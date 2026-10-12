import Foundation

/// Identifies a settings pane, for selection, persistence of the last pane and deep links.
///
/// A ``Pane`` gets its identifier from its title (`"Advanced Options"` becomes
/// `"advanced-options"`) unless you pass one. Declare the ones you link to as constants:
///
/// ```swift
/// extension PaneID {
///     static let accounts: PaneID = "accounts"
/// }
/// ```
public struct PaneID: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral, CustomStringConvertible {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.rawValue = value
    }

    /// An identifier made from a pane title: lowercased, with every run of characters that are not
    /// letters or digits replaced by a single `-`. `"Shortcuts & Keys"` becomes `"shortcuts-keys"`.
    public init(title: String) {
        var slug = ""
        var needsDash = false
        for scalar in title.lowercased().unicodeScalars {
            if CharacterSet.alphanumerics.contains(scalar) {
                if needsDash && !slug.isEmpty {
                    slug.append("-")
                }
                slug.unicodeScalars.append(scalar)
                needsDash = false
            } else {
                needsDash = true
            }
        }
        self.rawValue = slug
    }

    public var description: String {
        rawValue
    }
}
