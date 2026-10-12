import SwiftUI
import Testing
@testable import SettingsPane

@MainActor
@Suite("Pane builder")
struct PaneBuilderTests {
    private func build(@SettingsPaneBuilder _ content: () -> [Pane]) -> [Pane] {
        content()
    }

    @Test func buildsPanesInOrder() {
        let panes = build {
            Pane("General", systemImage: "gearshape") { Text("General") }
            Pane("Appearance", systemImage: "paintpalette", tint: .blue) { Text("Appearance") }
        }
        let expected: [PaneID] = [.general, .appearance]
        #expect(panes.map(\.id) == expected)
        #expect(panes.map(\.systemImage) == ["gearshape", "paintpalette"])
    }

    @Test func supportsConditionsAndLoops() {
        let showsAdvanced = false
        let extra = ["Sync", "Labs"]
        let panes = build {
            Pane("General", systemImage: "gearshape") { Text("General") }
            if showsAdvanced {
                Pane("Advanced", systemImage: "gearshape.2") { Text("Advanced") }
            } else {
                Pane("Basics", systemImage: "star") { Text("Basics") }
            }
            for title in extra {
                Pane(title, systemImage: "circle") { Text(title) }
            }
        }
        #expect(panes.map(\.id.rawValue) == ["general", "basics", "sync", "labs"])
    }

    @Test func explicitIdentifier() {
        let panes = build {
            Pane("Accounts", systemImage: "person", id: "people") { Text("Accounts") }
        }
        #expect(panes.first?.id.rawValue == "people")
        #expect(panes.first?.title == "Accounts")
    }

    @Test func classicAndPlainLabels() {
        #expect(SettingsLabel.classic("Theme") == "Theme:")
        #expect(SettingsLabel.classic("Theme:") == "Theme:")
        #expect(SettingsLabel.plain("Theme:") == "Theme")
        #expect(SettingsLabel.plain("Theme") == "Theme")
    }
}

@MainActor
@Suite("Settings router")
struct SettingsRouterTests {
    @Test func requestsAreTakenOnce() {
        let router = SettingsRouter()
        router.show(.accounts)
        #expect(router.pendingRequest?.pane == .accounts)

        let request = router.takeRequest()
        #expect(request?.pane == .accounts)
        #expect(router.pendingRequest == nil)
        let again = router.takeRequest()
        #expect(again == nil)
    }

    @Test func askingTwiceForTheSamePaneIsAChange() {
        let router = SettingsRouter()
        router.show(.advanced)
        let first = router.pendingRequest
        router.show(.advanced)
        let second = router.pendingRequest
        #expect(first != second)
        #expect(second?.pane == .advanced)
    }
}
