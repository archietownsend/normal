import Foundation

nonisolated protocol UsageLimitLedger: Sendable {
    func loadLastLoosened() -> Date?
    func saveLastLoosened(_ date: Date?)
}

struct KeychainUsageLimitLedger: UsageLimitLedger {
    private struct Record: Codable {
        let lastLoosened: Date
    }

    private let item: any KeychainStoring

    init(
        item: any KeychainStoring = KeychainItem(
            service: "com.normalengineering.normal.usageLimits",
            account: "lastLoosened"
        )
    ) {
        self.item = item
    }

    func loadLastLoosened() -> Date? {
        item.load(Record.self)?.lastLoosened
    }

    func saveLastLoosened(_ date: Date?) {
        guard let date else {
            item.delete()
            return
        }
        item.save(Record(lastLoosened: date))
    }
}

final class InMemoryUsageLimitLedger: UsageLimitLedger, @unchecked Sendable {
    private let lock = NSLock()
    private var date: Date?

    init(date: Date? = nil) {
        self.date = date
    }

    func loadLastLoosened() -> Date? {
        lock.withLock { date }
    }

    func saveLastLoosened(_ date: Date?) {
        lock.withLock { self.date = date }
    }
}
