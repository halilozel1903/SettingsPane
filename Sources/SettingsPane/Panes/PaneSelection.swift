/// Which pane a settings window shows. A plain value with no SwiftUI in it.
///
/// The first pane that exists among the preferred ones is selected (for example the pane the
/// user saw last, then the one the app asks for), otherwise the first pane.
public struct PaneSelection: Sendable, Equatable {
    /// The panes in their order, without duplicates.
    public private(set) var panes: [PaneID]
    /// The selected pane, or `nil` when there are no panes.
    public private(set) var selected: PaneID?

    /// - Parameters:
    ///   - panes: The panes in their order. Duplicates are dropped.
    ///   - preferred: Candidates in order of preference. `nil`s and unknown panes are skipped.
    public init(panes: [PaneID], preferred: [PaneID?] = []) {
        self.panes = Self.unique(panes)
        self.selected = Self.resolve(preferred: preferred, in: self.panes)
    }

    /// The first preferred pane that is in `panes`, otherwise the first pane.
    public static func resolve(preferred: [PaneID?], in panes: [PaneID]) -> PaneID? {
        for case let candidate? in preferred where panes.contains(candidate) {
            return candidate
        }
        return panes.first
    }

    /// The position of the selected pane.
    public var selectedIndex: Int? {
        selected.flatMap { panes.firstIndex(of: $0) }
    }

    /// Selects a pane. Returns `false` and keeps the selection when there is no such pane.
    @discardableResult
    public mutating func select(_ pane: PaneID) -> Bool {
        guard panes.contains(pane) else { return false }
        selected = pane
        return true
    }

    /// Selects the next pane, after the last one the first.
    public mutating func selectNext() {
        move(by: 1)
    }

    /// Selects the previous pane, before the first one the last.
    public mutating func selectPrevious() {
        move(by: -1)
    }

    /// Replaces the panes, keeping the selection when it still exists.
    public mutating func setPanes(_ newPanes: [PaneID]) {
        panes = Self.unique(newPanes)
        selected = Self.resolve(preferred: [selected], in: panes)
    }

    private mutating func move(by offset: Int) {
        guard !panes.isEmpty else { return }
        guard let index = selectedIndex else {
            selected = panes.first
            return
        }
        let count = panes.count
        selected = panes[((index + offset) % count + count) % count]
    }

    private static func unique(_ panes: [PaneID]) -> [PaneID] {
        var seen = Set<PaneID>()
        return panes.filter { seen.insert($0).inserted }
    }
}

/// Remembers the pane the user saw last, so the settings window opens on it next time.
public struct PanePersistence: Sendable, Hashable {
    /// The defaults key the pane identifier is stored under.
    public var key: String

    public init(key: String) {
        self.key = key
    }

    /// Stores the last pane under `"SettingsPane.selectedPane"`.
    public static let standard = PanePersistence(key: "SettingsPane.selectedPane")

    /// The stored pane, or `nil` when nothing is stored or the pane no longer exists.
    public func restore(from store: any SettingsStore, panes: [PaneID]) -> PaneID? {
        guard case .string(let rawValue)? = store.settingsValue(forKey: key) else { return nil }
        let pane = PaneID(rawValue: rawValue)
        return panes.contains(pane) ? pane : nil
    }

    public func save(_ pane: PaneID, to store: any SettingsStore) {
        store.setSettingsValue(.string(pane.rawValue), forKey: key)
    }

    public func clear(in store: any SettingsStore) {
        store.setSettingsValue(nil, forKey: key)
    }
}
