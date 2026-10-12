import AppKit
import UniformTypeIdentifiers

/// Save and open panels for exporting and importing settings as a property list.
///
/// ```swift
/// Button("Export Settings…") {
///     try? SettingsArchivePanel.exportSettings(AppSettings.registry, fileName: "Notchly Settings.plist")
/// }
/// ```
@MainActor
public enum SettingsArchivePanel {
    /// Asks where to save, then writes the settings there. Returns the file, or `nil` when the user
    /// cancelled.
    @discardableResult
    public static func exportSettings(
        _ keys: SettingsKeys,
        pane: PaneID? = nil,
        from defaults: UserDefaults = .standard,
        fileName: String = "Settings.plist"
    ) throws -> URL? {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.propertyList]
        panel.nameFieldStringValue = fileName
        panel.canCreateDirectories = true
        guard panel.runModal() == .OK, let url = panel.url else { return nil }
        let data = try keys.exportPropertyList(pane: pane, from: defaults)
        try data.write(to: url, options: .atomic)
        return url
    }

    /// Asks for a property list, then imports it. Returns what changed, or `nil` when the user
    /// cancelled.
    @discardableResult
    public static func importSettings(
        _ keys: SettingsKeys,
        pane: PaneID? = nil,
        into defaults: UserDefaults = .standard
    ) throws -> SettingsImportResult? {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.propertyList]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        guard panel.runModal() == .OK, let url = panel.url else { return nil }
        let data = try Data(contentsOf: url)
        return try keys.importPropertyList(data, pane: pane, into: defaults)
    }
}
