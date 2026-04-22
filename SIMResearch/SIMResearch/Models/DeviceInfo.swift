//
//  DeviceInfo.swift
//  SIMResearch
//
//  A value type that represents everything we are allowed to read about
//  the host device through public iOS APIs (UIDevice, utsname,
//  Locale and friends).
//

import Foundation

/// Snapshot of public, non-sensitive information about the device.
///
/// All properties are optional / `String` because some values may not be
/// available on every iOS version, or might be redacted for privacy.
struct DeviceInfo: Equatable {

    // MARK: - Identity

    /// User-supplied device name. Starting with iOS 16 this returns the
    /// generic model name (e.g. "iPhone") for non-entitled apps.
    let deviceName: String

    /// Marketing model name (e.g. "iPhone 15 Pro"). Derived from the
    /// hardware identifier returned by `uname()`.
    let marketingModel: String

    /// Raw hardware identifier (e.g. "iPhone16,1").
    let hardwareIdentifier: String

    /// Generic device model exposed by `UIDevice` ("iPhone", "iPad" …).
    let model: String

    /// Localized device model.
    let localizedModel: String

    // MARK: - Operating system

    /// Marketing OS name ("iOS", "iPadOS").
    let systemName: String

    /// OS version string ("17.4.1").
    let systemVersion: String

    /// Best-effort kernel build (e.g. "Darwin"). Useful only in DEBUG.
    let kernelName: String

    // MARK: - Identifiers

    /// `identifierForVendor` (UUID, scoped to the vendor) – may be `nil`
    /// in rare cases (immediately after install while the device is
    /// locked, for example).
    let identifierForVendor: String?

    // MARK: - Locale & region

    /// Current locale identifier ("en_US").
    let localeIdentifier: String

    /// Region code ("US").
    let regionCode: String?

    /// Preferred languages (BCP-47 tags).
    let preferredLanguages: [String]

    /// Current time zone identifier ("Europe/Berlin").
    let timeZoneIdentifier: String
}

extension DeviceInfo {

    /// Hardware / device context fields with non-empty string values (skips optional fields that are `nil` or blank).
    var concreteCollectedStringFields: [(label: String, value: String)] {
        var rows: [(label: String, value: String)] = []
        func add(_ label: String, _ value: String?) {
            guard let v = value?.trimmingCharacters(in: .whitespacesAndNewlines), !v.isEmpty else { return }
            rows.append((label, v))
        }
        add("Device name", deviceName)
        add("Marketing model", marketingModel)
        add("Hardware identifier", hardwareIdentifier)
        add("Generic model", model)
        add("Localized model", localizedModel)
        add("System name", systemName)
        add("System version", systemVersion)
        add("Kernel", kernelName)
        add("identifierForVendor", identifierForVendor)
        add("Locale", localeIdentifier)
        add("Region", regionCode)
        add("Time zone", timeZoneIdentifier)
        if !preferredLanguages.isEmpty {
            rows.append(("Preferred languages", preferredLanguages.joined(separator: ", ")))
        }
        return rows
    }
}
