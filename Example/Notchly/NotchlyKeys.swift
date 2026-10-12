import SettingsPane
import SwiftUI

extension PaneID {
    static let general: PaneID = "general"
    static let appearance: PaneID = "appearance"
    static let shortcuts: PaneID = "shortcuts"
    static let accounts: PaneID = "accounts"
    static let advanced: PaneID = "advanced"
}

/// Every Notchly setting, with its default and its pane.
enum NotchlyKeys {
    // General
    static let launchAtLogin = SettingsKey("launchAtLogin", default: true, pane: .general)
    static let showsMenuBarIcon = SettingsKey("showsMenuBarIcon", default: true, pane: .general)
    static let notchStyle = SettingsKey("notchStyle", default: NotchStyle.island, pane: .general)
    static let hidesInFullScreen = SettingsKey("hidesInFullScreen", default: true, pane: .general)
    static let hoverDelay = SettingsKey("hoverDelay", default: 0.3, pane: .general)
    static let checksForUpdates = SettingsKey("checksForUpdates", default: true, pane: .general)
    static let updateChannel = SettingsKey("updateChannel", default: UpdateChannel.stable, pane: .general)

    // Appearance
    static let theme = SettingsKey("theme", default: NotchTheme.system, pane: .appearance)
    static let accent = SettingsKey("accent", default: NotchAccent.purple, pane: .appearance)
    static let notchWidth = SettingsKey("notchWidth", default: 240.0, pane: .appearance)
    static let showsAlbumArt = SettingsKey("showsAlbumArt", default: true, pane: .appearance)
    static let showsBattery = SettingsKey("showsBattery", default: true, pane: .appearance)
    static let reducesMotion = SettingsKey("reducesMotion", default: false, pane: .appearance)

    // Shortcuts
    static let shortcutsEnabled = SettingsKey("shortcutsEnabled", default: true, pane: .shortcuts)

    // Accounts
    static let syncInterval = SettingsKey("syncInterval", default: SyncInterval.fifteenMinutes, pane: .accounts)
    static let showsBadges = SettingsKey("showsBadges", default: true, pane: .accounts)
    static let syncsOnBattery = SettingsKey("syncsOnBattery", default: false, pane: .accounts)

    // Advanced
    static let settingsStyle = SettingsKey("settingsStyle", default: SettingsPaneStyle.toolbar, pane: .advanced)
    static let hiddenApps = SettingsKey("hiddenApps", default: ["Keynote", "QuickTime Player"], pane: .advanced)
    static let verboseLogging = SettingsKey("verboseLogging", default: false, pane: .advanced)
    static let cacheLimit = SettingsKey("cacheLimit", default: 256, pane: .advanced)

    /// The registry: defaults registration, Restore Defaults, Reset All, export and import.
    static let all = SettingsKeys(
        launchAtLogin, showsMenuBarIcon, notchStyle, hidesInFullScreen, hoverDelay, checksForUpdates, updateChannel,
        theme, accent, notchWidth, showsAlbumArt, showsBattery, reducesMotion,
        shortcutsEnabled,
        syncInterval, showsBadges, syncsOnBattery,
        settingsStyle, hiddenApps, verboseLogging, cacheLimit
    )
}

/// Deep links such as notchly://settings/accounts.
enum NotchlyLinks {
    static let scheme = SettingsURLScheme(scheme: "notchly")
}

/// Where the settings are stored: the standard defaults, or a scratch suite for screenshots so a
/// capture never shows values left over from an earlier run.
enum AppDefaults {
    @MainActor static let store: UserDefaults = {
        guard ScreenshotScene.current != nil else { return .standard }
        let suite = "io.github.halilozel1903.SettingsPaneDemo.screenshots"
        guard let defaults = UserDefaults(suiteName: suite) else { return .standard }
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }()
}

enum NotchStyle: String, CaseIterable, Identifiable, SettingsValue {
    case island, pill, minimal

    var id: Self { self }

    var title: String {
        switch self {
        case .island: "Island, grows with its content"
        case .pill: "Pill, always the same size"
        case .minimal: "Minimal, a thin line until hovered"
        }
    }
}

enum NotchTheme: String, CaseIterable, Identifiable, SettingsValue {
    case system, light, dark

    var id: Self { self }

    var title: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }
}

enum NotchAccent: String, CaseIterable, Identifiable, SettingsValue {
    case blue, purple, pink, orange, green, graphite

    var id: Self { self }

    var title: String {
        rawValue.capitalized
    }

    var color: Color {
        switch self {
        case .blue: .blue
        case .purple: .purple
        case .pink: .pink
        case .orange: .orange
        case .green: .green
        case .graphite: .gray
        }
    }
}

enum UpdateChannel: String, CaseIterable, Identifiable, SettingsValue {
    case stable, beta

    var id: Self { self }

    var title: String {
        switch self {
        case .stable: "Stable releases"
        case .beta: "Beta releases"
        }
    }
}

enum SyncInterval: String, CaseIterable, Identifiable, SettingsValue {
    case realtime, fifteenMinutes, hourly, manual

    var id: Self { self }

    var title: String {
        switch self {
        case .realtime: "As changes happen"
        case .fifteenMinutes: "Every 15 minutes"
        case .hourly: "Every hour"
        case .manual: "Manually"
        }
    }
}
