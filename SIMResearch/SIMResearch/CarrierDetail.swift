//
//  CarrierDetail.swift
//  SIMResearch
//
//  Created by Dalia Hamada on 16/10/2025.
//

import Foundation

struct CarrierDetail: Identifiable, Equatable {
    let id: String
    let carrierName: String
    let countryCode: String
    let mobileNetworkCode: String
    let mobileCountryCode: String
    let allowsVOIP: Bool
    
    var displayName: String {
        carrierName.isEmpty || carrierName == "Unknown" ? "No Carrier" : carrierName
    }
    
    var fullCountryName: String {
        let locale = Locale.current
        return locale.localizedString(forRegionCode: countryCode.uppercased()) ?? countryCode
    }
}
