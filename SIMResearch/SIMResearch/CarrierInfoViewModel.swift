//
//  CarrierInfoViewModel.swift
//  SIMResearch
//
//  Created by Dalia Hamada on 16/10/2025.
//

import Foundation
import CoreTelephony
import Combine

class CarrierInfoViewModel: ObservableObject {
    @Published var carriers: [CarrierDetail] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var lastUpdated: Date = Date()
    
    private let networkInfo = CTTelephonyNetworkInfo()
    
    init() {
        fetchCarrierInfo()
    }
    
    func fetchCarrierInfo() {
        isLoading = true
        errorMessage = nil
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            
            var fetchedCarriers: [CarrierDetail] = []
            
            if #available(iOS 12.0, *) {
                if let providers = self.networkInfo.serviceSubscriberCellularProviders {
                    if providers.isEmpty {
                        self.errorMessage = "No SIM cards detected. Please test on a device with active SIM."
                    } else {
                        for (key, carrier) in providers {
                            let detail = CarrierDetail(
                                id: key,
                                carrierName: carrier.carrierName ?? "Unknown",
                                countryCode: carrier.isoCountryCode ?? "Unknown",
                                mobileNetworkCode: carrier.mobileNetworkCode ?? "Unknown",
                                mobileCountryCode: carrier.mobileCountryCode ?? "Unknown",
                                allowsVOIP: carrier.allowsVOIP
                            )
                            fetchedCarriers.append(detail)
                        }
                    }
                } else {
                    self.errorMessage = "Unable to access carrier information."
                }
            } else {
                // iOS 11 and below - single SIM only
                if let carrier = self.networkInfo.subscriberCellularProvider {
                    let detail = CarrierDetail(
                        id: "primary",
                        carrierName: carrier.carrierName ?? "Unknown",
                        countryCode: carrier.isoCountryCode ?? "Unknown",
                        mobileNetworkCode: carrier.mobileNetworkCode ?? "Unknown",
                        mobileCountryCode: carrier.mobileCountryCode ?? "Unknown",
                        allowsVOIP: carrier.allowsVOIP
                    )
                    fetchedCarriers.append(detail)
                } else {
                    self.errorMessage = "No carrier information available"
                }
            }
            
            self.carriers = fetchedCarriers
            self.lastUpdated = Date()
            self.isLoading = false
        }
    }
    
    var carrierCount: Int {
        carriers.count
    }
    
    var hasMultipleSIMs: Bool {
        carriers.count > 1
    }
}
