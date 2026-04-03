import SwiftUI
import Combine
import FirebaseAuth
import AuthenticationServices
import FirebaseAnalytics

@MainActor
class AuthManager: ObservableObject {
    @Published var user: FirebaseAuth.User?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var pendingSave: SavedVerse?

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

    // MARK: - Sign In

    func signIn() async {
        isLoading = true
        errorMessage = nil
        do {
            let firebaseUser = try await authService.signInWithApple()
            try await firestoreService.createUser(
                uid: firebaseUser.uid,
                email: firebaseUser.email ?? "",
                displayName: firebaseUser.displayName ?? ""
            )
            Analytics.logEvent("sign_in", parameters: ["method": "apple"])
        } catch let error as NSError {
            if error.code != ASAuthorizationError.canceled.rawValue {
                errorMessage = handleSignInError(error)
            }
        }
        isLoading = false
    }

    func signOut() {
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

    /// 계정 탈퇴 4단계:
    /// 1. Apple 재인증
    /// 2. Firestore 데이터 삭제 (users/{uid} + saved_verses/{uid}/verses)
    /// 3. Firebase Auth 계정 삭제
    /// 4. RevenueCat 로그아웃 신호 + UserDefaults 초기화
    func deleteAccount(subscriptionManager: SubscriptionManager) async throws {
        guard let uid = user?.uid else { return }

        // Step 1: Apple 재인증
        try await authService.reauthenticate()

        // Step 2: Firestore 데이터 삭제
        try await firestoreService.deleteUserData(uid: uid)

        // Step 3: Firebase Auth 계정 삭제
        try await user?.delete()

        // Step 4: RevenueCat 로그아웃 + UserDefaults 초기화
        subscriptionManager.logOut()
        if let bundleId = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleId)
        }

        Analytics.logEvent("account_deleted", parameters: nil)
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
