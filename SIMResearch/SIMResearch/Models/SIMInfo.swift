//
//  SIMInfo.swift
//  SIMResearch
//
//  Public-API representation of a single cellular subscription
//  ("SIM" – physical or eSIM) and a top-level snapshot of all
//  subscriptions reported by `CTTelephonyNetworkInfo`.
//

import Foundation

/// Information about a single cellular subscription.
///
/// On iOS 16+ Apple deprecated `CTCarrier` and the values returned for
/// `carrierName`, `mobileCountryCode`, `mobileNetworkCode` and
/// `isoCountryCode` are pinned to placeholder strings ("--"). We still
/// surface them so that the UI can clearly demonstrate the deprecation.
struct SIMSubscription: Identifiable, Equatable {

    /// CoreTelephony service identifier (e.g. `0000000100000001`). This
    /// identifier is stable for the lifetime of the cellular service and
    /// is the only way developers can tell two subscriptions apart.
    let id: String

    /// Carrier name (e.g. "Vodafone"). On iOS 16+ Apple returns "--".
    let carrierName: String?

    /// Mobile Country Code (3 digits).
    let mobileCountryCode: String?

    /// Mobile Network Code (2-3 digits).
    let mobileNetworkCode: String?

    /// ISO 3166 country code ("us", "de", …).
    let isoCountryCode: String?

    /// `true` if the carrier supports VoIP.
    let allowsVOIP: Bool

    /// Currently advertised radio access technology for this service
    /// (`CTRadioAccessTechnologyLTE`, `CTRadioAccessTechnologyNR`, …).
    let radioAccessTechnology: String?

    /// Human readable RAT name ("LTE", "5G NR", "3G" …).
    let radioAccessTechnologyDisplayName: String

    /// `true` when CoreTelephony returned the deprecated placeholder for
    /// the carrier metadata.
    var isDeprecatedCarrierMetadata: Bool {
        // iOS 16+ returns "--" or nil for the deprecated CTCarrier
        // properties.
        let placeholders: Set<String?> = ["--", "—", "", nil]
        return placeholders.contains(carrierName)
            && placeholders.contains(mobileCountryCode)
            && placeholders.contains(mobileNetworkCode)
    }
}

/// Aggregated state of every cellular service reported by the system.
struct SIMSnapshot: Equatable {
    /// All cellular subscriptions reported by the system.
    let subscriptions: [SIMSubscription]

    /// Identifier of the currently registered "data preferred"
    /// subscription, when CoreTelephony reports one.
    let dataServiceIdentifier: String?

    /// `true` when at least one cellular service is reported.
    var hasAnySIM: Bool { !subscriptions.isEmpty }

    /// `true` when more than one cellular service is reported.
    var isDualSIM: Bool { subscriptions.count > 1 }

    /// Best-effort estimate of whether the device is "eSIM capable".
    /// Apple does not expose a public flag, so we infer it from the
    /// number of services reported and the current device model. The
    /// caller should treat the result as advisory.
    let isLikelyESIMCapable: Bool

    /// Human-readable description of how many SIMs were detected.
    var summary: String {
        switch subscriptions.count {
        case 0: return "No active SIM detected"
        case 1: return "Single SIM (1 active subscription)"
        default: return "Dual SIM (\(subscriptions.count) active subscriptions)"
        }
    }
}
