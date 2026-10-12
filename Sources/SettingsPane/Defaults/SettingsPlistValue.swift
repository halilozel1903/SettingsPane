import Foundation

/// A property list value: what `UserDefaults` stores and a settings archive contains.
///
/// Sendable and comparable, unlike the `Any` that Foundation hands out, so the default registry
/// and its tests never deal with `NSNumber` directly.
public enum SettingsPlistValue: Sendable, Hashable {
    case bool(Bool)
    case int(Int)
    case double(Double)
    case string(String)
    case data(Data)
    case date(Date)
    case array([SettingsPlistValue])
    case dictionary([String: SettingsPlistValue])

    /// Converts a value read from `UserDefaults` or `PropertyListSerialization`. Returns `nil` for
    /// anything that is not a property list type.
    ///
    /// A `Bool` stored in a property list comes back as an `NSNumber`; this tells booleans,
    /// integers and floating-point numbers apart.
    public init?(propertyList value: Any) {
        switch value {
        case let string as String:
            self = .string(string)
        case let data as Data:
            self = .data(data)
        case let date as Date:
            self = .date(date)
        case let number as NSNumber:
            if CFGetTypeID(number as CFTypeRef) == CFBooleanGetTypeID() {
                self = .bool(number.boolValue)
            } else if CFNumberIsFloatType(number as CFNumber) {
                self = .double(number.doubleValue)
            } else {
                self = .int(number.intValue)
            }
        case let array as [Any]:
            var values: [SettingsPlistValue] = []
            values.reserveCapacity(array.count)
            for element in array {
                guard let converted = SettingsPlistValue(propertyList: element) else { return nil }
                values.append(converted)
            }
            self = .array(values)
        case let dictionary as [String: Any]:
            var values: [String: SettingsPlistValue] = [:]
            for (key, element) in dictionary {
                guard let converted = SettingsPlistValue(propertyList: element) else { return nil }
                values[key] = converted
            }
            self = .dictionary(values)
        default:
            return nil
        }
    }

    /// The value as Foundation property list object, for `UserDefaults` and
    /// `PropertyListSerialization`.
    public var propertyList: Any {
        switch self {
        case .bool(let value): return value
        case .int(let value): return value
        case .double(let value): return value
        case .string(let value): return value
        case .data(let value): return value
        case .date(let value): return value
        case .array(let values): return values.map(\.propertyList)
        case .dictionary(let values): return values.mapValues(\.propertyList)
        }
    }
}
