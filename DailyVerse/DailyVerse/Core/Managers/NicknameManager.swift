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
        // _nickname으로 Published 내부 저장소에 직접 접근 → didSet 미호출
        // (nickname = ... 방식은 didSet을 트리거해서 nicknameSet = true가 잘못 저장됨)
        _nickname = Published(initialValue: UserDefaults.standard.string(forKey: Self.nicknameKey) ?? "친구")
    }

    /// 유저가 명시적으로 닉네임을 설정했는지 여부
    /// - nicknameSet 플래그가 true이고 닉네임이 기본값("친구")이 아닌 경우만 true
    var isSet: Bool {
        UserDefaults.standard.bool(forKey: Self.nicknameSetKey) && nickname != "친구"
    }

    // MARK: - 닉네임 설정

    /// 닉네임 설정 + Firestore 동기화 (로그인 시)
    /// 한글 포함 여부 기준으로 최대 길이 결정 (한글 5자 / 영어·숫자 8자)
    static func maxLength(for text: String) -> Int {
        let hasKorean = text.unicodeScalars.contains { $0.value >= 0xAC00 && $0.value <= 0xD7A3 }
        return hasKorean ? 5 : 8
    }

    func setNickname(_ name: String, userId: String? = nil) async {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let limit = Self.maxLength(for: trimmed)
        nickname = trimmed.isEmpty ? "친구" : String(trimmed.prefix(limit))

        if let uid = userId {
            try? await firestoreService.updateNickname(nickname, userId: uid)
        }
    }

    /// 로그아웃/탈퇴 시 닉네임 초기화 (다음 로그인 계정 오염 방지)
    func reset() {
        _nickname = Published(initialValue: "친구")
        UserDefaults.standard.removeObject(forKey: Self.nicknameKey)
        UserDefaults.standard.set(false, forKey: Self.nicknameSetKey)
    }

    /// 로그인 후 Firestore와 동기화 (서버 값 우선)
    func syncWithFirestore(userId: String) async {
        if let user = try? await firestoreService.fetchUser(uid: userId),
           !user.nickname.isEmpty, user.nickname != "친구" {
            // Firestore 값이 있으면 → 로컬 업데이트
            nickname = user.nickname
            UserDefaults.standard.set(nickname, forKey: Self.nicknameKey)
        }
        // else: 신규 유저면 로컬 "친구"(reset 후 상태) 유지, Firestore 저장 안 함
        // (온보딩에서 직접 닉네임 입력 후 저장)
    }
}
