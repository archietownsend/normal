import FamilyControls
import Foundation
import ManagedSettings

enum TokenFixtures {
    static func app(_ id: UInt8) -> ApplicationToken {
        decode(id)
    }

    static func selection(apps: [UInt8]) -> FamilyActivitySelection {
        var selection = FamilyActivitySelection()
        selection.applicationTokens = Set(apps.map(app))
        return selection
    }

    private static func decode<T: Decodable>(_ id: UInt8) -> T {
        let json = #"{"data":"\#(Data([id]).base64EncodedString())"}"#
        return try! JSONDecoder().decode(T.self, from: Data(json.utf8))
    }
}
