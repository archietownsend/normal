import DeviceActivity
import Foundation

final class UITestDeviceActivityCenter: DeviceActivityProviding {
    private var schedules: [String: DeviceActivitySchedule] = [:]

    var monitoredActivityNames: Set<String> {
        Set(schedules.keys)
    }

    func startMonitoring(
        _ activityName: DeviceActivityName,
        during schedule: DeviceActivitySchedule,
        events _: [DeviceActivityEvent.Name: DeviceActivityEvent]
    ) throws {
        schedules[activityName.rawValue] = schedule
    }

    func stopMonitoring(_ activityNames: [DeviceActivityName]) {
        for name in activityNames {
            schedules.removeValue(forKey: name.rawValue)
        }
    }

    func registeredSchedule(for activityName: DeviceActivityName) -> DeviceActivitySchedule? {
        schedules[activityName.rawValue]
    }
}
