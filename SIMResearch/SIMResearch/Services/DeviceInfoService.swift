import Foundation
import UIKit

struct DeviceInfoService {
    func snapshot() -> DeviceInfoSnapshot {
        let device = UIDevice.current

        // iOS 16+ returns a generic name unless the app has Apple's
        // user-assigned-device-name entitlement.
        let items = [
            InfoItem(
                name: "Device name",
                value: device.name,
                detail: "On iOS 16 and later this is usually a generic name such as \"iPhone\" unless Apple grants a special entitlement."
            ),
            InfoItem(name: "Model", value: device.model),
            InfoItem(name: "Localized model", value: device.localizedModel),
            InfoItem(name: "Machine identifier", value: machineIdentifier()),
            InfoItem(name: "System", value: device.systemName),
            InfoItem(name: "System version", value: device.systemVersion),
            InfoItem(
                name: "Identifier for vendor",
                value: device.identifierForVendor?.uuidString ?? "Unavailable",
                detail: "Publicly available, but scoped to this app vendor and can change after all apps from the same vendor are removed."
            )
        ]

        let summary = "\(device.model) running \(device.systemName) \(device.systemVersion)"

        let notes = [
            "No runtime permission prompt is required for UIDevice properties used in this demo.",
            "The user-assigned device name is privacy-protected on iOS 16+ unless Apple approves the dedicated entitlement.",
            "iOS does not expose hardware identifiers such as IMEI, serial number, or UDID to App Store apps."
        ]

        return DeviceInfoSnapshot(summary: summary, items: items, notes: notes)
    }

    private func machineIdentifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)

        return withUnsafePointer(to: &systemInfo.machine) { pointer in
            pointer.withMemoryRebound(to: CChar.self, capacity: 1) { cString in
                String(cString: cString)
            }
        }
    }
}
