//
//  MSISDNLookupViewModel.swift
//  SIMResearch
//
//  Drives the MSISDN-via-USSD screen. State is per-carrier so the
//  user can run all four lookups (Vodafone / Etisalat / Orange / WE)
//  and review the results side-by-side.
//

import Foundation
import SwiftUI
import UIKit

/// Lifecycle phase of one carrier's lookup attempt.
enum CarrierLookupPhase: Equatable {
    case idle
    case dialing
    /// The dialer was presented to the user; waiting for them to read
    /// the carrier's response and type it back.
    case awaitingUserInput
    /// iOS refused to open the URL (typically `#119#`). UI should
    /// show copy-to-clipboard plus manual-dial guidance.
    case manualDialRequired
    /// Last call to `UIApplication.open` failed for an unknown reason.
    case dialFailed
    /// User saved a value but it could not be parsed as an Egyptian
    /// mobile number.
    case invalidInput
}

@MainActor
final class MSISDNLookupViewModel: ObservableObject {

    @Published private(set) var entries: [MSISDNEntry] = []
    @Published private(set) var phaseByCarrier: [EgyptianCarrier: CarrierLookupPhase] = [:]

    private let service: USSDLookupService

    init(service: USSDLookupService = USSDLookupService()) {
        self.service = service
        self.entries = service.capturedEntries()
        for carrier in EgyptianCarrier.allCases {
            phaseByCarrier[carrier] = .idle
        }
    }

    // MARK: - Derived

    func phase(for carrier: EgyptianCarrier) -> CarrierLookupPhase {
        phaseByCarrier[carrier] ?? .idle
    }

    func latestEntry(for carrier: EgyptianCarrier) -> MSISDNEntry? {
        entries.first { $0.carrier == carrier }
    }

    var ussdCodeReference: [(carrier: EgyptianCarrier, code: String)] {
        EgyptianCarrier.allCases.map { ($0, $0.ussdCode) }
    }

    // MARK: - Actions

    /// Triggers the system dialer for the carrier. The dialer ALWAYS
    /// shows the user's confirmation sheet — there is no public iOS
    /// API that bypasses it.
    func dial(_ carrier: EgyptianCarrier) {
        if carrier.requiresManualDial {
            phaseByCarrier[carrier] = .manualDialRequired
            UIPasteboard.general.string = carrier.ussdCode
            return
        }

        phaseByCarrier[carrier] = .dialing
        service.dial(carrier) { [weak self] result in
            Task { @MainActor [weak self] in
                guard let self else { return }
                switch result {
                case .dialerPresented:
                    self.phaseByCarrier[carrier] = .awaitingUserInput
                case .dialerRefused:
                    UIPasteboard.general.string = carrier.ussdCode
                    self.phaseByCarrier[carrier] = .manualDialRequired
                case .malformedURL:
                    self.phaseByCarrier[carrier] = .dialFailed
                }
            }
        }
    }

    /// Copies the USSD code to the clipboard so the user can paste it
    /// into the dialer manually (used as a fallback for `#119#`).
    func copyCode(for carrier: EgyptianCarrier) {
        UIPasteboard.general.string = carrier.ussdCode
    }

    /// Validates and stores the MSISDN the user copied from the
    /// carrier's USSD response.
    @discardableResult
    func saveMSISDN(_ raw: String, for carrier: EgyptianCarrier) -> Bool {
        guard let _ = service.saveCapturedNumber(raw, for: carrier) else {
            phaseByCarrier[carrier] = .invalidInput
            return false
        }
        entries = service.capturedEntries()
        phaseByCarrier[carrier] = .idle
        return true
    }

    /// Forgets the captured MSISDN for `carrier`.
    func reset(_ carrier: EgyptianCarrier) {
        phaseByCarrier[carrier] = .idle
    }

    /// Forgets every captured MSISDN. Useful when re-running the
    /// research to capture a fresh round of values.
    func clearAll() {
        service.clearAll()
        entries = []
        for carrier in EgyptianCarrier.allCases {
            phaseByCarrier[carrier] = .idle
        }
    }
}
