//
//  CellularInfoService.swift
//  Uses CoreTelephony: multiple cellular plans, carrier metadata, and radio access technology.
//
//  Limitations (public API, Apple’s design):
//  - CTCarrier and several CTTelephonyNetworkInfo members are **deprecated**; from iOS 16 onward,
//    many carrier string fields are often **empty** for privacy. This app still calls them to show
//    what the system actually returns.
//  - There is no public API for ICCID, IMSI, EID, or phone number, or for physical vs eSIM labels.
//  - Keys in `serviceSubscriberCellularProviders` are **opaque** — not a stable hardware ID.
//

import Foundation
import CoreTelephony

enum CellularInfoService {
    // MARK: - Public

    static func loadSummary() -> CellularSummary {
        let info = CTTelephonyNetworkInfo()
        var systemWarning: String?
        if #available(iOS 16.0, *) {
            systemWarning = "On iOS 16+, CTCarrier string properties are deprecated and may be nil or empty. Radio access technology may still be reported per service."
        }

        // Per-service current RAT, when available
        var ratByKey: [String: String] = [:]
        if #available(iOS 12.0, *), let r = info.serviceCurrentRadioAccessTechnology {
            ratByKey = r
        }

        var slots: [CellularSlotInfo] = []

        if #available(iOS 12.0, *) {
            if let providers = info.serviceSubscriberCellularProviders, !providers.isEmpty {
                for (key, carrier) in providers {
                    let rat = ratByKey[key] ?? (providers.count == 1 ? info.currentRadioAccessTechnology : nil)
                    let isPreferred = resolveDataPreferred(
                        key: key,
                        providerCount: providers.count,
                        dataServiceId: dataServiceIdentifierIfAvailable(info)
                    )
                    let slot = buildSlot(
                        key: key,
                        carrier: carrier,
                        rat: rat,
                        isDataPreferred: isPreferred
                    )
                    slots.append(slot)
                }
            } else if let carrier = info.subscriberCellularProvider {
                // If the per-service map is nil/empty, fall back to the legacy property when present.
                let rat = info.currentRadioAccessTechnology
                let slot = buildSlot(
                    key: "subscriberCellularProvider (fallback)",
                    carrier: carrier,
                    rat: rat,
                    isDataPreferred: true
                )
                slots = [slot]
            }
        } else if let carrier = info.subscriberCellularProvider {
            let rat = info.currentRadioAccessTechnology
            let slot = buildSlot(
                key: "primary (subscriberCellularProvider)",
                carrier: carrier,
                rat: rat,
                isDataPreferred: true
            )
            slots = [slot]
        }

        slots.sort { a, b in
            if a.isDataPreferred != b.isDataPreferred { return a.isDataPreferred }
            return a.id < b.id
        }

        let count = slots.count
        let interpretation: String
        if count == 0 {
            interpretation = "No active cellular line reported. Common on Simulator, in-flight mode, or without a plan."
        } else if count == 1 {
            interpretation = "One line reported. Does not prove the absence of additional inactive eSIMs."
        } else {
            interpretation = "Multiple active lines. Public API does not name physical vs eSIM."
        }

        return CellularSummary(
            slotCount: count,
            interpretation: interpretation,
            systemWarning: systemWarning,
            slots: slots,
            serviceRadioTechnologies: ratByKey
        )
    }

    // MARK: - Private

    @available(iOS 16.0, *)
    private static func dataServiceIdForComparison(_ info: CTTelephonyNetworkInfo) -> String? {
        // Property name per Apple: line used for mobile data
        // Note: if unavailable, returns nil on some devices — compare carefully.
        return info.dataServiceIdentifier
    }

    private static func dataServiceIdentifierIfAvailable(_ info: CTTelephonyNetworkInfo) -> String? {
        if #available(iOS 16.0, *) {
            return dataServiceIdForComparison(info)
        }
        return nil
    }

    private static func resolveDataPreferred(
        key: String,
        providerCount: Int,
        dataServiceId: String?
    ) -> Bool {
        if let ds = dataServiceId, !ds.isEmpty { return key == ds }
        return providerCount == 1
    }

    private static func buildSlot(
        key: String,
        carrier: CTCarrier,
        rat: String?,
        isDataPreferred: Bool
    ) -> CellularSlotInfo {
        let name = nonEmptyString(carrier.carrierName) ?? "— (unavailable; privacy or carrier may hide)"
        let mcc = nonEmptyString(carrier.mobileCountryCode) ?? "—"
        let mnc = nonEmptyString(carrier.mobileNetworkCode) ?? "—"
        let iso = nonEmptyString(carrier.isoCountryCode) ?? "—"
        let voip = carrier.allowsVOIP
        let ratLabel: String = {
            if let r = rat { return mapRAT(r) ?? r }
            return "—"
        }()

        var fields: [DataField] = [
            DataField(
                label: "Service / subscription key (opaque)",
                value: key,
                api: "CTTelephonyNetworkInfo.serviceSubscriberCellularProviders keys",
                availability: .deviceOnly,
                note: "This is not ICCID, IMSI, or phone number."
            ),
            DataField(
                label: "Carrier name",
                value: name,
                api: "CTCarrier.carrierName",
                availability: .oftenRestricted
            ),
            DataField(
                label: "Mobile country code (MCC)",
                value: mcc,
                api: "CTCarrier.mobileCountryCode",
                availability: .oftenRestricted
            ),
            DataField(
                label: "Mobile network code (MNC)",
                value: mnc,
                api: "CTCarrier.mobileNetworkCode",
                availability: .oftenRestricted
            ),
            DataField(
                label: "ISO country code",
                value: iso == "—" ? "—" : iso.uppercased(),
                api: "CTCarrier.isoCountryCode",
                availability: .oftenRestricted
            ),
            DataField(
                label: "VoIP allowed (network hint)",
                value: voip ? "Yes" : "No",
                api: "CTCarrier.allowsVOIP",
                availability: .oftenRestricted
            ),
            DataField(
                label: "Radio access technology (RAT)",
                value: ratLabel,
                api: "CTTelephonyNetworkInfo.serviceCurrentRadioAccessTechnology / currentRadioAccessTechnology",
                availability: .deviceOnly
            ),
            DataField(
                label: "Default cellular data line (this key)",
                value: isDataPreferred
                    ? "This subscription matches the cellular data line (iOS 16+), or only one line is active"
                    : "This subscription is not the cellular data line",
                api: "CTTelephonyNetworkInfo.dataServiceIdentifier (iOS 16+)",
                availability: .oftenRestricted
            )
        ]
        // Remove duplicate "label" in ratLabel line
        // swiftlint: fields already built

        return CellularSlotInfo(id: key, fields: fields, isDataPreferred: isDataPreferred)
    }

    private static func nonEmptyString(_ s: String?) -> String? {
        guard let t = s, !t.isEmpty else { return nil }
        return t
    }

    private static func mapRAT(_ value: String?) -> String? {
        guard let v = value else { return nil }
        if #available(iOS 14.1, *) {
            if v == CTRadioAccessTechnologyNRNSA { return "5G NSA" }
            if v == CTRadioAccessTechnologyNR { return "5G" }
        }
        switch v {
        case CTRadioAccessTechnologyGPRS: return "GPRS"
        case CTRadioAccessTechnologyEdge: return "Edge (2G)"
        case CTRadioAccessTechnologyWCDMA: return "WCDMA (3G)"
        case CTRadioAccessTechnologyHSDPA: return "HSDPA (3G)"
        case CTRadioAccessTechnologyHSUPA: return "HSUPA (3G)"
        case CTRadioAccessTechnologyCDMA1x: return "CDMA 1x"
        case CTRadioAccessTechnologyCDMAEVDORev0: return "EV-DO Rev.0"
        case CTRadioAccessTechnologyCDMAEVDORevA: return "EV-DO Rev.A"
        case CTRadioAccessTechnologyCDMAEVDORevB: return "EV-DO Rev.B"
        case CTRadioAccessTechnologyeHRPD: return "eHRPD"
        case CTRadioAccessTechnologyLTE: return "LTE (4G)"
        default: return nil
        }
    }

}
