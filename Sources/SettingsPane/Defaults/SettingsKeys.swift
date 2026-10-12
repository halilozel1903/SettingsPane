import Foundation

/// The registry of an app's settings: registers their defaults, resets a pane or everything, and
/// exports and imports them as a property list.
///
/// ```swift
/// enum AppSettings {
///     static let launchAtLogin = SettingsKey("launchAtLogin", default: true, pane: "general")
///     static let theme = SettingsKey("theme", default: Theme.system, pane: "appearance")
///
///     static let registry = SettingsKeys(launchAtLogin, theme)
/// }
///
/// AppSettings.registry.register()                     // at launch
/// AppSettings.registry.reset(pane: "appearance")      // Restore Defaults in one pane
/// let plist = try AppSettings.registry.exportPropertyList()
/// ```
public struct SettingsKeys: Sendable {
    /// Every key, in the order given. A name listed twice is kept once.
    public let all: [AnySettingsKey]

    public init(_ keys: [any SettingsKeyConvertible]) {
        var seen = Set<String>()
        var unique: [AnySettingsKey] = []
        for key in keys.map({ $0.erased }) where seen.insert(key.name).inserted {
            unique.append(key)
        }
        self.all = unique
    }

    public init(_ keys: any SettingsKeyConvertible...) {
        self.init(keys)
    }

    /// The key with this defaults name.
    public subscript(name: String) -> AnySettingsKey? {
        all.first { $0.name == name }
    }

    /// The panes that own at least one key, in the order of their first key.
    public var panes: [PaneID] {
        var seen = Set<PaneID>()
        return all.compactMap(\.pane).filter { seen.insert($0).inserted }
    }

    /// The keys of one pane, or every key for `nil`.
    public func keys(in pane: PaneID?) -> [AnySettingsKey] {
        guard let pane else { return all }
        return all.filter { $0.pane == pane }
    }

    /// Every key's default value by name.
    public var defaultValues: [String: SettingsPlistValue] {
        Dictionary(all.map { ($0.name, $0.defaultValue) }, uniquingKeysWith: { first, _ in first })
    }

    /// Registers the defaults, so `UserDefaults` and `@AppStorage` return them while nothing is
    /// stored. Call it once at launch.
    public func register(in store: any SettingsStore = UserDefaults.standard) {
        store.registerSettingsDefaults(defaultValues)
    }

    /// Restores the defaults of one pane by removing its stored values.
    public func reset(pane: PaneID, in store: any SettingsStore = UserDefaults.standard) {
        for key in keys(in: pane) {
            store.setSettingsValue(nil, forKey: key.name)
        }
    }

    /// Restores every default.
    public func resetAll(in store: any SettingsStore = UserDefaults.standard) {
        for key in all {
            store.setSettingsValue(nil, forKey: key.name)
        }
    }

    /// Whether every setting of a pane (or of every pane, for `nil`) has its default value.
    public func isDefault(pane: PaneID? = nil, in store: any SettingsStore = UserDefaults.standard) -> Bool {
        keys(in: pane).allSatisfy { $0.value(in: store) == $0.defaultValue }
    }

    /// The current value of every setting of a pane (or of every pane, for `nil`), defaults
    /// included.
    public func values(pane: PaneID? = nil, in store: any SettingsStore = UserDefaults.standard) -> [String: SettingsPlistValue] {
        var values: [String: SettingsPlistValue] = [:]
        for key in keys(in: pane) {
            values[key.name] = key.value(in: store)
        }
        return values
    }
}

// MARK: - Export and import

/// Why a settings archive could not be imported.
public enum SettingsArchiveError: Error, Equatable, Sendable {
    /// The data is not a property list.
    case unreadable
    /// The property list is not a dictionary of settings.
    case notADictionary
}

/// What an import changed.
public struct SettingsImportResult: Sendable, Equatable {
    /// The settings that were imported, sorted by name.
    public var applied: [String]
    /// Names that are not in the registry, or belong to another pane than the one imported.
    public var skipped: [String]
    /// Registered settings whose value has the wrong type. They keep their current value.
    public var invalid: [String]

    public init(applied: [String] = [], skipped: [String] = [], invalid: [String] = []) {
        self.applied = applied
        self.skipped = skipped
        self.invalid = invalid
    }
}

extension SettingsKeys {
    /// The current values as an XML property list: a dictionary from defaults key to value.
    ///
    /// - Parameter pane: Exports only this pane's settings; `nil` exports every setting.
    public func exportPropertyList(pane: PaneID? = nil, from store: any SettingsStore = UserDefaults.standard) throws -> Data {
        let dictionary = values(pane: pane, in: store).mapValues(\.propertyList)
        return try PropertyListSerialization.data(fromPropertyList: dictionary, format: .xml, options: 0)
    }

    /// Imports a property list written by ``exportPropertyList(pane:from:)``.
    ///
    /// Only registered keys are imported, each converted to its key's type. A value equal to the
    /// default is removed rather than stored, so later changes to the default still apply.
    ///
    /// - Parameter pane: Imports only this pane's settings; `nil` imports every registered setting.
    @discardableResult
    public func importPropertyList(
        _ data: Data,
        pane: PaneID? = nil,
        into store: any SettingsStore = UserDefaults.standard
    ) throws -> SettingsImportResult {
        let object: Any
        do {
            object = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
        } catch {
            throw SettingsArchiveError.unreadable
        }
        guard let dictionary = object as? [String: Any] else {
            throw SettingsArchiveError.notADictionary
        }

        var result = SettingsImportResult()
        for name in dictionary.keys.sorted() {
            guard let key = self[name], pane == nil || key.pane == pane else {
                result.skipped.append(name)
                continue
            }
            guard let raw = dictionary[name],
                  let plistValue = SettingsPlistValue(propertyList: raw),
                  let value = key.normalized(plistValue)
            else {
                result.invalid.append(name)
                continue
            }
            store.setSettingsValue(value == key.defaultValue ? nil : value, forKey: name)
            result.applied.append(name)
        }
        return result
    }
}
