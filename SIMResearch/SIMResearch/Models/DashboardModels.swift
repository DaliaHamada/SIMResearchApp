import Foundation

struct InfoItem: Identifiable, Hashable {
    let id: String
    let name: String
    let value: String
    let detail: String?

    init(name: String, value: String, detail: String? = nil) {
        self.id = name
        self.name = name
        self.value = value
        self.detail = detail
    }
}

struct DeviceInfoSnapshot {
    let summary: String
    let items: [InfoItem]
    let notes: [String]

    static let placeholder = DeviceInfoSnapshot(
        summary: "Collecting device information...",
        items: [],
        notes: []
    )
}

struct CarrierSubscriptionInfo: Identifiable, Hashable {
    let id: String
    let serviceIdentifier: String
    let carrierName: String
    let mobileCountryCode: String
    let mobileNetworkCode: String
    let isoCountryCode: String
    let radioAccessTechnology: String
    let allowsVoIP: String
    let isCurrentDataService: Bool
}

struct TelephonyInfoSnapshot {
    let summary: String
    let items: [InfoItem]
    let subscriptions: [CarrierSubscriptionInfo]
    let notes: [String]

    static let placeholder = TelephonyInfoSnapshot(
        summary: "Collecting SIM and carrier information...",
        items: [],
        subscriptions: [],
        notes: []
    )
}

struct NetworkInfoSnapshot {
    let summary: String
    let items: [InfoItem]
    let notes: [String]

    static let placeholder = NetworkInfoSnapshot(
        summary: "Monitoring network path...",
        items: [],
        notes: []
    )
}
