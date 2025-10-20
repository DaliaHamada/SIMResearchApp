//
//  CarrierDetail.swift
//  SIMResearch
//
//  Created by Dalia Hamada on 16/10/2025.
//

import Foundation

struct CarrierDetail: Identifiable, Equatable {
    let id: String
    let carrierName: String?
    let countryCode: String?
    let mobileNetworkCode: String?
    let mobileCountryCode: String?
    let allowsVOIP: Bool
    let isDeprecated: Bool
    
    var displayName: String {
        if isDeprecated {
            return "Carrier Info Unavailable (iOS 16+)"
        }
        guard let name = carrierName, !name.isEmpty else {
            return "No Carrier Detected"
        }
        return name
    }
    
    var fullCountryName: String {
        guard let code = countryCode, !code.isEmpty else {
            return "Unknown"
        }
        return Locale.current.localizedString(forRegionCode: code.uppercased()) ?? code
    }
    
    var statusDescription: String {
        if isDeprecated {
            return "CTCarrier deprecated in iOS 16 with no replacement"
        } else if carrierName == nil {
            return "No active SIM detected"
        }
        return "Active"
    }
}
