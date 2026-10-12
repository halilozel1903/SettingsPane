import SwiftUI

/// Restores the defaults of a pane, or of every pane, after asking.
///
/// ```swift
/// SettingsResetButton(pane: "appearance", keys: AppSettings.registry)   // "Restore Defaults"
/// SettingsResetButton(keys: AppSettings.registry)                       // "Reset All Settings…"
/// ```
///
/// It resets the defaults in ``SwiftUI/EnvironmentValues/settingsDefaults``. Every
/// `@AppStorage` and ``SettingsDefault`` showing those settings updates at once.
public struct SettingsResetButton: View {
    private let title: String
    private let pane: PaneID?
    private let keys: SettingsKeys
    private let confirms: Bool
    @Environment(\.settingsDefaults) private var defaults
    @State private var isConfirming = false

    /// - Parameters:
    ///   - title: The button title. "Restore Defaults" for a pane, "Reset All Settings…" for all.
    ///   - pane: The pane to reset, or `nil` for every setting in `keys`.
    ///   - keys: The registry.
    ///   - confirms: Whether to ask first.
    public init(_ title: String? = nil, pane: PaneID? = nil, keys: SettingsKeys, confirms: Bool = true) {
        self.title = title ?? (pane == nil ? "Reset All Settings…" : "Restore Defaults")
        self.pane = pane
        self.keys = keys
        self.confirms = confirms
    }

    public var body: some View {
        Button(title) {
            if confirms {
                isConfirming = true
            } else {
                reset()
            }
        }
        .confirmationDialog(confirmationTitle, isPresented: $isConfirming) {
            Button(pane == nil ? "Reset All" : "Restore Defaults", role: .destructive) {
                reset()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(confirmationMessage)
        }
    }

    private var confirmationTitle: String {
        pane == nil ? "Reset all settings?" : "Restore the default settings of this pane?"
    }

    private var confirmationMessage: String {
        pane == nil
            ? "Every setting returns to its default value. This cannot be undone."
            : "The settings in this pane return to their default values."
    }

    private func reset() {
        if let pane {
            keys.reset(pane: pane, in: defaults)
        } else {
            keys.resetAll(in: defaults)
        }
    }
}
