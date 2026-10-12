import Foundation

/// A typed setting: its defaults key, its default value and the pane it belongs to.
///
/// ```swift
/// extension SettingsKeys {
///     static let launchAtLogin = SettingsKey("launchAtLogin", default: true, pane: "general")
///     static let theme = SettingsKey("theme", default: Theme.system, pane: "appearance")
/// }
/// ```
///
/// Read it in a view with ``SettingsDefault`` or `@AppStorage(key)`, and collect the keys in a
/// ``SettingsKeys`` registry for defaults registration, reset and export.
public struct SettingsKey<Value: SettingsValue>: Sendable {
    /// The `UserDefaults` key.
    public let name: String
    /// The value while nothing is stored, and after a reset.
    public let defaultValue: Value
    /// The pane whose Restore Defaults resets this setting.
    public let pane: PaneID?

    public init(_ name: String, default defaultValue: Value, pane: PaneID? = nil) {
        self.name = name
        self.defaultValue = defaultValue
        self.pane = pane
    }

    /// The stored value, or the default when nothing is stored or the stored value has another type.
    public func value(in store: any SettingsStore = UserDefaults.standard) -> Value {
        guard let stored = store.settingsValue(forKey: name), let value = Value(plistValue: stored) else {
            return defaultValue
        }
        return value
    }

    public func set(_ value: Value, in store: any SettingsStore = UserDefaults.standard) {
        store.setSettingsValue(value.plistValue, forKey: name)
    }

    /// Removes the stored value, so the default applies again.
    public func reset(in store: any SettingsStore = UserDefaults.standard) {
        store.setSettingsValue(nil, forKey: name)
    }

    /// Whether the current value equals the default.
    public func isDefault(in store: any SettingsStore = UserDefaults.standard) -> Bool {
        value(in: store).plistValue == defaultValue.plistValue
    }
}

/// Anything that can be listed in a ``SettingsKeys`` registry.
public protocol SettingsKeyConvertible: Sendable {
    var erased: AnySettingsKey { get }
}

extension SettingsKey: SettingsKeyConvertible {
    public var erased: AnySettingsKey {
        AnySettingsKey(self)
    }
}

/// A ``SettingsKey`` without its value type, so keys of different types fit in one registry.
public struct AnySettingsKey: Sendable, Hashable, Identifiable, SettingsKeyConvertible {
    public let name: String
    public let pane: PaneID?
    public let defaultValue: SettingsPlistValue
    private let normalizer: @Sendable (SettingsPlistValue) -> SettingsPlistValue?

    public init<Value: SettingsValue>(_ key: SettingsKey<Value>) {
        self.name = key.name
        self.pane = key.pane
        self.defaultValue = key.defaultValue.plistValue
        self.normalizer = { Value(plistValue: $0)?.plistValue }
    }

    public var id: String {
        name
    }

    public var erased: AnySettingsKey {
        self
    }

    /// The value converted to the key's type (an integer `3` for a `Double` key becomes `3.0`), or
    /// `nil` when it does not fit the type.
    public func normalized(_ value: SettingsPlistValue) -> SettingsPlistValue? {
        normalizer(value)
    }

    /// The stored value in the key's type, or the default.
    public func value(in store: any SettingsStore) -> SettingsPlistValue {
        store.settingsValue(forKey: name).flatMap { normalized($0) } ?? defaultValue
    }

    public static func == (lhs: AnySettingsKey, rhs: AnySettingsKey) -> Bool {
        lhs.name == rhs.name && lhs.pane == rhs.pane && lhs.defaultValue == rhs.defaultValue
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(pane)
        hasher.combine(defaultValue)
    }
}
