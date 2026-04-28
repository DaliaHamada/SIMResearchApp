//
//  DeviceCheckService.swift
//  SIMResearch
//
//  Wraps Apple's `DCDevice.generateToken` API. The device-side call
//  is one line: it returns an opaque blob that the BACKEND exchanges
//  with Apple's servers (via JWT-signed REST call) to read or write
//  two device-scoped bits per developer team.
//
//  Where this fits in a banking flow
//  ---------------------------------
//  Bit 0 = "this device has previously enrolled in the bank app"
//  Bit 1 = "this device has been flagged for fraud"
//  Both bits persist across app uninstall, factory reset is required
//  to clear them. They're scoped to your developer team — competitor
//  apps cannot see or set them.
//
//  This class does NOT call Apple's REST API itself; that requires a
//  team-private signing key and must be done from the trusted
//  backend. It only produces the device-side token.
//

import Foundation
import DeviceCheck

final class DeviceCheckService {

    enum DeviceCheckError: Error, LocalizedError {
        case unsupported
        case generationFailed(underlying: Error?)

        var errorDescription: String? {
            switch self {
            case .unsupported:
                return "DCDevice is not supported on this device (Simulator or unsupported model)."
            case .generationFailed(let underlying):
                return "DeviceCheck token generation failed: \(underlying?.localizedDescription ?? "unknown error")"
            }
        }
    }

    /// `true` when DeviceCheck can be used. Always `false` on the
    /// iOS Simulator.
    var isSupported: Bool { DCDevice.current.isSupported }

    /// Generates a device token. The async variant is iOS 15+; the
    /// project's deployment target is iOS 18.2 so we use it directly.
    func currentToken() async throws -> Data {
        guard isSupported else { throw DeviceCheckError.unsupported }
        do {
            return try await DCDevice.current.generateToken()
        } catch {
            throw DeviceCheckError.generationFailed(underlying: error)
        }
    }

    /// Convenience: token as a base64 string for transport / display.
    func currentTokenBase64() async throws -> String {
        try await currentToken().base64EncodedString()
    }
}
