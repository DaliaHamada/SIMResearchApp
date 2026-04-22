import CoreTelephony

/// Service responsible for collecting carrier and SIM information.
///
/// APIs used:
/// - `CTTelephonyNetworkInfo` — central class for telephony data.
/// - `CTCarrier` — carrier name, MCC, MNC, ISO country code, VoIP support.
///
/// Important deprecation notice:
/// - `CTCarrier` was deprecated in iOS 16.0.
/// - On iOS 16+, carrier property accessors return static placeholder values
///   ("--" for strings, "65535" for codes).
/// - Apple has not provided a direct replacement API for carrier metadata.
/// - The `serviceSubscriberCellularProviders` dictionary still returns CTCarrier
///   objects keyed by service identifier, but the values are unreliable on iOS 16+.
///
/// SIM Detection:
/// - The number of entries in `serviceSubscriberCellularProviders` indicates
///   how many active SIM/eSIM subscriptions exist.
/// - There is NO public API to distinguish between physical SIM and eSIM.
///   We infer the configuration from the number of active services.
///
/// Data that CANNOT be retrieved:
/// - Phone number (not accessible since iOS 4+)
/// - IMSI (International Mobile Subscriber Identity)
/// - ICCID (SIM card serial number)
/// - IMEI (International Mobile Equipment Identity)
/// - SIM slot type (physical vs eSIM) — no public API to distinguish
final class CarrierInfoService {

    private let networkInfo = CTTelephonyNetworkInfo()

    func collectSIMConfiguration() -> SIMConfiguration {
        let providers = networkInfo.serviceSubscriberCellularProviders ?? [:]
        let dataServiceId = networkInfo.dataServiceIdentifier

        var carriers: [CarrierInfo] = []

        for (key, carrier) in providers {
            let info = CarrierInfo(
                serviceKey: key,
                carrierName: carrier.carrierName,
                mobileCountryCode: carrier.mobileCountryCode,
                mobileNetworkCode: carrier.mobileNetworkCode,
                isoCountryCode: carrier.isoCountryCode,
                allowsVOIP: carrier.allowsVOIP
            )
            carriers.append(info)
        }

        carriers.sort { $0.serviceKey < $1.serviceKey }

        let simType = determineSIMType(carrierCount: carriers.count)

        return SIMConfiguration(
            type: simType,
            carrierCount: carriers.count,
            carriers: carriers,
            dataServiceIdentifier: dataServiceId
        )
    }

    /// Infers the SIM configuration type from the number of active carrier services.
    /// Note: There is no public API to differentiate physical SIM from eSIM.
    private func determineSIMType(carrierCount: Int) -> SIMConfiguration.SIMType {
        switch carrierCount {
        case 0:
            return .none
        case 1:
            return .singleSIM
        case 2:
            return .dualSIM
        default:
            return .unknown
        }
    }
}
