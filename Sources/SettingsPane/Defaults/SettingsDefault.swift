import Combine
import SwiftUI

/// Reads and writes a ``SettingsKey`` in a view, and updates the view when the value changes,
/// in this view or anywhere else (another window, a reset, an import, `defaults write`).
///
/// Works with every ``SettingsValue`` type, including arrays and dictionaries that `@AppStorage`
/// cannot store.
///
/// ```swift
/// struct BlocklistSettings: View {
///     @SettingsDefault(AppSettings.hiddenApps) private var hiddenApps
///
///     var body: some View {
///         List(hiddenApps, id: \.self) { Text($0) }
///     }
/// }
/// ```
@MainActor
@propertyWrapper
public struct SettingsDefault<Value: SettingsValue>: DynamicProperty {
    @StateObject private var box: SettingsDefaultBox<Value>

    /// - Parameters:
    ///   - key: The setting.
    ///   - store: The defaults it is stored in.
    public init(_ key: SettingsKey<Value>, store: UserDefaults = .standard) {
        _box = StateObject(wrappedValue: SettingsDefaultBox(key: key, defaults: store))
    }

    public var wrappedValue: Value {
        get { box.value }
        nonmutating set { box.value = newValue }
    }

    /// A binding to the value, for controls.
    public var projectedValue: Binding<Value> {
        $box.value
    }
}

/// Observes `UserDefaults` for ``SettingsDefault`` and reads and writes its key.
@MainActor
final class SettingsDefaultBox<Value: SettingsValue>: ObservableObject {
    let key: SettingsKey<Value>
    let defaults: UserDefaults
    nonisolated(unsafe) private var observation: (any NSObjectProtocol)?

    init(key: SettingsKey<Value>, defaults: UserDefaults) {
        self.key = key
        self.defaults = defaults
        observation = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: defaults,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.objectWillChange.send()
            }
        }
    }

    deinit {
        if let observation {
            NotificationCenter.default.removeObserver(observation)
        }
    }

    var value: Value {
        get { key.value(in: defaults) }
        set {
            objectWillChange.send()
            key.set(newValue, in: defaults)
        }
    }
}
