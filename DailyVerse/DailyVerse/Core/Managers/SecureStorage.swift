import Foundation

/// 민감한 데이터를 iCloud 백업에서 제외하여 저장하는 유틸리티
/// UserDefaults는 기본적으로 iCloud 백업에 포함되므로,
/// 기도·감사·묵상 임시 데이터는 별도 파일로 분리 저장
final class SecureStorage {

    static let shared = SecureStorage()

    /// 백업 제외 디렉토리 (Library/Application Support/SecureData/)
    private let secureDir: URL = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("SecureData", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            // iCloud 백업에서 완전 제외
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            var mutableDir = dir
            try? mutableDir.setResourceValues(values)
        }
        return dir
    }()

    private init() {}

    // MARK: - Public API

    func set(_ value: Data?, forKey key: String) {
        let fileURL = secureDir.appendingPathComponent("\(key).bin")
        if let value {
            try? value.write(to: fileURL, options: .atomic)
        } else {
            try? FileManager.default.removeItem(at: fileURL)
        }
    }

    func data(forKey key: String) -> Data? {
        let fileURL = secureDir.appendingPathComponent("\(key).bin")
        return try? Data(contentsOf: fileURL)
    }

    func set<T: Encodable>(_ value: T, forKey key: String) {
        let data = try? JSONEncoder().encode(value)
        set(data, forKey: key)
    }

    func get<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    func remove(forKey key: String) {
        set(nil as Data?, forKey: key)
    }

    func removeAll() {
        let files = (try? FileManager.default.contentsOfDirectory(at: secureDir, includingPropertiesForKeys: nil)) ?? []
        files.forEach { try? FileManager.default.removeItem(at: $0) }
    }
}
