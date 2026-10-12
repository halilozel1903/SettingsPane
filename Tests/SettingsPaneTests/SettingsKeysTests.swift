import Foundation
import Testing
@testable import SettingsPane

enum TestTheme: String, CaseIterable, SettingsValue {
    case system, light, dark
}

enum TestSettings {
    static let launchAtLogin = SettingsKey("launchAtLogin", default: true, pane: .general)
    static let hoverDelay = SettingsKey("hoverDelay", default: 0.3, pane: .general)
    static let theme = SettingsKey("theme", default: TestTheme.system, pane: .appearance)
    static let notchWidth = SettingsKey("notchWidth", default: 220, pane: .appearance)
    static let hiddenApps = SettingsKey("hiddenApps", default: ["Keynote"], pane: .advanced)
    static let launchCount = SettingsKey("launchCount", default: 0)

    static let registry = SettingsKeys(launchAtLogin, hoverDelay, theme, notchWidth, hiddenApps, launchCount)
}

@Suite("Settings keys")
struct SettingsKeyTests {
    @Test func defaultWhileNothingIsStored() {
        let store = InMemorySettingsStore()
        #expect(TestSettings.launchAtLogin.value(in: store))
        #expect(TestSettings.theme.value(in: store) == .system)
        let keynote: [String] = ["Keynote"]
        #expect(TestSettings.hiddenApps.value(in: store) == keynote)
    }

    @Test func setAndReset() {
        let store = InMemorySettingsStore()
        TestSettings.theme.set(.dark, in: store)
        #expect(TestSettings.theme.value(in: store) == .dark)
        #expect(store.values["theme"] == .string("dark"))
        #expect(!TestSettings.theme.isDefault(in: store))

        TestSettings.theme.reset(in: store)
        #expect(TestSettings.theme.value(in: store) == .system)
        #expect(TestSettings.theme.isDefault(in: store))
    }

    @Test func aValueOfAnotherTypeReadsAsTheDefault() {
        let store = InMemorySettingsStore(values: ["theme": .string("sepia"), "notchWidth": .string("wide")])
        #expect(TestSettings.theme.value(in: store) == .system)
        #expect(TestSettings.notchWidth.value(in: store) == 220)
    }

    @Test func numbersConvertWhenExact() {
        let store = InMemorySettingsStore(values: ["notchWidth": .double(240), "hoverDelay": .int(1)])
        #expect(TestSettings.notchWidth.value(in: store) == 240)
        #expect(TestSettings.hoverDelay.value(in: store) == 1.0)

        let fractional = InMemorySettingsStore(values: ["notchWidth": .double(240.5)])
        #expect(TestSettings.notchWidth.value(in: fractional) == 220)
    }

    @Test func booleansAcceptZeroAndOne() {
        let store = InMemorySettingsStore(values: ["launchAtLogin": .int(0)])
        #expect(!TestSettings.launchAtLogin.value(in: store))
        #expect(Bool(plistValue: .int(2)) == nil)
    }

    @Test func erasedKeysCompareByNamePaneAndDefault() {
        #expect(TestSettings.theme.erased == AnySettingsKey(TestSettings.theme))
        #expect(TestSettings.theme.erased != TestSettings.notchWidth.erased)
        #expect(TestSettings.theme.erased.defaultValue == .string("system"))
    }
}

@Suite("Settings registry")
struct SettingsRegistryTests {
    let registry = TestSettings.registry

    @Test func listsKeysByPane() {
        #expect(registry.all.count == 6)
        #expect(registry.keys(in: .general).map(\.name) == ["launchAtLogin", "hoverDelay"])
        #expect(registry.keys(in: .appearance).map(\.name) == ["theme", "notchWidth"])
        #expect(registry.keys(in: nil).count == 6)
        let panes: [PaneID] = [.general, .appearance, .advanced]
        #expect(registry.panes == panes)
        #expect(registry["theme"]?.pane == .appearance)
        #expect(registry["missing"] == nil)
    }

    @Test func dropsADuplicateName() {
        let duplicate = SettingsKey("theme", default: "other")
        let keys = SettingsKeys(TestSettings.theme, duplicate)
        #expect(keys.all.count == 1)
        #expect(keys["theme"]?.defaultValue == .string("system"))
    }

    @Test func registersDefaults() {
        let store = InMemorySettingsStore()
        registry.register(in: store)
        #expect(store.registeredDefaults["launchAtLogin"] == .bool(true))
        let hiddenApps: SettingsPlistValue = .array([.string("Keynote")])
        #expect(store.registeredDefaults["hiddenApps"] == hiddenApps)
        #expect(store.settingsValue(forKey: "notchWidth") == .int(220))
        #expect(store.values.isEmpty)
    }

    @Test func resetsOnePane() {
        let store = InMemorySettingsStore()
        TestSettings.launchAtLogin.set(false, in: store)
        TestSettings.theme.set(.dark, in: store)
        TestSettings.notchWidth.set(300, in: store)

        registry.reset(pane: .appearance, in: store)
        #expect(TestSettings.theme.value(in: store) == .system)
        #expect(TestSettings.notchWidth.value(in: store) == 220)
        #expect(!TestSettings.launchAtLogin.value(in: store))
        #expect(registry.isDefault(pane: .appearance, in: store))
        #expect(!registry.isDefault(pane: .general, in: store))
        #expect(!registry.isDefault(in: store))
    }

    @Test func resetsEverything() {
        let store = InMemorySettingsStore()
        TestSettings.launchAtLogin.set(false, in: store)
        TestSettings.hiddenApps.set(["Xcode", "Safari"], in: store)
        TestSettings.launchCount.set(4, in: store)
        store.setSettingsValue(.string("kept"), forKey: "notASetting")

        registry.resetAll(in: store)
        #expect(registry.isDefault(in: store))
        let remaining: [String: SettingsPlistValue] = ["notASetting": .string("kept")]
        #expect(store.values == remaining)
    }

    @Test func currentValuesIncludeDefaults() {
        let store = InMemorySettingsStore()
        TestSettings.notchWidth.set(260, in: store)
        let values = registry.values(pane: .appearance, in: store)
        let expected: [String: SettingsPlistValue] = ["theme": .string("system"), "notchWidth": .int(260)]
        #expect(values == expected)
    }
}

@Suite("Export and import")
struct SettingsArchiveTests {
    let registry = TestSettings.registry

    @Test func roundTrip() throws {
        let source = InMemorySettingsStore()
        TestSettings.theme.set(.light, in: source)
        TestSettings.hoverDelay.set(0.8, in: source)
        TestSettings.hiddenApps.set(["Xcode"], in: source)
        let data = try registry.exportPropertyList(from: source)

        let destination = InMemorySettingsStore()
        let result = try registry.importPropertyList(data, into: destination)
        #expect(result.applied == ["hiddenApps", "hoverDelay", "launchAtLogin", "launchCount", "notchWidth", "theme"])
        #expect(result.skipped.isEmpty)
        #expect(result.invalid.isEmpty)
        #expect(TestSettings.theme.value(in: destination) == .light)
        #expect(TestSettings.hoverDelay.value(in: destination) == 0.8)
        #expect(TestSettings.hiddenApps.value(in: destination) == ["Xcode"])
        // Values equal to their default are not stored, so the default keeps applying.
        #expect(destination.values["launchAtLogin"] == nil)
        #expect(destination.values["notchWidth"] == nil)
    }

    @Test func exportIsAnXMLPropertyList() throws {
        let store = InMemorySettingsStore()
        let data = try registry.exportPropertyList(pane: .appearance, from: store)
        let text = try #require(String(data: data, encoding: .utf8))
        #expect(text.contains("<plist"))
        #expect(text.contains("<key>theme</key>"))
        #expect(!text.contains("launchAtLogin"))
    }

    @Test func skipsUnknownAndReportsInvalidValues() throws {
        let plist: [String: Any] = [
            "theme": "dark",
            "notchWidth": "very wide",
            "launchAtLogin": false,
            "somethingElse": 42,
        ]
        let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        let store = InMemorySettingsStore()
        TestSettings.notchWidth.set(280, in: store)

        let result = try registry.importPropertyList(data, into: store)
        #expect(result == SettingsImportResult(applied: ["launchAtLogin", "theme"], skipped: ["somethingElse"], invalid: ["notchWidth"]))
        #expect(TestSettings.theme.value(in: store) == .dark)
        #expect(!TestSettings.launchAtLogin.value(in: store))
        #expect(TestSettings.notchWidth.value(in: store) == 280)
    }

    @Test func importsOnePane() throws {
        let plist: [String: Any] = ["theme": "light", "launchAtLogin": false]
        let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .binary, options: 0)
        let store = InMemorySettingsStore()

        let result = try registry.importPropertyList(data, pane: .appearance, into: store)
        #expect(result.applied == ["theme"])
        #expect(result.skipped == ["launchAtLogin"])
        #expect(TestSettings.launchAtLogin.value(in: store))
    }

    @Test func importNormalizesNumbers() throws {
        let plist: [String: Any] = ["hoverDelay": 1, "notchWidth": 250.0]
        let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        let store = InMemorySettingsStore()
        try registry.importPropertyList(data, into: store)
        #expect(store.values["hoverDelay"] == .double(1))
        #expect(store.values["notchWidth"] == .int(250))
    }

    @Test func rejectsData() throws {
        #expect(throws: SettingsArchiveError.unreadable) {
            try registry.importPropertyList(Data(#"<?xml version="1.0"?><plist><dict><key>theme"#.utf8), into: InMemorySettingsStore())
        }
        let array = try PropertyListSerialization.data(fromPropertyList: ["theme"], format: .xml, options: 0)
        #expect(throws: SettingsArchiveError.notADictionary) {
            try registry.importPropertyList(array, into: InMemorySettingsStore())
        }
    }
}

@Suite("Property list values")
struct SettingsPlistValueTests {
    @Test func tellsBooleansIntegersAndDoublesApart() {
        #expect(SettingsPlistValue(propertyList: NSNumber(value: true)) == .bool(true))
        #expect(SettingsPlistValue(propertyList: NSNumber(value: 1)) == .int(1))
        #expect(SettingsPlistValue(propertyList: NSNumber(value: 1.5)) == .double(1.5))
        #expect(SettingsPlistValue(propertyList: false) == .bool(false))
    }

    @Test func convertsCollections() {
        let value = SettingsPlistValue(propertyList: ["a": [1, 2], "b": "text"] as [String: Any])
        let expected: SettingsPlistValue = .dictionary(["a": .array([.int(1), .int(2)]), "b": .string("text")])
        #expect(value == expected)
    }

    @Test func rejectsNonPropertyListValues() {
        #expect(SettingsPlistValue(propertyList: URL(fileURLWithPath: "/tmp")) == nil)
        #expect(SettingsPlistValue(propertyList: ["ok", URL(fileURLWithPath: "/tmp")] as [Any]) == nil)
    }

    @Test func userDefaultsRoundTrip() throws {
        let suite = "SettingsPaneTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        TestSettings.registry.register(in: defaults)
        #expect(TestSettings.launchAtLogin.value(in: defaults))
        #expect(TestSettings.theme.value(in: defaults) == .system)

        TestSettings.launchAtLogin.set(false, in: defaults)
        TestSettings.notchWidth.set(240, in: defaults)
        TestSettings.hiddenApps.set(["Xcode", "Mail"], in: defaults)
        let stored = defaults.object(forKey: "launchAtLogin") as? Bool
        #expect(stored == false)
        #expect(defaults.settingsValue(forKey: "launchAtLogin") == .bool(false))
        #expect(defaults.settingsValue(forKey: "notchWidth") == .int(240))
        #expect(TestSettings.hiddenApps.value(in: defaults) == ["Xcode", "Mail"])

        TestSettings.registry.resetAll(in: defaults)
        #expect(TestSettings.launchAtLogin.value(in: defaults))
        #expect(TestSettings.notchWidth.value(in: defaults) == 220)
    }
}
