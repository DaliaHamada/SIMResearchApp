import Foundation

struct DeviceNetworkSnapshot {
    let capturedAt: Date
    let deviceInfo: [InfoField]
    let simSummary: SimSummary
    let carrierInfo: [CarrierSnapshot]
    let networkInfo: [InfoField]
    let notes: [String]
}

struct SimSummary {
    let description: String
    let activeSubscriptionsCount: Int
    let availability: DataAvailability
    let details: String
}

struct CarrierSnapshot: Identifiable {
    let id: String
    let serviceIdentifier: String
    let fields: [InfoField]
}
