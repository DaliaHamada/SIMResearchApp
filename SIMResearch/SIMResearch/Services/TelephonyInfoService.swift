import CoreTelephony
import Foundation

struct TelephonyInfoService {
    func snapshot() -> TelephonyInfoSnapshot {
        let networkInfo = CTTelephonyNetworkInfo()
        let cellularData = CTCellularData()
        let subscriptions = makeSubscriptions(from: networkInfo)
        let subscriptionCount = subscriptions.count

        let items = [
            InfoItem(
                name: "SIM status",
                value: simStatusDescription(for: subscriptionCount),
                detail: "This is a best-effort summary based on active services exposed by CoreTelephony. Public APIs do not reveal whether a plan is on a physical SIM or eSIM."
            ),
            InfoItem(name: "Active subscription count", value: "\(subscriptionCount)"),
            InfoItem(
                name: "Current data service identifier",
                value: networkInfo.dataServiceIdentifier ?? "Unavailable",
                detail: "Matches the service currently providing mobile data when iOS exposes one."
            ),
            InfoItem(
                name: "Cellular data restriction",
                value: restrictedStateDescription(cellularData.restrictedState),
                detail: "Reports whether this app can use cellular data. It does not indicate signal quality."
            ),
            InfoItem(
                name: "eSIM / physical SIM type",
                value: "Not exposed",
                detail: "Public iOS APIs do not identify whether an active subscription comes from a removable SIM or an eSIM profile."
            )
        ]

        let summary: String
        switch subscriptionCount {
        case 0:
            summary = "No active cellular services were exposed by CoreTelephony."
        case 1:
            summary = "One active cellular service is currently exposed."
        default:
            summary = "\(subscriptionCount) active cellular services are currently exposed."
        }

        let notes = [
            "Carrier details shown here come from CoreTelephony. On iOS 16 and later, CTCarrier is deprecated with no replacement and may return blank or placeholder values.",
            "This demo does not attempt to read phone number, IMSI, ICCID, or inactive eSIM profiles because public iOS APIs do not provide that information to normal apps.",
            "A device with one exposed service could be using either a physical SIM or an eSIM. iOS does not let ordinary apps distinguish between them."
        ]

        return TelephonyInfoSnapshot(
            summary: summary,
            items: items,
            subscriptions: subscriptions,
            notes: notes
        )
    }

    private func makeSubscriptions(from networkInfo: CTTelephonyNetworkInfo) -> [CarrierSubscriptionInfo] {
        let providers = networkInfo.serviceSubscriberCellularProviders ?? [:]
        let radioTechnologies = networkInfo.serviceCurrentRadioAccessTechnology ?? [:]
        let currentDataServiceIdentifier = networkInfo.dataServiceIdentifier

        return providers.keys.sorted().map { serviceIdentifier in
            let carrier = providers[serviceIdentifier]

            return CarrierSubscriptionInfo(
                id: serviceIdentifier,
                serviceIdentifier: serviceIdentifier,
                carrierName: sanitizedCarrierValue(carrier?.carrierName),
                mobileCountryCode: sanitizedCarrierValue(carrier?.mobileCountryCode),
                mobileNetworkCode: sanitizedCarrierValue(carrier?.mobileNetworkCode),
                isoCountryCode: sanitizedCarrierValue(carrier?.isoCountryCode?.uppercased()),
                radioAccessTechnology: radioAccessTechnologyDescription(radioTechnologies[serviceIdentifier]),
                allowsVoIP: booleanDescription(carrier?.allowsVOIP == true),
                isCurrentDataService: serviceIdentifier == currentDataServiceIdentifier
            )
        }
    }

    private func simStatusDescription(for subscriptionCount: Int) -> String {
        switch subscriptionCount {
        case 0:
            return "No active subscription exposed"
        case 1:
            return "Single active subscription exposed"
        case 2:
            return "Two active subscriptions exposed (dual active)"
        default:
            return "\(subscriptionCount) active subscriptions exposed"
        }
    }

    private func sanitizedCarrierValue(_ value: String?) -> String {
        guard let value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return "Unavailable"
        }

        if value == "--" || value == "65535" {
            return "Restricted or placeholder value"
        }

        return value
    }

    private func booleanDescription(_ value: Bool) -> String {
        value ? "Yes" : "No"
    }

    private func restrictedStateDescription(_ state: CTCellularDataRestrictedState) -> String {
        switch state {
        case .restricted:
            return "Restricted"
        case .notRestricted:
            return "Not restricted"
        case .restrictedStateUnknown:
            return "Unknown"
        @unknown default:
            return "Unknown future state"
        }
    }

    private func radioAccessTechnologyDescription(_ technology: String?) -> String {
        guard let technology else {
            return "Unavailable"
        }

        switch technology {
        case CTRadioAccessTechnologyGPRS:
            return "GPRS (2G)"
        case CTRadioAccessTechnologyEdge:
            return "EDGE (2G)"
        case CTRadioAccessTechnologyWCDMA:
            return "WCDMA (3G)"
        case CTRadioAccessTechnologyHSDPA:
            return "HSDPA (3G)"
        case CTRadioAccessTechnologyHSUPA:
            return "HSUPA (3G)"
        case CTRadioAccessTechnologyCDMA1x:
            return "CDMA1x (2G)"
        case CTRadioAccessTechnologyCDMAEVDORev0:
            return "EV-DO Rev. 0 (3G)"
        case CTRadioAccessTechnologyCDMAEVDORevA:
            return "EV-DO Rev. A (3G)"
        case CTRadioAccessTechnologyCDMAEVDORevB:
            return "EV-DO Rev. B (3G)"
        case CTRadioAccessTechnologyeHRPD:
            return "eHRPD"
        case CTRadioAccessTechnologyLTE:
            return "LTE (4G)"
        case CTRadioAccessTechnologyNRNSA:
            return "5G NSA"
        case CTRadioAccessTechnologyNR:
            return "5G SA"
        default:
            return technology
        }
    }
}
