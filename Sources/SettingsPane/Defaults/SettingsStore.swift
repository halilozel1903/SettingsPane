import Foundation

/// Where settings live. `UserDefaults` is one; ``InMemorySettingsStore`` is another, for tests and
/// previews.
public protocol SettingsStore: AnyObject {
    /// The stored value, or the registered default when nothing is stored.
    func settingsValue(forKey key: String) -> SettingsPlistValue?
    /// Stores a value. `nil` removes it, so the registered default applies again.
    func setSettingsValue(_ value: SettingsPlistValue?, forKey key: String)
    /// Registers values to use while nothing is stored (`UserDefaults.register(defaults:)`).
    func registerSettingsDefaults(_ defaults: [String: SettingsPlistValue])
}

extension UserDefaults: SettingsStore {
    public func settingsValue(forKey key: String) -> SettingsPlistValue? {
        object(forKey: key).flatMap { SettingsPlistValue(propertyList: $0) }
    }

    public func setSettingsValue(_ value: SettingsPlistValue?, forKey key: String) {
        if let value {
            set(value.propertyList, forKey: key)
        } else {
            removeObject(forKey: key)
        }
    }

    public func registerSettingsDefaults(_ defaults: [String: SettingsPlistValue]) {
        register(defaults: defaults.mapValues(\.propertyList))
    }
}

/// A settings store in memory, with the same semantics as `UserDefaults`: a removed value falls
/// back to the registered default.
public final class InMemorySettingsStore: SettingsStore {
    /// The values set explicitly.
    public private(set) var values: [String: SettingsPlistValue]
    /// The registered defaults.
    public private(set) var registeredDefaults: [String: SettingsPlistValue] = [:]

    public init(values: [String: SettingsPlistValue] = [:]) {
        self.values = values
    }

    public func settingsValue(forKey key: String) -> SettingsPlistValue? {
        values[key] ?? registeredDefaults[key]
    }

    public func setSettingsValue(_ value: SettingsPlistValue?, forKey key: String) {
        values[key] = value
    }

    public func registerSettingsDefaults(_ defaults: [String: SettingsPlistValue]) {
        registeredDefaults.merge(defaults) { _, new in new }
    }
}
