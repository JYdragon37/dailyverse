import SwiftUI
import Combine
import FirebaseCore
import FirebaseAuth
import AuthenticationServices
import FirebaseAnalytics
import GoogleSignIn

@MainActor
class AuthManager: ObservableObject {
    @Published var user: FirebaseAuth.User?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var pendingSave: SavedVerse?
    @Published var authError: String?
    /// 계정 탈퇴 진행 중 플래그 — AppRootView에서 탈퇴/로그아웃 라우팅 구분용
    @Published var isDeletingAccount: Bool = false
    /// 탈퇴 완료 메시지 — AppRootView에서 alert 표시 (SettingsView는 이미 dismiss되므로)
    @Published var deletionCompleteMessage: String? = nil

    private let authService = AuthService()
    private let firestoreService = FirestoreService()
    private var authStateHandle: AuthStateDidChangeListenerHandle?

    init() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.user = user
                if user != nil, let pending = self?.pendingSave {
                    try? await self?.savePendingVerse(pending)
                }
            }
        }
    }

    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    var isLoggedIn: Bool { user != nil }
    var userId: String? { user?.uid }

    // MARK: - Email Auth

    /// 이메일/비밀번호 회원가입
    func signUpWithEmail(email: String, password: String) async {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            // Firestore 유저 문서 생성
            try? await FirestoreService().createUser(uid: result.user.uid, email: email, displayName: email.components(separatedBy: "@").first ?? "")
            await MainActor.run { authError = nil }
        } catch {
            await MainActor.run { authError = error.localizedDescription }
        }
    }

    /// 이메일/비밀번호 로그인
    func signInWithEmail(email: String, password: String) async {
        do {
            _ = try await Auth.auth().signIn(withEmail: email, password: password)
            await MainActor.run { authError = nil }
        } catch {
            await MainActor.run { authError = error.localizedDescription }
        }
    }

    /// Google Sign-In (GoogleSignIn-iOS SDK + Firebase Auth)
    func signInWithGoogle() async {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            authError = "Google 클라이언트 ID를 찾을 수 없어요."
            return
        }
        // Google Sign-In 설정
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        // 최상위 ViewController 가져오기
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            authError = "화면을 찾을 수 없어요."
            return
        }

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)
            guard let idToken = result.user.idToken?.tokenString else {
                authError = "Google 인증 토큰을 받지 못했어요."
                return
            }
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )
            let authResult = try await Auth.auth().signIn(with: credential)
            // 신규 유저면 Firestore 문서 생성
            if authResult.additionalUserInfo?.isNewUser == true {
                let displayName = result.user.profile?.name ?? "친구"
                let email = result.user.profile?.email ?? ""
                try? await FirestoreService().createUser(uid: authResult.user.uid, email: email, displayName: displayName)
            }
            authError = nil
        } catch {
            authError = error.localizedDescription
        }
    }

    // MARK: - Sign In

    func signIn() async {
        isLoading = true
        errorMessage = nil
        do {
            let firebaseUser = try await authService.signInWithApple()
            let currentNickname = NicknameManager.shared.nickname
            try await firestoreService.createUser(
                uid: firebaseUser.uid,
                email: firebaseUser.email ?? "",
                displayName: firebaseUser.displayName ?? "",
                nickname: currentNickname
            )
            // v5.1: 로그인 후 닉네임 Firestore 동기화
            await NicknameManager.shared.syncWithFirestore(userId: firebaseUser.uid)
            Analytics.logEvent("sign_in", parameters: ["method": "apple"])
        } catch let error as NSError {
            if error.code != ASAuthorizationError.canceled.rawValue {
                errorMessage = handleSignInError(error)
            }
        }
        isLoading = false
    }

    func signOut() {
        // 닉네임 초기화 (다음 로그인 계정 오염 방지)
        Task { @MainActor in
            NicknameManager.shared.reset()
        }
        do {
            try authService.signOut()
        } catch {
            errorMessage = "로그아웃 중 오류가 발생했습니다."
        }
    }

    // MARK: - Pending Save

    func setPendingSave(_ savedVerse: SavedVerse) {
        pendingSave = savedVerse
    }

    private func savePendingVerse(_ savedVerse: SavedVerse) async throws {
        guard let uid = user?.uid else { return }
        try await firestoreService.saveVerse(savedVerse, userId: uid)
        pendingSave = nil
    }

    // MARK: - Account Deletion

    /// 계정 탈퇴
    /// 순서: Auth 삭제 시도 → 17014 시 재인증 → 재시도 → Firestore 삭제 → UserDefaults 초기화
    ///
    /// Firestore 삭제를 Auth 삭제 성공 이후로 배치하는 이유:
    ///   재인증 취소(throw) 시 Auth 삭제가 실행되지 않아 Firestore 데이터가 보존됨
    func deleteAccount(subscriptionManager: SubscriptionManager) async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw NSError(domain: "AuthManager", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "로그인 상태가 아닙니다."])
        }
        let uid = currentUser.uid
        let provider = currentUser.providerData.first?.providerID ?? ""

        isDeletingAccount = true
        defer { isDeletingAccount = false }

        // Step 1: Auth 삭제 시도
        // 최근 로그인한 경우 → 바로 성공 (재인증 불필요)
        // 토큰 만료된 경우 → 17014 에러 → Step 2로
        do {
            try await currentUser.delete()
        } catch let error as NSError where error.code == 17014 {
            // Step 2: 재인증 (17014 발생 시에만)
            // 취소 시 throw → Firestore 삭제 실행 안 됨 → 데이터 보존
            if provider == "apple.com" {
                try await authService.reauthenticate()
            } else if provider == "google.com" {
                try await authService.reauthenticateWithGoogle()
            }
            // Step 3: 재인증 직후 재시도 (17014 없음)
            try await currentUser.delete()
        }

        // Step 4: Firestore 삭제 — Auth 삭제 성공 후에만 실행됨
        try? await firestoreService.deleteUserData(uid: uid)

        // Step 5: UserDefaults 전체 초기화
        subscriptionManager.logOut()
        if let bundleId = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleId)
        }

        Analytics.logEvent("account_deleted", parameters: nil)
        deletionCompleteMessage = "계정이 삭제되었습니다.\n그동안 함께해서 감사했어요 🙏"
    }

    // MARK: - Error Handling

    private func handleSignInError(_ error: NSError) -> String {
        switch error.code {
        case -1009, URLError.notConnectedToInternet.rawValue:
            return "인터넷 연결을 확인해주세요"
        case 17995:
            return "설정을 확인해주세요"
        default:
            return "다시 시도해주세요"
        }
    }
}
