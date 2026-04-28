//
//  KeychainUUIDService.swift
//  SIMResearch
//
//  Persists a UUID in the device keychain so it survives app
//  uninstall/reinstall on the same physical device. This is the
//  iOS-sanctioned replacement for the long-removed
//  `UIDevice.uniqueIdentifier` and the blocked IMEI/serial reads —
//  banks use it as the persistent half of "device binding".
//
//  Storage class: `kSecClassGenericPassword`
//  Accessibility: `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`
//    * Available after the user first unlocks the device after a
//      reboot — required because we may be invoked from a launch
//      handler before the user has unlocked the device.
//    * `ThisDeviceOnly` blocks iCloud Keychain backup and restore-to-
//      a-new-device. The UUID is exactly what its name says: bound to
//      THIS physical device.
//

import Foundation
import Security

final class KeychainUUIDService {

    /// Process-wide service label for the keychain item. Defaults to
    /// the bundle identifier so multiple apps from the same vendor do
    /// not collide.
    private let service: String
    private let account = "device-uuid.v1"

    init(service: String? = nil) {
        self.service = service
            ?? Bundle.main.bundleIdentifier
            ?? "SIMResearch.KeychainUUIDService"
    }

    /// Returns the UUID for this device, generating and storing one
    /// on first call. Returns `nil` only when the keychain operation
    /// itself fails (e.g. storage-tampered system).
    @discardableResult
    func currentUUID() -> String? {
        if let existing = read() { return existing }
        let new = UUID().uuidString
        guard write(new) else { return nil }
        return new
    }

    /// Wipes the UUID. Used by the demo's reset action; production
    /// code should NOT call this on its own — losing it means the
    /// device looks brand-new to the backend.
    func reset() {
        SecItemDelete(baseQuery() as CFDictionary)
    }

    // MARK: - Private

    private func baseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }

    private func read() -> String? {
        var query = baseQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    private func write(_ value: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        var attributes = baseQuery()
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

        let status = SecItemAdd(attributes as CFDictionary, nil)
        if status == errSecSuccess { return true }
        if status == errSecDuplicateItem {
            // Another writer beat us; treat as success and let the
            // next read pick up whichever value won.
            return true
        }
        return false
    }
}
