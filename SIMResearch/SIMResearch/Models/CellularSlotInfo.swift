//
//  CellularSlotInfo.swift
//  One logical cellular “slot” (physical SIM and/or eSIM) as reported by CoreTelephony.
//  The map keys (e.g. CTTelephonyInfo.dataServiceProviderIDKey) are opaque; they do *not* expose
//  ICCID or a stable hardware identifier in public API.
//

import Foundation

struct CellularSlotInfo: Identifiable {
    let id: String
    let fields: [DataField]
    /// When true, matches `dataServiceIdentifier` on iOS 16+ when the system provides it, or a single line.
    var isDataPreferred: Bool
}

struct CellularSummary {
    let slotCount: Int
    let interpretation: String
    let systemWarning: String?
    let slots: [CellularSlotInfo]
    let serviceRadioTechnologies: [String: String]
}
