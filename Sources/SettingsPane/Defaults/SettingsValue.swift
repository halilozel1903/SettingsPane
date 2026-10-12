import Foundation

/// A type that can be stored in a setting: `Bool`, `Int`, `Double`, `String`, `Data`, `Date`,
/// arrays and string-keyed dictionaries of those, and enums backed by a `String` or `Int`.
///
/// For an enum, adding the conformance is enough:
///
/// ```swift
/// enum Theme: String, CaseIterable, SettingsValue {
///     case system, light, dark
/// }
/// ```
public protocol SettingsValue: Sendable {
    /// The value as a property list value.
    var plistValue: SettingsPlistValue { get }
    /// Reads the value back, or returns `nil` when the stored value has another type.
    init?(plistValue: SettingsPlistValue)
}

extension SettingsValue where Self: RawRepresentable, RawValue: SettingsValue {
    public var plistValue: SettingsPlistValue {
        rawValue.plistValue
    }

    public init?(plistValue: SettingsPlistValue) {
        guard let rawValue = RawValue(plistValue: plistValue) else { return nil }
        self.init(rawValue: rawValue)
    }
}

extension Bool: SettingsValue {
    public var plistValue: SettingsPlistValue {
        .bool(self)
    }

    /// Accepts a boolean, or the integers 0 and 1 (what `defaults write` produces with `-int`).
    public init?(plistValue: SettingsPlistValue) {
        switch plistValue {
        case .bool(let value):
            self = value
        case .int(let value) where value == 0 || value == 1:
            self = value == 1
        default:
            return nil
        }
    }
}

extension Int: SettingsValue {
    public var plistValue: SettingsPlistValue {
        .int(self)
    }

    /// Accepts an integer, or a floating-point number without a fractional part.
    public init?(plistValue: SettingsPlistValue) {
        switch plistValue {
        case .int(let value):
            self = value
        case .double(let value):
            guard let exact = Int(exactly: value) else { return nil }
            self = exact
        default:
            return nil
        }
    }
}

extension Double: SettingsValue {
    public var plistValue: SettingsPlistValue {
        .double(self)
    }

    /// Accepts a floating-point number or an integer.
    public init?(plistValue: SettingsPlistValue) {
        switch plistValue {
        case .double(let value):
            self = value
        case .int(let value):
            self = Double(value)
        default:
            return nil
        }
    }
}

extension String: SettingsValue {
    public var plistValue: SettingsPlistValue {
        .string(self)
    }

    public init?(plistValue: SettingsPlistValue) {
        guard case .string(let value) = plistValue else { return nil }
        self = value
    }
}

extension Data: SettingsValue {
    public var plistValue: SettingsPlistValue {
        .data(self)
    }

    public init?(plistValue: SettingsPlistValue) {
        guard case .data(let value) = plistValue else { return nil }
        self = value
    }
}

extension Date: SettingsValue {
    public var plistValue: SettingsPlistValue {
        .date(self)
    }

    public init?(plistValue: SettingsPlistValue) {
        guard case .date(let value) = plistValue else { return nil }
        self = value
    }
}

extension Array: SettingsValue where Element: SettingsValue {
    public var plistValue: SettingsPlistValue {
        .array(map(\.plistValue))
    }

    public init?(plistValue: SettingsPlistValue) {
        guard case .array(let values) = plistValue else { return nil }
        var elements: [Element] = []
        elements.reserveCapacity(values.count)
        for value in values {
            guard let element = Element(plistValue: value) else { return nil }
            elements.append(element)
        }
        self = elements
    }
}

extension Dictionary: SettingsValue where Key == String, Value: SettingsValue {
    public var plistValue: SettingsPlistValue {
        .dictionary(mapValues(\.plistValue))
    }

    public init?(plistValue: SettingsPlistValue) {
        guard case .dictionary(let values) = plistValue else { return nil }
        var result: [String: Value] = [:]
        for (key, value) in values {
            guard let element = Value(plistValue: value) else { return nil }
            result[key] = element
        }
        self = result
    }
}
