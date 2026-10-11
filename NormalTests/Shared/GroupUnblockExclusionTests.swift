import FamilyControls
import Foundation
@testable import Normal
import Testing

struct GroupUnblockExclusionTests {
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

    @Test func removesAppsAndDomainsOfActiveGroupUnblocks() throws {
        let exclusion = try GroupUnblockExclusion(
            unblocks: [unblock(id: "g1", apps: [2], domains: ["b.com"])],
            at: .now
        )

        let remaining = exclusion.applied(to: TokenFixtures.selection(apps: [1, 2]))
        #expect(remaining.applicationTokens == [TokenFixtures.app(1)])
        #expect(exclusion.applied(to: ["a.com", "b.com"]) == ["a.com"])
    }

    @Test func ignoresExpiredGroupUnblocksAndMainUnblock() throws {
        let exclusion = try GroupUnblockExclusion(
            unblocks: [
                unblock(id: "g1", apps: [1], endDate: .now.addingTimeInterval(-60)),
                unblock(id: TimedUnblockService.mainID, apps: [2]),
            ],
            at: .now
        )

        let remaining = exclusion.applied(to: TokenFixtures.selection(apps: [1, 2]))
        #expect(remaining.applicationTokens == [TokenFixtures.app(1), TokenFixtures.app(2)])
    }
}
