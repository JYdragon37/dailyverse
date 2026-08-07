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

}
