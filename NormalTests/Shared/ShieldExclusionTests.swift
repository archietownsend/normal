import FamilyControls
import Foundation
@testable import Normal
import Testing

struct ShieldExclusionTests {
    private let cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()

    // Wednesday, June 5 2024, 12:00 UTC.
    private var noonWednesday: Date {
        cal.date(from: DateComponents(year: 2024, month: 6, day: 5, hour: 12))!
    }

    private func unblock(
        id: String,
        apps: [UInt8],
        domains: [String] = [],
        endDate: Date = .now.addingTimeInterval(.hours(1))
    ) throws -> TimedUnblockDTO {
        try TimedUnblockDTO(
            id: id,
            selectionData: TokenFixtures.selection(apps: apps).toData(),
            endDate: endDate,
            activityName: "timedUnblock_\(id)",
            isGroupUnblock: id != TimedUnblockService.mainID,
            customDomains: domains
        )
    }

    private func schedule(
        apps: [UInt8],
        domains: [String] = [],
        startHour: Int = 10,
        durationMinutes: Int = 240,
        shouldBlock: Bool = true
    ) throws -> ScheduleDTO {
        try ScheduleDTO(
            id: UUID(),
            name: "S",
            selectionData: TokenFixtures.selection(apps: apps).toData(),
            startHour: startHour,
            startMinute: 0,
            durationMinutes: durationMinutes,
            weekdays: [4],
            shouldBlock: shouldBlock,
            isTimed: true,
            customDomains: domains
        )
    }

    @Test func removesAppsAndDomainsOfActiveGroupUnblocks() throws {
        let exclusion = try ShieldExclusion.groupUnblocks(
            [unblock(id: "g1", apps: [2], domains: ["b.com"])],
            at: .now
        )

        let remaining = exclusion.applied(to: TokenFixtures.selection(apps: [1, 2]))
        #expect(remaining.applicationTokens == [TokenFixtures.app(1)])
        #expect(exclusion.applied(to: ["a.com", "b.com"]) == ["a.com"])
    }

    @Test func ignoresExpiredGroupUnblocksAndMainUnblock() throws {
        let exclusion = try ShieldExclusion.groupUnblocks(
            [
                unblock(id: "g1", apps: [1], endDate: .now.addingTimeInterval(-60)),
                unblock(id: TimedUnblockService.mainID, apps: [2]),
            ],
            at: .now
        )

        let remaining = exclusion.applied(to: TokenFixtures.selection(apps: [1, 2]))
        #expect(remaining.applicationTokens == [TokenFixtures.app(1), TokenFixtures.app(2)])
    }

    @Test func keepsAppsOfOtherActiveSchedulesOfSameKind() throws {
        let ending = try schedule(apps: [1, 2], domains: ["a.com", "b.com"], startHour: 9, durationMinutes: 180)
        let stillRunning = try schedule(apps: [2, 3], domains: ["b.com"])

        let keep = ShieldExclusion.activeSchedules(
            [ending, stillRunning],
            shouldBlock: true,
            at: noonWednesday,
            excluding: ending.id,
            calendar: cal
        ) { _ in true }

        #expect(keep.applied(to: TokenFixtures.selection(apps: [1, 2])).applicationTokens == [TokenFixtures.app(1)])
        #expect(keep.applied(to: ["a.com", "b.com"]) == ["a.com"])
    }

    @Test func ignoresDisabledInactiveAndOtherKindSchedules() throws {
        let ending = try schedule(apps: [1], startHour: 9, durationMinutes: 180)
        let disabled = try schedule(apps: [1])
        let inactive = try schedule(apps: [1], startHour: 14, durationMinutes: 60)
        let allowing = try schedule(apps: [1], shouldBlock: false)

        let keep = ShieldExclusion.activeSchedules(
            [ending, disabled, inactive, allowing],
            shouldBlock: true,
            at: noonWednesday,
            excluding: ending.id,
            calendar: cal
        ) { $0.id != disabled.id }

        #expect(keep.applied(to: TokenFixtures.selection(apps: [1])).applicationTokens == [TokenFixtures.app(1)])
    }

    @Test func unionCombinesBothExclusions() throws {
        let groups = try ShieldExclusion.groupUnblocks([unblock(id: "g1", apps: [1])], at: .now)
        let schedules = try ShieldExclusion.activeSchedules(
            [schedule(apps: [2])],
            shouldBlock: true,
            at: noonWednesday,
            excluding: UUID(),
            calendar: cal
        ) { _ in true }

        let remaining = groups.union(schedules).applied(to: TokenFixtures.selection(apps: [1, 2, 3]))
        #expect(remaining.applicationTokens == [TokenFixtures.app(3)])
    }
}
