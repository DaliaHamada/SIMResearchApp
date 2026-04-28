//
//  DeviceTrust.swift
//  SIMResearch
//
//  The four-layer device-identity stack iOS exposes to App Store apps
//  in place of the blocked hardware identifiers (IMEI, IMSI, ICCID,
//  EID, MAC, MEID). This is the artifact you take to a banking /
//  government stakeholder when they ask for "IMEI" — every layer here
//  is App Store safe and most are technically stronger than IMEI for
//  the actual fraud / KYC use cases.
//
//  Layers, from weakest to strongest:
//
//  1. `identifierForVendor` (IDFV)
//     UUID per (vendor, device). Free, instant, no entitlement, no
//     prompt. Resets when the user uninstalls every app from the
//     vendor and reinstalls one. Public API since iOS 6.
//
//  2. Keychain-backed device UUID
//     UUID generated on first launch and stored in the *device*
//     keychain (`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`).
//     Survives app uninstall/reinstall on the same device because
//     keychain items live outside the app sandbox. Does NOT sync to
//     iCloud. Does NOT roam to a new device. Used by every major
//     bank for "remember this device" KYC binding.
//
//  3. DeviceCheck token (`DCDevice.generateToken`)
//     Apple-issued opaque blob the backend exchanges with Apple's
//     servers to read/write 2 bits of state per (device, developer
//     team). Cannot be spoofed by another developer's app. Available
//     since iOS 11.
//
//  4. App Attest assertion (`DCAppAttestService`)
//     Hardware-backed key in the Secure Enclave, attested by Apple
//     once at provisioning, then used to sign every sensitive request.
//     Per-request signature only an unmodified copy of THIS app on a
//     real Apple device can produce. Available since iOS 14, required
//     in practice for licensed financial apps in MENA / EU.
//

import Foundation

struct DeviceTrustSnapshot: Equatable {
    let identifierForVendor: String?
    let keychainDeviceUUID: String?
    let deviceCheck: DeviceCheckState
    let appAttest: AppAttestState
    let capturedAt: Date
}

/// State of the `DeviceCheck` (`DCDevice`) layer.
enum DeviceCheckState: Equatable {
    /// `DCDevice.current.isSupported == false`. True on Simulator and
    /// on a small set of older devices.
    case unsupported
    /// Supported, no token requested yet this session.
    case ready
    /// A token was generated and is ready to be sent to the backend.
    /// The token is opaque and is single-use from the backend's
    /// perspective — it must POST it to Apple's API to read/write the
    /// two device bits.
    case tokenGenerated(tokenBase64: String, generatedAt: Date)
    /// Generation failed.
    case failed(message: String)
}

/// State of the `App Attest` (`DCAppAttestService`) layer.
enum AppAttestState: Equatable {
    case unsupported
    case noKey
    /// A Secure Enclave key was generated. It still needs to be
    /// attested by Apple (one-shot, with a server-issued challenge)
    /// before it can be used to sign requests.
    case keyGenerated(keyId: String)
    /// The key is attested. Production code stores the attestation on
    /// the backend together with the customer record; the device
    /// keeps only the `keyId` and uses the key to generate per-request
    /// assertions.
    case attested(keyId: String, attestationByteCount: Int, attestedAt: Date)
    /// Either generation, attestation, or assertion failed.
    case failed(message: String)
}

extension DeviceTrustSnapshot {
    /// Concrete `(label, value)` rows for the UI / logs, skipping
    /// blank values exactly like `DeviceInfo.concreteCollectedStringFields`.
    var concreteRows: [(label: String, value: String)] {
        var rows: [(String, String)] = []
        if let v = identifierForVendor, !v.isEmpty { rows.append(("identifierForVendor", v)) }
        if let v = keychainDeviceUUID, !v.isEmpty { rows.append(("Keychain device UUID", v)) }
        switch deviceCheck {
        case .unsupported: rows.append(("DeviceCheck", "Not supported on this device"))
        case .ready: rows.append(("DeviceCheck", "Ready (no token requested)"))
        case .tokenGenerated(let token, _): rows.append(("DeviceCheck token", token))
        case .failed(let message): rows.append(("DeviceCheck error", message))
        }
        switch appAttest {
        case .unsupported: rows.append(("App Attest", "Not supported on this device"))
        case .noKey: rows.append(("App Attest", "No Secure Enclave key generated yet"))
        case .keyGenerated(let id): rows.append(("App Attest key id (un-attested)", id))
        case .attested(let id, let size, _):
            rows.append(("App Attest key id", id))
            rows.append(("App Attest attestation size", "\(size) bytes"))
        case .failed(let message): rows.append(("App Attest error", message))
        }
        return rows
    }
}
