//
//  DailyVerseTests.swift
//  DailyVerseTests
//
//  Created by JeongYong Huh on 4/1/26.
//

import Foundation
import Testing
@testable import DailyVerse

struct DailyVerseTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }

    @Test func migratesLegacyGreetingLanguageKey() async throws {
        let defaults = UserDefaults(suiteName: "test.migratesLegacyGreetingLanguageKey")!
        defaults.removePersistentDomain(forName: "test.migratesLegacyGreetingLanguageKey")
        defaults.set("en", forKey: "greetingLanguage")

        migrateAppLanguageKeyIfNeeded(defaults: defaults)

        #expect(defaults.string(forKey: "appLanguage") == "en")
        #expect(defaults.object(forKey: "greetingLanguage") == nil)
    }

    @Test func doesNotOverwriteExistingAppLanguageKey() async throws {
        let defaults = UserDefaults(suiteName: "test.doesNotOverwriteExistingAppLanguageKey")!
        defaults.removePersistentDomain(forName: "test.doesNotOverwriteExistingAppLanguageKey")
        defaults.set("ko", forKey: "appLanguage")
        defaults.set("en", forKey: "greetingLanguage")

        migrateAppLanguageKeyIfNeeded(defaults: defaults)

        #expect(defaults.string(forKey: "appLanguage") == "ko")
    }

    @Test func defaultsToDeviceLanguageWhenNoKeyExists() async throws {
        let defaults = UserDefaults(suiteName: "test.defaultsToDeviceLanguageWhenNoKeyExists")!
        defaults.removePersistentDomain(forName: "test.defaultsToDeviceLanguageWhenNoKeyExists")

        migrateAppLanguageKeyIfNeeded(defaults: defaults, deviceLanguageCode: "en")

        #expect(defaults.string(forKey: "appLanguage") == "en")
    }

    @Test func defaultsToKoreanWhenDeviceLanguageIsNotEnglish() async throws {
        let defaults = UserDefaults(suiteName: "test.defaultsToKoreanWhenDeviceLanguageIsNotEnglish")!
        defaults.removePersistentDomain(forName: "test.defaultsToKoreanWhenDeviceLanguageIsNotEnglish")

        migrateAppLanguageKeyIfNeeded(defaults: defaults, deviceLanguageCode: "ja")

        #expect(defaults.string(forKey: "appLanguage") == "ko")
    }

    @Test func normalizesInvalidLegacyGreetingLanguageValue() async throws {
        let defaults = UserDefaults(suiteName: "test.normalizesInvalidLegacyGreetingLanguageValue")!
        defaults.removePersistentDomain(forName: "test.normalizesInvalidLegacyGreetingLanguageValue")
        defaults.set("random", forKey: "greetingLanguage")

        migrateAppLanguageKeyIfNeeded(defaults: defaults)

        #expect(defaults.string(forKey: "appLanguage") == "ko")
        #expect(defaults.object(forKey: "greetingLanguage") == nil)
    }

    @Test func allStringCatalogKeysResolveToLocalizedValues() async throws {
        // Locate Localizable.xcstrings relative to this test file:
        // .../DailyVerse/DailyVerseTests/DailyVerseTests.swift
        //   -> .../DailyVerse/DailyVerse/Localizable.xcstrings
        let testFileURL = URL(fileURLWithPath: #filePath)
        let catalogURL = testFileURL
            .deletingLastPathComponent() // DailyVerseTests/
            .deletingLastPathComponent() // DailyVerse/ (project root)
            .appendingPathComponent("DailyVerse")
            .appendingPathComponent("Localizable.xcstrings")

        let data = try Data(contentsOf: catalogURL)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let strings = json?["strings"] as? [String: Any]
        #expect(strings != nil)
        let keys = strings?.keys ?? [:].keys
        #expect(keys.isEmpty == false)

        let previousValue = UserDefaults.standard.object(forKey: "appLanguage")
        UserDefaults.standard.set("en", forKey: "appLanguage")
        defer {
            if let previousValue {
                UserDefaults.standard.set(previousValue, forKey: "appLanguage")
            } else {
                UserDefaults.standard.removeObject(forKey: "appLanguage")
            }
        }

        for key in keys {
            let resolved = appLanguageString(key)
            #expect(resolved != key, "Key '\(key)' did not resolve to a localized value")
        }
    }

}
