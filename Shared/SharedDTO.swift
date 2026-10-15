import FamilyControls
import Foundation

nonisolated struct TimedUnblockDTO: Codable, Sendable, Identifiable {
    let id: String
    let selectionData: Data
    let endDate: Date
    let activityName: String
    let isGroupUnblock: Bool
    let blockAllPreventsAppDelete: Bool?

    private let encodedCustomDomains: [String]?
    var customDomains: [String] {
        encodedCustomDomains ?? []
    }

    let startDate: Date?

    init(
        id: String,
        selectionData: Data,
        endDate: Date,
        activityName: String,
        isGroupUnblock: Bool,
        blockAllPreventsAppDelete: Bool? = nil,
        customDomains: [String]? = nil,
        startDate: Date? = nil
    ) {
        self.id = id
        self.selectionData = selectionData
        self.endDate = endDate
        self.activityName = activityName
        self.isGroupUnblock = isGroupUnblock
        self.blockAllPreventsAppDelete = blockAllPreventsAppDelete
        encodedCustomDomains = customDomains
        self.startDate = startDate
    }
}

nonisolated struct ScheduleDTO: Codable, Sendable, Identifiable {
    let id: UUID
    let name: String
    let selectionData: Data
    let startHour: Int
    let startMinute: Int
    let durationMinutes: Int
    let weekdays: Set<Int>
    let shouldBlock: Bool
    let isTimed: Bool

    private let encodedCustomDomains: [String]?
    var customDomains: [String] {
        encodedCustomDomains ?? []
    }

    init(
        id: UUID,
        name: String,
        selectionData: Data,
        startHour: Int,
        startMinute: Int,
        durationMinutes: Int,
        weekdays: Set<Int>,
        shouldBlock: Bool,
        isTimed: Bool,
        customDomains: [String]? = nil
    ) {
        self.id = id
        self.name = name
        self.selectionData = selectionData
        self.startHour = startHour
        self.startMinute = startMinute
        self.durationMinutes = durationMinutes
        self.weekdays = weekdays
        self.shouldBlock = shouldBlock
        self.isTimed = isTimed
        encodedCustomDomains = customDomains
    }
}

nonisolated extension ScheduleDTO {
    var wrapsPastMidnight: Bool {
        startHour * 60 + startMinute + durationMinutes >= 24 * 60
    }

    func isActive(at date: Date, calendar: Calendar = .current) -> Bool {
        activeWindowStart(at: date, calendar: calendar) != nil
    }

    func activeWindowStart(at date: Date, calendar: Calendar = .current) -> Date? {
        ScheduleWindow.start(
            containing: date,
            startHour: startHour,
            startMinute: startMinute,
            durationMinutes: durationMinutes,
            weekdays: weekdays,
            calendar: calendar
        )
    }

    func endApplies(on date: Date, calendar: Calendar = .current) -> Bool {
        let today = calendar.component(.weekday, from: date)
        let startWeekday = wrapsPastMidnight ? (today == 1 ? 7 : today - 1) : today
        return weekdays.contains(startWeekday)
    }
}

nonisolated extension FamilyActivitySelection {
    func toData() throws -> Data {
        try PropertyListEncoder().encode(self)
    }

    static func fromData(_ data: Data) throws -> FamilyActivitySelection {
        try PropertyListDecoder().decode(FamilyActivitySelection.self, from: data)
    }

    func union(_ other: FamilyActivitySelection) -> FamilyActivitySelection {
        var merged = self
        merged.applicationTokens.formUnion(other.applicationTokens)
        merged.webDomainTokens.formUnion(other.webDomainTokens)
        merged.categoryTokens.formUnion(other.categoryTokens)
        return merged
    }

    func subtracting(_ other: FamilyActivitySelection) -> FamilyActivitySelection {
        var result = self
        result.applicationTokens.subtract(other.applicationTokens)
        result.webDomainTokens.subtract(other.webDomainTokens)
        result.categoryTokens.subtract(other.categoryTokens)
        return result
    }
}

nonisolated enum ScheduleWindow {
    static func start(
        containing date: Date,
        startHour: Int,
        startMinute: Int,
        durationMinutes: Int,
        weekdays: Set<Int>,
        calendar: Calendar = .current
    ) -> Date? {
        let startOfToday = calendar.startOfDay(for: date)
        for dayOffset in [0, -1] {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: startOfToday),
                  let start = calendar.date(
                      bySettingHour: startHour, minute: startMinute, second: 0, of: day
                  )
            else { continue }
            let end = start.addingTimeInterval(TimeInterval(durationMinutes * 60))
            if weekdays.contains(calendar.component(.weekday, from: start)),
               date >= start, date < end
            {
                return start
            }
        }
        return nil
    }
}

nonisolated struct ShieldExclusion {
    private(set) var selection = FamilyActivitySelection()
    private(set) var domains: Set<String> = []

    static func groupUnblocks(_ unblocks: [TimedUnblockDTO], at date: Date) -> ShieldExclusion {
        var exclusion = ShieldExclusion()
        for unblock in unblocks where unblock.isGroupUnblock && unblock.endDate > date {
            exclusion.add(unblock.selectionData, domains: unblock.customDomains)
        }
        return exclusion
    }

    static func activeSchedules(
        _ schedules: [ScheduleDTO],
        shouldBlock: Bool,
        at date: Date,
        excluding excludedID: UUID? = nil,
        calendar: Calendar = .current,
        isEnabled: (ScheduleDTO) -> Bool
    ) -> ShieldExclusion {
        var exclusion = ShieldExclusion()
        for schedule in schedules
            where schedule.id != excludedID
            && schedule.shouldBlock == shouldBlock
            && isEnabled(schedule)
            && schedule.isActive(at: date, calendar: calendar)
        {
            exclusion.add(schedule.selectionData, domains: schedule.customDomains)
        }
        return exclusion
    }

    func union(_ other: ShieldExclusion) -> ShieldExclusion {
        var merged = self
        merged.selection = selection.union(other.selection)
        merged.domains.formUnion(other.domains)
        return merged
    }

    private mutating func add(_ selectionData: Data, domains: [String]) {
        guard let added = try? FamilyActivitySelection.fromData(selectionData) else { return }
        selection = selection.union(added)
        self.domains.formUnion(domains)
    }

    func applied(to selection: FamilyActivitySelection) -> FamilyActivitySelection {
        selection.subtracting(self.selection)
    }

    func applied(to domains: [String]) -> [String] {
        domains.filter { !self.domains.contains($0) }
    }
}
