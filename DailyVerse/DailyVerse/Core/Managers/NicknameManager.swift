import Foundation
import Combine

/// v5.1 — 닉네임 시스템
/// - UserDefaults: 즉시 반영 (오프라인 포함)
/// - Firestore users/{uid}.nickname: 로그인 유저 동기화
/// - 기본값: "친구"
@MainActor
final class NicknameManager: ObservableObject {
    static let shared = NicknameManager()

    @Published var nickname: String {
        didSet {
            UserDefaults.standard.set(nickname, forKey: Self.nicknameKey)
            UserDefaults.standard.set(true, forKey: Self.nicknameSetKey)
        }
    }

    private static let nicknameKey = "userNickname"
    private static let nicknameSetKey = "nicknameSet"
    private let firestoreService = FirestoreService()

    private init() {
        nickname = UserDefaults.standard.string(forKey: Self.nicknameKey) ?? "친구"
    }

    var isSet: Bool {
        UserDefaults.standard.bool(forKey: Self.nicknameSetKey)
    }

    // MARK: - 닉네임 설정

    /// 닉네임 설정 + Firestore 동기화 (로그인 시)
    func setNickname(_ name: String, userId: String? = nil) async {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        nickname = trimmed.isEmpty ? "친구" : String(trimmed.prefix(10))

        if let uid = userId {
            try? await firestoreService.updateNickname(nickname, userId: uid)
        }
    }

    /// 로그인 후 Firestore와 동기화 (서버 값 우선)
    func syncWithFirestore(userId: String) async {
        if let user = try? await firestoreService.fetchUser(uid: userId),
           !user.nickname.isEmpty, user.nickname != "친구" {
            nickname = user.nickname
            UserDefaults.standard.set(nickname, forKey: Self.nicknameKey)
        } else if !nickname.isEmpty {
            // 로컬 닉네임을 서버에 저장
            try? await firestoreService.updateNickname(nickname, userId: userId)
        }
    }
}
