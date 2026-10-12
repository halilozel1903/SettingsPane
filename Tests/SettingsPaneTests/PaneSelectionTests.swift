import Testing
@testable import SettingsPane

@Suite("Pane selection")
struct PaneSelectionTests {
    let panes: [PaneID] = [.general, .appearance, .shortcuts, .accounts, .advanced]

    @Test func startsOnTheFirstPane() {
        let selection = PaneSelection(panes: panes)
        #expect(selection.selected == .general)
        #expect(selection.selectedIndex == 0)
    }

    @Test func prefersTheFirstKnownCandidate() {
        let selection = PaneSelection(panes: panes, preferred: [nil, .billing, .accounts, .advanced])
        #expect(selection.selected == .accounts)
    }

    @Test func emptyPanesSelectNothing() {
        let selection = PaneSelection(panes: [], preferred: [.general])
        #expect(selection.selected == nil)
        #expect(selection.selectedIndex == nil)
    }

    @Test func dropsDuplicatePanes() {
        let selection = PaneSelection(panes: [.general, .general, .advanced])
        let expected: [PaneID] = [.general, .advanced]
        #expect(selection.panes == expected)
    }

    @Test func selectsAKnownPane() {
        var selection = PaneSelection(panes: panes)
        let selected = selection.select(.shortcuts)
        #expect(selected)
        #expect(selection.selected == .shortcuts)
    }

    @Test func ignoresAnUnknownPane() {
        var selection = PaneSelection(panes: panes, preferred: [.appearance])
        let selected = selection.select(.billing)
        #expect(!selected)
        #expect(selection.selected == .appearance)
    }

    @Test func nextAndPreviousWrapAround() {
        var selection = PaneSelection(panes: panes, preferred: [.advanced])
        selection.selectNext()
        #expect(selection.selected == .general)
        selection.selectPrevious()
        #expect(selection.selected == .advanced)
        selection.selectPrevious()
        #expect(selection.selected == .accounts)
    }

    @Test func settingPanesKeepsTheSelectionWhenItStillExists() {
        var selection = PaneSelection(panes: panes, preferred: [.accounts])
        selection.setPanes([.accounts, .general])
        #expect(selection.selected == .accounts)
        selection.setPanes([.general, .advanced])
        #expect(selection.selected == .general)
    }

    @Test func resolveWithoutPreferences() {
        #expect(PaneSelection.resolve(preferred: [], in: panes) == .general)
        #expect(PaneSelection.resolve(preferred: [.advanced], in: []) == nil)
    }
}

@Suite("Last pane persistence")
struct PanePersistenceTests {
    let panes: [PaneID] = [.general, .advanced]

    @Test func savesAndRestoresTheLastPane() {
        let store = InMemorySettingsStore()
        let persistence = PanePersistence.standard
        #expect(persistence.restore(from: store, panes: panes) == nil)

        persistence.save(.advanced, to: store)
        #expect(store.values["SettingsPane.selectedPane"] == .string("advanced"))
        #expect(persistence.restore(from: store, panes: panes) == .advanced)
    }

    @Test func ignoresAPaneThatNoLongerExists() {
        let store = InMemorySettingsStore(values: ["last": .string("billing")])
        let persistence = PanePersistence(key: "last")
        #expect(persistence.restore(from: store, panes: panes) == nil)
    }

    @Test func ignoresAValueOfAnotherType() {
        let store = InMemorySettingsStore(values: ["last": .int(2)])
        #expect(PanePersistence(key: "last").restore(from: store, panes: panes) == nil)
    }

    @Test func clearRemovesTheValue() {
        let store = InMemorySettingsStore()
        let persistence = PanePersistence(key: "last")
        persistence.save(.general, to: store)
        persistence.clear(in: store)
        #expect(store.values["last"] == nil)
    }

    @Test func restoredPaneWinsOverTheDefaultPane() {
        let store = InMemorySettingsStore()
        let persistence = PanePersistence.standard
        persistence.save(.advanced, to: store)
        let restored = persistence.restore(from: store, panes: panes)
        let selection = PaneSelection(panes: panes, preferred: [nil, restored, .general])
        #expect(selection.selected == .advanced)
    }
}

@Suite("Pane identifiers")
struct PaneIDTests {
    @Test func slugFromTitle() {
        #expect(PaneID(title: "General").rawValue == "general")
        #expect(PaneID(title: "Shortcuts & Keys").rawValue == "shortcuts-keys")
        #expect(PaneID(title: "  Wi-Fi  ").rawValue == "wi-fi")
        #expect(PaneID(title: "Advanced Options…").rawValue == "advanced-options")
    }

    @Test func literalAndRawValue() {
        let id: PaneID = "accounts"
        #expect(id.rawValue == "accounts")
        #expect(id == .accounts)
        #expect(id.description == "accounts")
    }
}
