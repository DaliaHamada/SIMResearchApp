//
//  DeviceInfoService.swift
//  Collects device identity and model information using public Apple APIs and `uname` (Darwin).
//  `identifierForVendor` is the only programmatic “device id” a normal app can read; UDID and serial are not available.
//

import Foundation
import Darwin
import UIKit

enum DeviceInfoService {
    // MARK: - Public

    static func makeDeviceSection() -> [DataField] {
        var rows: [DataField] = []

        rows.append(
            DataField(
                label: "Device name (user-set)",
                value: UIDevice.current.name,
                api: "UIDevice.name",
                availability: .generallyAvailable
            )
        )

        rows.append(
            DataField(
                label: "Model (marketing / generic)",
                value: "\(UIDevice.current.localizedModel) — \(UIDevice.current.model)",
                api: "UIDevice.localizedModel, UIDevice.model",
                availability: .generallyAvailable
            )
        )

        let hw = hardwareModelIdentifier
        rows.append(
            DataField(
                label: "Hardware model identifier",
                value: hw,
                api: "utsname (Darwin) — e.g. iPhone15,2 for “which iPhone”",
                availability: .deviceOnly,
                note: "Simulator may report x86_64, arm64, or Mac-like identifiers."
            )
        )

        rows.append(
            DataField(
                label: "System version",
                value: "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)",
                api: "UIDevice.systemName, systemVersion",
                availability: .generallyAvailable
            )
        )

        if let idfv = UIDevice.current.identifierForVendor?.uuidString {
            rows.append(
                DataField(
                    label: "Identifier for vendor (IDFV)",
                    value: idfv,
                    api: "UIDevice.identifierForVendor",
                    availability: .generallyAvailable,
                    note: "Tied to your app’s vendor; resets if all of that vendor’s apps are removed from the device."
                )
            )
        } else {
            rows.append(
                DataField(
                    label: "Identifier for vendor (IDFV)",
                    value: "Not available",
                    api: "UIDevice.identifierForVendor",
                    availability: .oftenRestricted
                )
            )
        }

        rows.append(
            DataField(
                label: "User interface idiom",
                value: idiomString(UIDevice.current.userInterfaceIdiom),
                api: "UIDevice.userInterfaceIdiom",
                availability: .generallyAvailable
            )
        )

        if let screen = UIScreen.main as UIScreen? {
            let native = screen.nativeBounds.size
            let scale = screen.nativeScale
            rows.append(
                DataField(
                    label: "Main display (native size @ scale)",
                    value: String(format: "%.0f × %.0f @ %.0fx (native points)", native.width, native.height, scale),
                    api: "UIScreen (main) nativeBounds, nativeScale",
                    availability: .generallyAvailable,
                    note: "Use window scene on multi-display iPad setups; on typical iPhone, one main screen."
                )
            )
        }

        // Battery: values are only meaningful with monitoring on (idempotent in practice).
        UIDevice.current.isBatteryMonitoringEnabled = true
        rows.append(
            DataField(
                label: "Battery (approx.)",
                value: batteryInfoLine,
                api: "UIDevice.batteryLevel, batteryState (with isBatteryMonitoringEnabled = true)",
                availability: .userControllable,
                note: "Level is -1.0 if unknown; may not update until monitoring is enabled."
            )
        )

        return rows
    }

    // MARK: - Private

    private static var hardwareModelIdentifier: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        return withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) { ptr in
                String(cString: ptr)
            }
        }
    }

    private static func idiomString(_ idiom: UIUserInterfaceIdiom) -> String {
        switch idiom {
        case .phone: return "iPhone"
        case .pad: return "iPad"
        case .tv: return "tv"
        case .carPlay: return "CarPlay"
        case .mac: return "Mac (Designed for iPad)"
        case .vision: return "visionOS"
        case .unspecified: return "Unspecified"
        @unknown default: return "Unknown (raw: \(idiom.rawValue))"
        }
    }

    private static var batteryInfoLine: String {
        let level = UIDevice.current.batteryLevel
        let state = UIDevice.current.batteryState
        if level < 0 { return "Unknown (enable battery monitoring; may stay unknown on some builds)" }
        let pct = Int((level * 100).rounded())
        let stateStr: String
        switch state {
        case .unknown: stateStr = "state unknown"
        case .unplugged: stateStr = "unplugged"
        case .charging: stateStr = "charging"
        case .full: stateStr = "full"
        @unknown default: stateStr = "other"
        }
        return "\(pct)% — \(stateStr)"
    }
}
