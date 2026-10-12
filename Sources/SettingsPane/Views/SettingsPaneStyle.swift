import SwiftUI

/// How a settings window presents its panes.
public enum SettingsPaneStyle: String, Sendable, CaseIterable, Identifiable, SettingsValue {
    /// Classic Mac settings: a toolbar of panes, the window resizing to each pane's height, and
    /// forms with right-aligned labels.
    case toolbar
    /// System Settings since macOS 13: a sidebar of panes with colored icons, a fixed-size window
    /// and grouped forms.
    case sidebar

    public var id: String {
        rawValue
    }
}

/// Sizes of a ``SettingsPaneView``.
public struct SettingsPaneLayout: Sendable, Hashable {
    /// The width of every pane in the toolbar style. The height follows each pane's content.
    public var toolbarWidth: CGFloat
    /// The window size in the sidebar style.
    public var sidebarWindowSize: CGSize
    /// The width of the sidebar in the sidebar style.
    public var sidebarWidth: CGFloat

    public init(
        toolbarWidth: CGFloat = 520,
        sidebarWindowSize: CGSize = CGSize(width: 720, height: 500),
        sidebarWidth: CGFloat = 200
    ) {
        self.toolbarWidth = toolbarWidth
        self.sidebarWindowSize = sidebarWindowSize
        self.sidebarWidth = sidebarWidth
    }
}

private struct SettingsPaneStyleKey: EnvironmentKey {
    static let defaultValue: SettingsPaneStyle = .toolbar
}

private struct SettingsDefaultsKey: EnvironmentKey {
    static var defaultValue: UserDefaults {
        .standard
    }
}

extension EnvironmentValues {
    /// The style the current pane is shown in. ``SettingsForm``, ``SettingsRow`` and
    /// ``SettingsSection`` read it to lay themselves out.
    public var settingsPaneStyle: SettingsPaneStyle {
        get { self[SettingsPaneStyleKey.self] }
        set { self[SettingsPaneStyleKey.self] = newValue }
    }

    /// The defaults that ``SettingsPaneView`` remembers the last pane in and
    /// ``SettingsResetButton`` resets. `UserDefaults.standard` unless set with
    /// `settingsDefaults(_:)`.
    public var settingsDefaults: UserDefaults {
        get { self[SettingsDefaultsKey.self] }
        set { self[SettingsDefaultsKey.self] = newValue }
    }
}

extension View {
    /// Lays out ``SettingsForm``, ``SettingsRow`` and ``SettingsSection`` in this style. The
    /// settings view sets it for each pane; use it for previews or a form outside the window.
    public func settingsPaneStyle(_ style: SettingsPaneStyle) -> some View {
        environment(\.settingsPaneStyle, style)
    }

    /// Uses these defaults for the settings: for the last pane, for resets, and for every
    /// `@AppStorage` without an explicit store.
    public func settingsDefaults(_ defaults: UserDefaults) -> some View {
        environment(\.settingsDefaults, defaults)
            .defaultAppStorage(defaults)
    }
}
