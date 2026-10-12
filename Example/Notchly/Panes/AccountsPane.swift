import SettingsPane
import SwiftUI

struct AccountsPane: View {
    @AppStorage(NotchlyKeys.syncInterval) private var syncInterval: SyncInterval
    @AppStorage(NotchlyKeys.showsBadges) private var showsBadges: Bool
    @AppStorage(NotchlyKeys.syncsOnBattery) private var syncsOnBattery: Bool

    var body: some View {
        SettingsForm {
            SettingsSection("Accounts", showsSeparator: false) {
                ForEach(Account.samples) { account in
                    SettingsRow {
                        AccountRow(account: account)
                    }
                }
                SettingsRow {
                    HStack {
                        Button("Add Account…") {}
                        Button("Remove") {}
                            .disabled(true)
                    }
                }
            }

            SettingsSection("Sync") {
                SettingsRow("Sync") {
                    Picker("Sync", selection: $syncInterval) {
                        ForEach(SyncInterval.allCases) { interval in
                            Text(interval.title).tag(interval)
                        }
                    }
                    .labelsHidden()
                    .fixedSize()
                }
                SettingsRow {
                    Toggle("Show unread counts in the notch", isOn: $showsBadges)
                }
                SettingsRow {
                    Toggle("Sync while on battery power", isOn: $syncsOnBattery)
                }
            } footer: {
                Text("Calendars and reminders sync in the background. Mail is checked whenever the notch opens.")
            }

            SettingsSection {
                SettingsRow {
                    SettingsResetButton(pane: .accounts, keys: NotchlyKeys.all)
                }
            }
        }
    }
}

struct Account: Identifiable {
    enum Status {
        case connected, needsSignIn
    }

    let name: String
    let detail: String
    let initials: String
    let color: Color
    let status: Status

    var id: String { detail }

    static let samples = [
        Account(name: "Personal", detail: "mira.lindqvist@example.com", initials: "ML", color: .orange, status: .connected),
        Account(name: "Work", detail: "mira@northwind.example", initials: "NW", color: .blue, status: .connected),
        Account(name: "Family Calendar", detail: "Shared by Jonas", initials: "FC", color: .green, status: .needsSignIn),
    ]
}

struct AccountRow: View {
    let account: Account

    var body: some View {
        HStack(spacing: 10) {
            Text(verbatim: account.initials)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(account.color.gradient, in: Circle())
            VStack(alignment: .leading, spacing: 1) {
                Text(verbatim: account.name)
                    .fontWeight(.medium)
                Text(verbatim: account.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 12)
            switch account.status {
            case .connected:
                Label("Connected", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
            case .needsSignIn:
                Button("Sign In…") {}
                    .controlSize(.small)
            }
        }
        .frame(minWidth: 340, maxWidth: .infinity)
    }
}
