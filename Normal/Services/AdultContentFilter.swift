import ManagedSettings

extension ManagedSettingsStore.Name {
    static let adultContent = Self("normal.adultContent")
}

protocol AdultContentFiltering: AnyObject {
    var isEnabled: Bool { get }
    func setEnabled(_ enabled: Bool)
}

final class ManagedSettingsAdultContentFilter: AdultContentFiltering {
    private let store = ManagedSettingsStore(named: .adultContent)

    var isEnabled: Bool {
        if case .auto? = store.webContent.blockedByFilter { return true }
        return false
    }

    func setEnabled(_ enabled: Bool) {
        guard enabled != isEnabled else { return }
        store.webContent.blockedByFilter = enabled ? .auto() : nil
    }
}

final class InMemoryAdultContentFilter: AdultContentFiltering {
    private(set) var isEnabled = false

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
    }
}
