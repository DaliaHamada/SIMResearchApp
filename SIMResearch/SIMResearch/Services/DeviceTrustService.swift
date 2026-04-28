//
//  DeviceTrustService.swift
//  SIMResearch
//
//  Aggregates the four App Store-safe device-trust layers — IDFV,
//  Keychain UUID, DeviceCheck, App Attest — behind a single API.
//  This is the artifact the app should use anywhere it would
//  otherwise have wanted IMEI/IMSI/ICCID/EID/MEID.
//

import Foundation
import UIKit

@MainActor
final class DeviceTrustService {

    private let keychain: KeychainUUIDService
    private let deviceCheck: DeviceCheckService
    private let appAttest: AppAttestService

    init(
        keychain: KeychainUUIDService = KeychainUUIDService(),
        deviceCheck: DeviceCheckService = DeviceCheckService(),
        appAttest: AppAttestService = AppAttestService()
    ) {
        self.keychain = keychain
        self.deviceCheck = deviceCheck
        self.appAttest = appAttest
    }

    /// Returns the snapshot WITHOUT touching the network. DeviceCheck
    /// and App Attest are reported as `ready` / `noKey` because the
    /// real generation calls hit Apple's servers and should be
    /// triggered explicitly by the UI.
    func staticSnapshot() -> DeviceTrustSnapshot {
        DeviceTrustSnapshot(
            identifierForVendor: UIDevice.current.identifierForVendor?.uuidString,
            keychainDeviceUUID: keychain.currentUUID(),
            deviceCheck: deviceCheck.isSupported ? .ready : .unsupported,
            appAttest: appAttestStaticState(),
            capturedAt: Date()
        )
    }

    private func appAttestStaticState() -> AppAttestState {
        guard appAttest.isSupported else { return .unsupported }
        if let keyId = appAttest.storedKeyId() {
            return .keyGenerated(keyId: keyId)
        }
        return .noKey
    }

    // MARK: - Active operations

    /// Generates a fresh DeviceCheck token. The backend exchanges it
    /// with Apple to read/write the team's two device bits.
    func generateDeviceCheckToken() async -> DeviceCheckState {
        do {
            let base64 = try await deviceCheck.currentTokenBase64()
            return .tokenGenerated(tokenBase64: base64, generatedAt: Date())
        } catch {
            return .failed(message: error.localizedDescription)
        }
    }

    /// Generates a fresh App Attest key in the Secure Enclave.
    func generateAppAttestKey() async -> AppAttestState {
        do {
            let keyId = try await appAttest.generateKey()
            return .keyGenerated(keyId: keyId)
        } catch {
            return .failed(message: error.localizedDescription)
        }
    }

    /// Attests an existing key. The challenge is generated locally
    /// for demo purposes — production code MUST fetch it from the
    /// backend, single-use.
    func attestExistingKey() async -> AppAttestState {
        guard let keyId = appAttest.storedKeyId() else {
            return .failed(message: AppAttestService.AttestError.keyMissing.localizedDescription)
        }
        let challenge = Self.demoChallenge()
        do {
            let attestation = try await appAttest.attestKey(keyId, challenge: challenge)
            return .attested(
                keyId: keyId,
                attestationByteCount: attestation.count,
                attestedAt: Date()
            )
        } catch {
            return .failed(message: error.localizedDescription)
        }
    }

    /// Signs a demo payload with the currently attested key. Returns
    /// the assertion bytes for inspection; production code would ship
    /// these alongside the request to the backend.
    func signDemoPayload(_ payload: String) async -> Result<Data, Error> {
        guard let keyId = appAttest.storedKeyId() else {
            return .failure(AppAttestService.AttestError.keyMissing)
        }
        guard let data = payload.data(using: .utf8) else {
            return .failure(AppAttestService.AttestError.assertionFailed(nil))
        }
        do {
            let assertion = try await appAttest.generateAssertion(keyId: keyId, clientData: data)
            return .success(assertion)
        } catch {
            return .failure(error)
        }
    }

    /// Wipes the Keychain UUID and the stored App Attest key id. The
    /// Secure Enclave key itself cannot be deleted from user code —
    /// it stays parked until the device is wiped — but losing the
    /// `keyId` makes it un-addressable.
    func resetLocalIdentity() {
        keychain.reset()
        appAttest.clearStoredKeyId()
    }

    private static func demoChallenge() -> Data {
        // 32 random bytes is what most server challenges use.
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes)
    }
}
