//
//  IdentifierLifecycle.swift
//  SIMResearch
//
//  A catalog of every identifier this app can read from iOS, with
//  the exact event that resets each one. Built specifically for the
//  question "I want one unique ID for the phone — when does it
//  change and why?".
//
//  Reference docs:
//    * https://developer.apple.com/documentation/foundation/uuid
//      A UUID is a 128-bit value used as an identifier. Foundation
//      generates v4 (random) UUIDs by default.
//    * https://developer.apple.com/documentation/uikit/uidevice/identifierforvendor
//      "An alphanumeric string that uniquely identifies a device to
//      the app's vendor." Apple's documented behaviour (paraphrased):
//        - Same value across all apps from the same vendor on the
//          same device.
//        - Returns `nil` briefly after install while the device is
//          still locked.
//        - **Resets** when the user uninstalls every app from the
//          vendor and then reinstalls one.
//        - Different vendor => different value.
//        - New device (Quick Start / restore from backup) => new
//          value, because the underlying device is different.
//

import Foundation

/// Every event that could potentially reset an identifier. The view
/// shows a check (changes) or x (does not change) per trigger per
/// identifier so the user can compare them side-by-side.
enum IdentifierChangeTrigger: String, CaseIterable, Identifiable, Codable {
    case appRelaunch       = "App relaunched"
    case backgroundForeground = "Background ↔ foreground"
    case osUpdate          = "iOS minor / major update"
    case reboot            = "Device rebooted"
    case appReinstall      = "This app uninstalled & reinstalled"
    case allVendorRemoved  = "ALL apps from this vendor removed, then one reinstalled"
    case differentTeam     = "Build signed with a different developer team"
    case simSwap           = "SIM swap or new carrier"
    case factoryReset      = "Erase All Content and Settings"
    case newDevice         = "Migrated to a NEW iPhone (Quick Start / iCloud restore)"

    var id: String { rawValue }
}

/// How long the identifier "survives" — used as a quick badge and to
/// rank identifiers by stability.
enum IdentifierStability: Int, Comparable, Codable {
    /// Different value every single time you call the API.
    case perCall = 0
    /// Stable for the lifetime of one app install.
    case perAppInstall = 10
    /// Stable for the lifetime of any of this vendor's apps being
    /// installed on the device. (IDFV)
    case perVendorInstall = 20
    /// Stable for the lifetime of one Secure Enclave key.
    case perSEPKey = 30
    /// Stable as long as this physical device is not factory-wiped.
    /// Survives uninstall, OS update, reboot.
    case perDevice = 40
    /// The same value forever for the same hardware. Cannot change
    /// without replacing parts of the device.
    case immutable = 50

    static func < (lhs: IdentifierStability, rhs: IdentifierStability) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var label: String {
        switch self {
        case .perCall:           return "Per call"
        case .perAppInstall:     return "Per app install"
        case .perVendorInstall:  return "Per vendor install (IDFV-class)"
        case .perSEPKey:         return "Per Secure Enclave key"
        case .perDevice:         return "Per device (until factory wipe)"
        case .immutable:         return "Immutable hardware fact"
        }
    }
}

/// One row in the catalog.
struct IdentifierLifecycleEntry: Identifiable, Equatable {
    let id: String           // stable key for SwiftUI
    let displayName: String
    let sourceAPI: String    // human-readable source ("UIDevice.identifierForVendor")
    let documentationURL: URL?
    let liveValue: String?
    let stability: IdentifierStability
    /// Triggers that DO change this value. Anything not in here is
    /// implicitly safe.
    let changedBy: Set<IdentifierChangeTrigger>
    let notes: String

    /// `true` when `trigger` definitely changes this identifier.
    func changes(on trigger: IdentifierChangeTrigger) -> Bool {
        changedBy.contains(trigger)
    }
}
