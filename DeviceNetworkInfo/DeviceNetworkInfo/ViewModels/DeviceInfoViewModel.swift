import Foundation

/// ViewModel that bridges DeviceInfoService data to SwiftUI views.
@MainActor
final class DeviceInfoViewModel: ObservableObject {

    @Published var rows: [InfoRow] = []

    private let service = DeviceInfoService()

    func refresh() {
        let info = service.collectDeviceInfo()

        rows = [
            InfoRow(label: "Device Name", value: info.name,
                    detail: "iOS 16+ may return generic name for privacy"),
            InfoRow(label: "Model", value: info.model),
            InfoRow(label: "Localized Model", value: info.localizedModel),
            InfoRow(label: "System", value: "\(info.systemName) \(info.systemVersion)"),
            InfoRow(label: "Identifier for Vendor", value: info.identifierForVendor ?? "Unavailable",
                    detail: "Unique per vendor; resets if all vendor apps are deleted"),
            InfoRow(label: "User Interface Idiom", value: info.userInterfaceIdiom),
            InfoRow(label: "Multitasking", value: info.isMultitaskingSupported ? "Supported" : "Not Supported"),
            InfoRow(label: "Battery Level", value: info.batteryLevel >= 0
                    ? "\(Int(info.batteryLevel * 100))%"
                    : "Unknown"),
            InfoRow(label: "Battery State", value: info.batteryState),
            InfoRow(label: "Screen Size", value: info.screenBounds),
            InfoRow(label: "Screen Scale", value: info.screenScale),
            InfoRow(label: "Native Scale", value: info.screenNativeScale),
            InfoRow(label: "Processor Count", value: "\(info.processorCount)"),
            InfoRow(label: "Physical Memory", value: info.physicalMemory),
            InfoRow(label: "System Uptime", value: info.systemUptime),
            InfoRow(label: "Preferred Languages", value: info.preferredLanguages.joined(separator: ", ")),
            InfoRow(label: "Locale", value: info.currentLocale),
            InfoRow(label: "Time Zone", value: info.timeZone)
        ]
    }
}
