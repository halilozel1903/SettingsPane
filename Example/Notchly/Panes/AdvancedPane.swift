import SettingsPane
import SwiftUI

struct AdvancedPane: View {
    @AppStorage(NotchlyKeys.settingsStyle) private var settingsStyle: SettingsPaneStyle
    @SettingsDefault(NotchlyKeys.hiddenApps, store: AppDefaults.store) private var hiddenApps: [String]
    @AppStorage(NotchlyKeys.verboseLogging) private var verboseLogging: Bool
    @AppStorage(NotchlyKeys.cacheLimit) private var cacheLimit: Int
    @State private var importSummary = ""
    @State private var showsImportSummary = false

    var body: some View {
        SettingsForm {
            SettingsRow("Settings window") {
                Picker("Settings window", selection: $settingsStyle) {
                    Text("Toolbar, like classic Mac apps").tag(SettingsPaneStyle.toolbar)
                    Text("Sidebar, like System Settings").tag(SettingsPaneStyle.sidebar)
                }
                .pickerStyle(.radioGroup)
                .labelsHidden()
            }
            SettingsRow("Hide in") {
                Text(hiddenApps.isEmpty ? "No apps" : hiddenApps.formatted(.list(type: .and)))
                    .foregroundStyle(.secondary)
                HStack {
                    Button("Add Preview") {
                        if !hiddenApps.contains("Preview") {
                            hiddenApps.append("Preview")
                        }
                    }
                    Button("Clear") {
                        hiddenApps = []
                    }
                    .disabled(hiddenApps.isEmpty)
                }
                .controlSize(.small)
            }
            SettingsRow("Logging") {
                Toggle("Write verbose logs", isOn: $verboseLogging)
            }
            SettingsRow("Cache") {
                Stepper("\(cacheLimit) MB", value: $cacheLimit, in: 64...2048, step: 64)
                    .fixedSize()
            }
            SettingsRow("Deep link") {
                Text(verbatim: "notchly://settings/accounts")
                    .font(.callout.monospaced())
                    .textSelection(.enabled)
            }

            SettingsSection("Backup") {
                SettingsRow {
                    HStack {
                        Button("Export Settings…") { exportSettings() }
                        Button("Import Settings…") { importSettings() }
                    }
                }
            } footer: {
                Text("A property list with every Notchly setting, to move them to another Mac.")
            }

            SettingsSection("Reset") {
                SettingsRow {
                    SettingsResetButton(keys: NotchlyKeys.all)
                }
            } footer: {
                Text("Every pane returns to its default settings.")
            }
        }
        .alert("Settings Imported", isPresented: $showsImportSummary) {
            Button("OK") {}
        } message: {
            Text(importSummary)
        }
    }

    private func exportSettings() {
        _ = try? SettingsArchivePanel.exportSettings(
            NotchlyKeys.all,
            from: AppDefaults.store,
            fileName: "Notchly Settings.plist"
        )
    }

    private func importSettings() {
        do {
            guard let result = try SettingsArchivePanel.importSettings(NotchlyKeys.all, into: AppDefaults.store) else { return }
            importSummary = "\(result.applied.count) settings imported, \(result.skipped.count) skipped, \(result.invalid.count) invalid."
        } catch {
            importSummary = "The file is not a Notchly settings file."
        }
        showsImportSummary = true
    }
}
