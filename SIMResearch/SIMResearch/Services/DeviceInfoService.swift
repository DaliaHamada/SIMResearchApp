//
//  DeviceInfoService.swift
//  SIMResearch
//
//  Reads the current device snapshot using only public iOS APIs:
//  * UIDevice
//  * uname() / utsname (POSIX, public)
//  * Locale / TimeZone
//

import Foundation
import UIKit

/// Reads `DeviceInfo` snapshots on demand.
///
/// The service is intentionally synchronous – every read it performs is
/// O(1) and inexpensive. View models call `currentSnapshot()` on the
/// main thread.
final class DeviceInfoService {

    /// Returns a fresh snapshot of the current device state.
    func currentSnapshot() -> DeviceInfo {
        let device = UIDevice.current
        let hardwareID = Self.readHardwareIdentifier()

        return DeviceInfo(
            deviceName: device.name,
            marketingModel: Self.marketingName(for: hardwareID) ?? hardwareID,
            hardwareIdentifier: hardwareID,
            model: device.model,
            localizedModel: device.localizedModel,
            systemName: device.systemName,
            systemVersion: device.systemVersion,
            kernelName: Self.readKernelName(),
            identifierForVendor: device.identifierForVendor?.uuidString,
            localeIdentifier: Locale.current.identifier,
            regionCode: Self.regionCode(),
            preferredLanguages: Locale.preferredLanguages,
            timeZoneIdentifier: TimeZone.current.identifier
        )
    }

    // MARK: - Helpers

    /// Calls `uname()` to retrieve the hardware identifier
    /// ("iPhone16,1"). This is a public POSIX API and is App Store safe.
    private static func readHardwareIdentifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let mirror = Mirror(reflecting: systemInfo.machine)
        let identifier = mirror.children.reduce(into: "") { partial, element in
            guard let value = element.value as? Int8, value != 0 else { return }
            partial.append(String(UnicodeScalar(UInt8(value))))
        }
        return identifier.isEmpty ? "Unknown" : identifier
    }

    /// Reads the POSIX kernel name ("Darwin").
    private static func readKernelName() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let mirror = Mirror(reflecting: systemInfo.sysname)
        return mirror.children.reduce(into: "") { partial, element in
            guard let value = element.value as? Int8, value != 0 else { return }
            partial.append(String(UnicodeScalar(UInt8(value))))
        }
    }

    /// Resolves the user's region in a Swift 5/6 friendly way.
    private static func regionCode() -> String? {
        if #available(iOS 16.0, *) {
            return Locale.current.region?.identifier
        } else {
            return Locale.current.regionCode
        }
    }

    /// Marketing names for hardware identifiers. The list intentionally
    /// covers only iPhone family devices – on unknown identifiers the
    /// caller falls back to the raw value.
    ///
    /// New device identifiers are added by Apple every September; treat
    /// this map as a best-effort enrichment only.
    private static func marketingName(for identifier: String) -> String? {
        switch identifier {
        // iPhones
        case "iPhone8,1": return "iPhone 6s"
        case "iPhone8,2": return "iPhone 6s Plus"
        case "iPhone8,4": return "iPhone SE (1st gen)"
        case "iPhone9,1", "iPhone9,3": return "iPhone 7"
        case "iPhone9,2", "iPhone9,4": return "iPhone 7 Plus"
        case "iPhone10,1", "iPhone10,4": return "iPhone 8"
        case "iPhone10,2", "iPhone10,5": return "iPhone 8 Plus"
        case "iPhone10,3", "iPhone10,6": return "iPhone X"
        case "iPhone11,2": return "iPhone XS"
        case "iPhone11,4", "iPhone11,6": return "iPhone XS Max"
        case "iPhone11,8": return "iPhone XR"
        case "iPhone12,1": return "iPhone 11"
        case "iPhone12,3": return "iPhone 11 Pro"
        case "iPhone12,5": return "iPhone 11 Pro Max"
        case "iPhone12,8": return "iPhone SE (2nd gen)"
        case "iPhone13,1": return "iPhone 12 mini"
        case "iPhone13,2": return "iPhone 12"
        case "iPhone13,3": return "iPhone 12 Pro"
        case "iPhone13,4": return "iPhone 12 Pro Max"
        case "iPhone14,2": return "iPhone 13 Pro"
        case "iPhone14,3": return "iPhone 13 Pro Max"
        case "iPhone14,4": return "iPhone 13 mini"
        case "iPhone14,5": return "iPhone 13"
        case "iPhone14,6": return "iPhone SE (3rd gen)"
        case "iPhone14,7": return "iPhone 14"
        case "iPhone14,8": return "iPhone 14 Plus"
        case "iPhone15,2": return "iPhone 14 Pro"
        case "iPhone15,3": return "iPhone 14 Pro Max"
        case "iPhone15,4": return "iPhone 15"
        case "iPhone15,5": return "iPhone 15 Plus"
        case "iPhone16,1": return "iPhone 15 Pro"
        case "iPhone16,2": return "iPhone 15 Pro Max"
        case "iPhone17,1": return "iPhone 16 Pro"
        case "iPhone17,2": return "iPhone 16 Pro Max"
        case "iPhone17,3": return "iPhone 16"
        case "iPhone17,4": return "iPhone 16 Plus"
        // Simulators report architecture identifiers.
        case "i386", "x86_64", "arm64":
            return "Simulator (\(identifier))"
        default:
            return nil
        }
    }
}
