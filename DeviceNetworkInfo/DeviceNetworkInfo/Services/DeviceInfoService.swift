import UIKit

/// Service responsible for collecting device-level information using UIDevice and ProcessInfo.
///
/// APIs used:
/// - `UIDevice.current` — model, name, system info, battery, etc.
/// - `ProcessInfo.processInfo` — processor count, memory, uptime.
/// - `UIScreen.main` — screen dimensions and scale.
/// - `Locale` / `TimeZone` — locale and timezone info.
///
/// Limitations:
/// - `UIDevice.current.name` returns a generic name (e.g., "iPhone") starting with iOS 16
///   unless the user has granted the app the entitlement or Local Network permission.
/// - `identifierForVendor` can return nil if the device is locked or uninitialized.
/// - UDID, serial number, and IMEI are NOT accessible via public APIs.
final class DeviceInfoService {

    func collectDeviceInfo() -> DeviceInfo {
        let device = UIDevice.current
        device.isBatteryMonitoringEnabled = true

        let processInfo = ProcessInfo.processInfo
        let screen = UIScreen.main

        let idiomDescription: String
        switch device.userInterfaceIdiom {
        case .phone: idiomDescription = "iPhone"
        case .pad: idiomDescription = "iPad"
        case .tv: idiomDescription = "Apple TV"
        case .carPlay: idiomDescription = "CarPlay"
        case .mac: idiomDescription = "Mac"
        case .vision: idiomDescription = "Apple Vision"
        @unknown default: idiomDescription = "Unknown"
        }

        let batteryStateDescription: String
        switch device.batteryState {
        case .unknown: batteryStateDescription = "Unknown"
        case .unplugged: batteryStateDescription = "Unplugged"
        case .charging: batteryStateDescription = "Charging"
        case .full: batteryStateDescription = "Full"
        @unknown default: batteryStateDescription = "Unknown"
        }

        let uptimeSeconds = Int(processInfo.systemUptime)
        let hours = uptimeSeconds / 3600
        let minutes = (uptimeSeconds % 3600) / 60
        let seconds = uptimeSeconds % 60
        let uptimeFormatted = "\(hours)h \(minutes)m \(seconds)s"

        let memoryGB = Double(processInfo.physicalMemory) / 1_073_741_824
        let memoryFormatted = String(format: "%.1f GB", memoryGB)

        return DeviceInfo(
            name: device.name,
            model: device.model,
            localizedModel: device.localizedModel,
            systemName: device.systemName,
            systemVersion: device.systemVersion,
            identifierForVendor: device.identifierForVendor?.uuidString,
            isMultitaskingSupported: device.isMultitaskingSupported,
            userInterfaceIdiom: idiomDescription,
            batteryLevel: device.batteryLevel,
            batteryState: batteryStateDescription,
            screenBounds: "\(Int(screen.bounds.width)) × \(Int(screen.bounds.height)) pts",
            screenScale: "\(screen.scale)x",
            screenNativeScale: "\(screen.nativeScale)x",
            processorCount: processInfo.processorCount,
            physicalMemory: memoryFormatted,
            systemUptime: uptimeFormatted,
            preferredLanguages: Locale.preferredLanguages,
            currentLocale: Locale.current.identifier,
            timeZone: TimeZone.current.identifier
        )
    }
}
