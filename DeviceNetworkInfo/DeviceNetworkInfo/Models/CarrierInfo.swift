import Foundation

/// Represents carrier/SIM information for a single service subscription.
///
/// Starting with iOS 16, CTCarrier is deprecated and returns static placeholder values.
/// On iOS 16+, the only reliable source of carrier information is the
/// `CTTelephonyNetworkInfo.serviceSubscriberCellularProviders` dictionary,
/// but Apple has progressively restricted the data it returns.
struct CarrierInfo: Identifiable {
    let id = UUID()
    let serviceKey: String
    let carrierName: String?
    let mobileCountryCode: String?
    let mobileNetworkCode: String?
    let isoCountryCode: String?
    let allowsVOIP: Bool
}

/// Represents the overall SIM/eSIM configuration of the device.
struct SIMConfiguration {
    let type: SIMType
    let carrierCount: Int
    let carriers: [CarrierInfo]
    let dataServiceIdentifier: String?

    enum SIMType: String {
        case none = "No SIM Detected"
        case singleSIM = "Single SIM"
        case dualSIM = "Dual SIM"
        case eSIMOnly = "eSIM Only"
        case physicalPlusESIM = "Physical SIM + eSIM"
        case unknown = "Unknown Configuration"
    }
}
