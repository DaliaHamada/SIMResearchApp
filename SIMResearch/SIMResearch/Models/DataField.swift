//
//  DataField.swift
//  SIMResearch
//
//  A single displayable data point: label, value, and human-readable availability notes.
//

import Foundation

/// How reliably this value appears on a typical user device (see README limitations).
enum DataAvailability: String {
    case generallyAvailable
    case deviceOnly /// Simulator or certain environments may omit data.
    case oftenRestricted /// Apple or carriers may return empty strings, especially on newer iOS.
    case userControllable /// Depends on user settings (e.g., Low Data Mode)

    var displayName: String {
        switch self {
        case .generallyAvailable: return "Usually"
        case .deviceOnly: return "Device / real SIM"
        case .oftenRestricted: return "Often blank / iOS 16+"
        case .userControllable: return "User / policy"
        }
    }
}

struct DataField: Identifiable {
    let id = UUID()
    let label: String
    let value: String
    let api: String
    let availability: DataAvailability
    let note: String?

    init(
        label: String,
        value: String,
        api: String,
        availability: DataAvailability,
        note: String? = nil
    ) {
        self.label = label
        self.value = value
        self.api = api
        self.availability = availability
        self.note = note
    }
}
