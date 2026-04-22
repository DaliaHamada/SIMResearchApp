import Foundation

/// ViewModel that bridges CarrierInfoService data to SwiftUI views.
@MainActor
final class CarrierInfoViewModel: ObservableObject {

    @Published var configurationRows: [InfoRow] = []
    @Published var carrierSections: [[InfoRow]] = []
    @Published var limitationRows: [InfoRow] = []

    private let service = CarrierInfoService()

    func refresh() {
        let config = service.collectSIMConfiguration()

        configurationRows = [
            InfoRow(label: "SIM Configuration", value: config.type.rawValue),
            InfoRow(label: "Active Subscriptions", value: "\(config.carrierCount)"),
            InfoRow(label: "Data Service ID", value: config.dataServiceIdentifier ?? "N/A",
                    detail: "Identifies which service handles cellular data")
        ]

        carrierSections = config.carriers.map { carrier in
            [
                InfoRow(label: "Service Key", value: carrier.serviceKey),
                InfoRow(label: "Carrier Name", value: carrier.carrierName ?? "Unknown",
                        detail: "Deprecated on iOS 16+; may return placeholder"),
                InfoRow(label: "MCC", value: carrier.mobileCountryCode ?? "N/A",
                        detail: "Mobile Country Code (e.g., 310 = USA)"),
                InfoRow(label: "MNC", value: carrier.mobileNetworkCode ?? "N/A",
                        detail: "Mobile Network Code (e.g., 410 = AT&T)"),
                InfoRow(label: "ISO Country Code", value: carrier.isoCountryCode ?? "N/A"),
                InfoRow(label: "Allows VoIP", value: carrier.allowsVOIP ? "Yes" : "No")
            ]
        }

        limitationRows = [
            InfoRow(label: "Phone Number", value: "Not Accessible",
                    detail: "Apple restricts access since iOS 4 for privacy"),
            InfoRow(label: "IMSI", value: "Not Accessible",
                    detail: "No public API; requires carrier-level access"),
            InfoRow(label: "ICCID", value: "Not Accessible",
                    detail: "SIM serial number; no public API"),
            InfoRow(label: "IMEI", value: "Not Accessible",
                    detail: "Device identity; no public API since iOS 5"),
            InfoRow(label: "SIM Slot Type", value: "Not Distinguishable",
                    detail: "No API to determine if a service uses physical SIM vs eSIM")
        ]
    }
}
