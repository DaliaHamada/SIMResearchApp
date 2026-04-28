//
//  DeviceTrustViewModel.swift
//  SIMResearch
//

import Foundation
import SwiftUI

@MainActor
final class DeviceTrustViewModel: ObservableObject {

    @Published private(set) var snapshot: DeviceTrustSnapshot
    @Published private(set) var isWorking: Bool = false
    @Published var lastAssertion: Data?
    @Published var lastAssertionPayload: String = ""
    @Published var lastError: String?

    private let service: DeviceTrustService

    /// `service` is optional so the default value does NOT need to be
    /// constructed in the caller's (nonisolated) context. The init
    /// itself is `@MainActor` (the class is), so resolving the default
    /// here is safe.
    init(service: DeviceTrustService? = nil) {
        let resolved = service ?? DeviceTrustService()
        self.service = resolved
        self.snapshot = resolved.staticSnapshot()
    }

    func refresh() {
        snapshot = service.staticSnapshot()
    }

    // MARK: - DeviceCheck

    func generateDeviceCheckToken() {
        run { [self] in
            let state = await service.generateDeviceCheckToken()
            snapshot = DeviceTrustSnapshot(
                identifierForVendor: snapshot.identifierForVendor,
                keychainDeviceUUID: snapshot.keychainDeviceUUID,
                deviceCheck: state,
                appAttest: snapshot.appAttest,
                capturedAt: Date()
            )
        }
    }

    // MARK: - App Attest

    func generateAppAttestKey() {
        run { [self] in
            let state = await service.generateAppAttestKey()
            updateAppAttest(state)
        }
    }

    func attestExistingKey() {
        run { [self] in
            let state = await service.attestExistingKey()
            updateAppAttest(state)
        }
    }

    func signDemoPayload(_ payload: String) {
        run { [self] in
            let result = await service.signDemoPayload(payload)
            switch result {
            case .success(let data):
                lastAssertion = data
                lastAssertionPayload = payload
                lastError = nil
            case .failure(let error):
                lastAssertion = nil
                lastAssertionPayload = payload
                lastError = error.localizedDescription
            }
        }
    }

    // MARK: - Reset

    func resetLocalIdentity() {
        service.resetLocalIdentity()
        lastAssertion = nil
        lastAssertionPayload = ""
        lastError = nil
        refresh()
    }

    // MARK: - Helpers

    private func updateAppAttest(_ state: AppAttestState) {
        snapshot = DeviceTrustSnapshot(
            identifierForVendor: snapshot.identifierForVendor,
            keychainDeviceUUID: snapshot.keychainDeviceUUID,
            deviceCheck: snapshot.deviceCheck,
            appAttest: state,
            capturedAt: Date()
        )
    }

    private func run(_ work: @escaping () async -> Void) {
        guard !isWorking else { return }
        isWorking = true
        Task { @MainActor in
            await work()
            isWorking = false
        }
    }
}
