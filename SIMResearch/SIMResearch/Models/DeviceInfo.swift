//
//  DeviceInfo.swift
//  SIMResearch
//
//  A value type that represents everything we are allowed to read about
//  the host device through public iOS APIs (UIDevice, ProcessInfo,
//  utsname, NSLocale and friends).
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

    // MARK: - Capabilities

    /// `true` when the screen orientation can be detected.
    let isMultitaskingSupported: Bool

    /// Number of active CPU cores.
    let activeProcessorCount: Int

    /// Total physical memory in bytes.
    let physicalMemory: UInt64

    /// Battery level (0 – 1) or `nil` when monitoring is disabled.
    let batteryLevel: Float?

    /// Battery state (charging, full, …) or `nil` when monitoring is
    /// disabled.
    let batteryState: String?

    /// True when the user enabled Low Power Mode.
    let isLowPowerModeEnabled: Bool
}
