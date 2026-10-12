import Foundation
import SwiftUI

/// Builds and reads deep links to a settings pane, such as `notchly://settings/accounts`.
///
/// ```swift
/// let links = SettingsURLScheme(scheme: "notchly")
/// links.url(for: "accounts")                                  // notchly://settings/accounts
/// links.pane(from: URL(string: "notchly://settings?pane=advanced")!)   // "advanced"
/// ```
///
/// Register the scheme under `CFBundleURLTypes` in the Info.plist, then let a view open the
/// links with `opensSettings(for:)`.
public struct SettingsURLScheme: Sendable, Hashable {
    /// The URL scheme, without `://`.
    public let scheme: String
    /// The host that marks a settings link. `settings` by default.
    public let host: String

    public init(scheme: String, host: String = "settings") {
        self.scheme = scheme
        self.host = host
    }

    /// `scheme://host/pane`.
    public func url(for pane: PaneID) -> URL? {
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.path = "/" + pane.rawValue
        return components.url
    }

    /// `scheme://host`, which opens the settings on the last pane.
    public var settingsURL: URL? {
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        return components.url
    }

    /// Whether the URL is a settings link of this scheme. Scheme and host are compared ignoring case.
    public func matches(_ url: URL) -> Bool {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return false }
        return components.scheme?.lowercased() == scheme.lowercased()
            && components.host?.lowercased() == host.lowercased()
    }

    /// The pane a settings link points to: the first path component, or the `pane` query item.
    /// `nil` when the URL is not a settings link or names no pane.
    public func pane(from url: URL) -> PaneID? {
        guard matches(url),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        else { return nil }
        if let first = components.path.split(separator: "/").first, !first.isEmpty {
            return PaneID(rawValue: String(first))
        }
        if let item = components.queryItems?.first(where: { $0.name == "pane" }),
           let value = item.value, !value.isEmpty {
            return PaneID(rawValue: value)
        }
        return nil
    }
}

extension View {
    /// Opens the Settings window when the app receives a settings link of this scheme: on the
    /// linked pane, or on the last pane for a link without one.
    public func opensSettings(for scheme: SettingsURLScheme) -> some View {
        modifier(SettingsURLHandler(scheme: scheme))
    }
}

private struct SettingsURLHandler: ViewModifier {
    let scheme: SettingsURLScheme
    @Environment(\.openSettings) private var openSettings

    func body(content: Content) -> some View {
        content.onOpenURL { url in
            guard scheme.matches(url) else { return }
            if let pane = scheme.pane(from: url) {
                openSettings(pane: pane)
            } else {
                openSettings()
            }
        }
    }
}
