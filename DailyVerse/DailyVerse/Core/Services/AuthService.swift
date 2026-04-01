import Foundation
import FirebaseAuth
import AuthenticationServices
import CryptoKit

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
            controller.performRequests()
        }
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
