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
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        fetchCarrierInfo()
        setupCarrierChangeNotification()
    }
    
    private func setupCarrierChangeNotification() {
        // Note: This only works while app is running (foreground/background)
        networkInfo.subscriberCellularProviderDidUpdateNotifier = { [weak self] carrier in
            DispatchQueue.main.async {
                print("Carrier change detected (while app is running)")
                self?.fetchCarrierInfo()
            }
        }
    }
    
    func fetchCarrierInfo() {
        isLoading = true
        errorMessage = nil
        
        // Simulate slight delay for better UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }
            
            var fetchedCarriers: [CarrierDetail] = []
            let isIOS16OrLater = self.isIOS16OrLater()
            
            if #available(iOS 12.0, *) {
                // Multi-SIM support (iOS 12+)
                if let providers = self.networkInfo.serviceSubscriberCellularProviders {
                    if providers.isEmpty {
                        self.errorMessage = "No active cellular service detected.\n\nPlease ensure:\n• Device has an active SIM card\n• Cellular service is enabled\n• Running on a physical device (not simulator)"
                    } else {
                        for (key, carrier) in providers {
                            let detail = self.createCarrierDetail(
                                id: key,
                                carrier: carrier,
                                isDeprecated: isIOS16OrLater
                            )
                            fetchedCarriers.append(detail)
                        }
                    }
                } else {
                    self.errorMessage = "Unable to access carrier information.\n\nThis may be due to:\n• Running on iOS Simulator\n• No SIM card installed\n• Restricted access to Core Telephony"
                }
            } else {
                // Single SIM support (iOS 11 and below)
                if let carrier = self.networkInfo.subscriberCellularProvider {
                    let detail = self.createCarrierDetail(
                        id: "primary",
                        carrier: carrier,
                        isDeprecated: false
                    )
                    fetchedCarriers.append(detail)
                } else {
                    self.errorMessage = "No carrier information available"
                }
            }
            
            self.carriers = fetchedCarriers.sorted { $0.id < $1.id }
            self.lastUpdated = Date()
            self.isLoading = false
        }
    }
    
    private func createCarrierDetail(id: String, carrier: CTCarrier, isDeprecated: Bool) -> CarrierDetail {
        return CarrierDetail(
            id: id,
            carrierName: carrier.carrierName,
            countryCode: carrier.isoCountryCode,
            mobileNetworkCode: carrier.mobileNetworkCode,
            mobileCountryCode: carrier.mobileCountryCode,
            allowsVOIP: carrier.allowsVOIP,
            isDeprecated: isDeprecated
        )
    }
    
    private func isIOS16OrLater() -> Bool {
        if #available(iOS 16.0, *) {
            return true
        }
        return false
    }
    
    var carrierCount: Int {
        carriers.count
    }
    
    var deviceDescription: String {
        switch carriers.count {
        case 0:
            return "No SIM detected"
        case 1:
            return "Single SIM"
        case 2:
            return "Dual SIM (Physical + eSIM or Dual eSIM)"
        default:
            return "\(carriers.count) cellular slots detected"
        }
    }
}
