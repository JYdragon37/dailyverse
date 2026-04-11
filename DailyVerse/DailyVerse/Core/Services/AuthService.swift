import Foundation
import FirebaseAuth
import FirebaseCore
import AuthenticationServices
import CryptoKit
import GoogleSignIn
import UIKit

class AuthService: NSObject {
    private var currentNonce: String?

    // signInWithApple()과 reauthenticate()가 같은 delegate를 공유하므로
    // 두 흐름을 구분하기 위해 별도 continuation을 사용
    private var signInContinuation: CheckedContinuation<FirebaseAuth.User, Error>?
    private var reauthContinuation: CheckedContinuation<Void, Error>?

    // MARK: - Sign In

    func signInWithApple() async throws -> FirebaseAuth.User {
        return try await withCheckedThrowingContinuation { continuation in
            self.signInContinuation = continuation
            let nonce = randomNonceString()
            currentNonce = nonce
            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = sha256(nonce)
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self  // 팝업 표시 창 연결
            controller.performRequests()
        }
    }

    // MARK: - Re-authenticate (계정 탈퇴 전 Apple 재인증)

    /// 계정 탈퇴 전 Apple 재인증: credential 획득 후 Firebase reauthenticate까지 수행
    func reauthenticate() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            self.reauthContinuation = continuation
            let nonce = randomNonceString()
            currentNonce = nonce
            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = []
            request.nonce = sha256(nonce)
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self  // 팝업 표시 창 연결
            controller.performRequests()
        }
    }

    // MARK: - Re-authenticate (Google)

    /// Google 계정 탈퇴 전 재인증
    func reauthenticateWithGoogle() async throws {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw NSError(domain: "AuthService", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Google 클라이언트 ID 없음"])
        }
        // @MainActor isolated 프로퍼티 접근 — Swift 6 준수
        let rootVC: UIViewController? = await MainActor.run {
            (UIApplication.shared.connectedScenes.first as? UIWindowScene)?
                .windows.first?.rootViewController
        }
        guard let rootVC else {
            throw NSError(domain: "AuthService", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "화면을 찾을 수 없어요"])
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)
        guard let idToken = result.user.idToken?.tokenString else {
            throw NSError(domain: "AuthService", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Google 토큰을 받지 못했어요"])
        }
        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: result.user.accessToken.tokenString
        )
        try await Auth.auth().currentUser?.reauthenticate(with: credential)
    }

    // MARK: - Sign Out

    func signOut() throws {
        try Auth.auth().signOut()
    }

    var currentUser: FirebaseAuth.User? { Auth.auth().currentUser }

    // MARK: - Helpers

    private func randomNonceString(length: Int = 32) -> String {
        var randomBytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AuthService: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Sign-In 및 재인증 팝업이 표시될 창 제공
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            return UIWindow()
        }
        return window
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AuthService: ASAuthorizationControllerDelegate {
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let nonce = currentNonce,
              let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            signInContinuation?.resume(throwing: AuthError.invalidCredential)
            reauthContinuation?.resume(throwing: AuthError.invalidCredential)
            signInContinuation = nil
            reauthContinuation = nil
            return
        }

        let credential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: appleIDCredential.fullName
        )

        if let continuation = signInContinuation {
            // 일반 로그인 흐름
            signInContinuation = nil
            Task {
                do {
                    let result = try await Auth.auth().signIn(with: credential)
                    continuation.resume(returning: result.user)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        } else if let continuation = reauthContinuation {
            // 재인증 흐름
            reauthContinuation = nil
            Task {
                do {
                    try await Auth.auth().currentUser?.reauthenticate(with: credential)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        signInContinuation?.resume(throwing: error)
        reauthContinuation?.resume(throwing: error)
        signInContinuation = nil
        reauthContinuation = nil
    }
}

// MARK: - AuthError

enum AuthError: Error, LocalizedError {
    case invalidCredential
    case cancelled

    var errorDescription: String? {
        switch self {
        case .invalidCredential: return "인증 정보가 올바르지 않습니다."
        case .cancelled: return "로그인이 취소되었습니다."
        }
    }
}
