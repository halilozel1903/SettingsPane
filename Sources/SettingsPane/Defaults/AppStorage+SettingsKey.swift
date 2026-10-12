import SwiftUI

// `@AppStorage` from a ``SettingsKey``: the key's name and default value, in one place.
//
//     @AppStorage(AppSettings.launchAtLogin) private var launchAtLogin: Bool
//     @AppStorage(AppSettings.theme) private var theme: Theme

extension AppStorage where Value == Bool {
    @MainActor
    public init(_ key: SettingsKey<Bool>, store: UserDefaults? = nil) {
        self.init(wrappedValue: key.defaultValue, key.name, store: store)
    }
}

extension AppStorage where Value == Int {
    @MainActor
    public init(_ key: SettingsKey<Int>, store: UserDefaults? = nil) {
        self.init(wrappedValue: key.defaultValue, key.name, store: store)
    }
}

extension AppStorage where Value == Double {
    @MainActor
    public init(_ key: SettingsKey<Double>, store: UserDefaults? = nil) {
        self.init(wrappedValue: key.defaultValue, key.name, store: store)
    }
}

extension AppStorage where Value == String {
    @MainActor
    public init(_ key: SettingsKey<String>, store: UserDefaults? = nil) {
        self.init(wrappedValue: key.defaultValue, key.name, store: store)
    }
}

extension AppStorage where Value == Data {
    @MainActor
    public init(_ key: SettingsKey<Data>, store: UserDefaults? = nil) {
        self.init(wrappedValue: key.defaultValue, key.name, store: store)
    }
}

extension AppStorage where Value: RawRepresentable & SettingsValue, Value.RawValue == String {
    @MainActor
    public init(_ key: SettingsKey<Value>, store: UserDefaults? = nil) {
        self.init(wrappedValue: key.defaultValue, key.name, store: store)
    }
}

extension AppStorage where Value: RawRepresentable & SettingsValue, Value.RawValue == Int {
    @MainActor
    public init(_ key: SettingsKey<Value>, store: UserDefaults? = nil) {
        self.init(wrappedValue: key.defaultValue, key.name, store: store)
    }
}
