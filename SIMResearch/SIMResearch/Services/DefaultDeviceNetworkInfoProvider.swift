import CoreTelephony
import Foundation
import Network
import UIKit

final class DefaultDeviceNetworkInfoProvider: DeviceNetworkInfoProviding {
    private let telephonyInfo = CTTelephonyNetworkInfo()
    private let monitorQueue = DispatchQueue(label: "simresearch.network.monitor")

    func fetchSnapshot() async -> DeviceNetworkSnapshot {
        let deviceInfo = fetchDeviceInfoFields()
        let networkInfo = await fetchNetworkInfoFields()
        let simResult = fetchCarrierAndSimInfo()

        return DeviceNetworkSnapshot(
            capturedAt: Date(),
            deviceInfo: deviceInfo,
            simSummary: simResult.simSummary,
            carrierInfo: simResult.carriers,
            networkInfo: networkInfo,
            notes: buildGeneralNotes()
        )
    }

    private func fetchDeviceInfoFields() -> [InfoField] {
        let device = UIDevice.current
        return [
            InfoField(
                title: "Device Name",
                value: nonEmpty(device.name),
                apiName: "UIDevice.current.name",
                availability: .available,
                note: "May be generic if user does not rename device."
            ),
            InfoField(
                title: "System Name",
                value: nonEmpty(device.systemName),
                apiName: "UIDevice.current.systemName",
                availability: .available,
                note: nil
            ),
            InfoField(
                title: "System Version",
                value: nonEmpty(device.systemVersion),
                apiName: "UIDevice.current.systemVersion",
                availability: .available,
                note: nil
            ),
            InfoField(
                title: "Device Model",
                value: nonEmpty(device.model),
                apiName: "UIDevice.current.model",
                availability: .available,
                note: "High-level value such as iPhone or iPad."
            ),
            InfoField(
                title: "Localized Model",
                value: nonEmpty(device.localizedModel),
                apiName: "UIDevice.current.localizedModel",
                availability: .available,
                note: nil
            ),
            InfoField(
                title: "Vendor Identifier",
                value: device.identifierForVendor?.uuidString ?? unavailableText,
                apiName: "UIDevice.current.identifierForVendor",
                availability: device.identifierForVendor == nil ? .limited : .available,
                note: "Scoped to this vendor; can reset after reinstalling all apps from the same vendor."
            )
        ]
    }

    private func fetchCarrierAndSimInfo() -> (simSummary: SimSummary, carriers: [CarrierSnapshot]) {
        if #available(iOS 16.0, *) {
            return (
                simSummary: SimSummary(
                    description: "SIM/carrier details are restricted on iOS 16+",
                    activeSubscriptionsCount: 0,
                    availability: .unavailable,
                    details: "CoreTelephony carrier APIs were deprecated with no replacement in iOS 16."
                ),
                carriers: []
            )
        }

        if #available(iOS 12.0, *) {
            // This API returns ACTIVE subscriptions only. It does not reveal
            // whether a plan is physical SIM vs eSIM, and it cannot list inactive eSIM profiles.
            let providers = telephonyInfo.serviceSubscriberCellularProviders ?? [:]
            let carriers = providers.map { key, carrier in
                CarrierSnapshot(
                    id: key,
                    serviceIdentifier: key,
                    fields: carrierFields(from: carrier)
                )
            }.sorted { $0.serviceIdentifier < $1.serviceIdentifier }

            return (
                simSummary: buildSimSummary(activeSubscriptionsCount: carriers.count),
                carriers: carriers
            )
        }

        guard let carrier = telephonyInfo.subscriberCellularProvider else {
            return (
                simSummary: SimSummary(
                    description: "No active cellular plan detected",
                    activeSubscriptionsCount: 0,
                    availability: .limited,
                    details: "No subscriber carrier information available."
                ),
                carriers: []
            )
        }

        let legacyCarrier = CarrierSnapshot(
            id: "legacy-primary",
            serviceIdentifier: "legacy-primary",
            fields: carrierFields(from: carrier)
        )
        return (
            simSummary: buildSimSummary(activeSubscriptionsCount: 1),
            carriers: [legacyCarrier]
        )
    }

    private func buildSimSummary(activeSubscriptionsCount: Int) -> SimSummary {
        let description: String
        switch activeSubscriptionsCount {
        case 0:
            description = "No active SIM/eSIM plan detected"
        case 1:
            description = "Single active cellular plan detected"
        default:
            description = "Multiple active cellular plans detected"
        }

        return SimSummary(
            description: description,
            activeSubscriptionsCount: activeSubscriptionsCount,
            availability: .limited,
            details: "iOS does not expose definitive physical SIM vs eSIM type through public APIs; this is inferred from active subscriptions only."
        )
    }

    @available(iOS, introduced: 4.0, obsoleted: 16.0)
    private func carrierFields(from carrier: CTCarrier) -> [InfoField] {
        [
            InfoField(
                title: "Carrier Name",
                value: nonEmpty(carrier.carrierName),
                apiName: "CTCarrier.carrierName",
                availability: fieldAvailability(for: carrier.carrierName),
                note: "Deprecated in iOS 16 with no replacement; can be nil on recent iOS."
            ),
            InfoField(
                title: "Mobile Country Code (MCC)",
                value: nonEmpty(carrier.mobileCountryCode),
                apiName: "CTCarrier.mobileCountryCode",
                availability: fieldAvailability(for: carrier.mobileCountryCode),
                note: "Deprecated in iOS 16 with no replacement; can be nil."
            ),
            InfoField(
                title: "Mobile Network Code (MNC)",
                value: nonEmpty(carrier.mobileNetworkCode),
                apiName: "CTCarrier.mobileNetworkCode",
                availability: fieldAvailability(for: carrier.mobileNetworkCode),
                note: "Deprecated in iOS 16 with no replacement; can be nil."
            ),
            InfoField(
                title: "ISO Country Code",
                value: nonEmpty(carrier.isoCountryCode),
                apiName: "CTCarrier.isoCountryCode",
                availability: fieldAvailability(for: carrier.isoCountryCode),
                note: "Deprecated in iOS 16 with no replacement; can be nil."
            ),
            InfoField(
                title: "VoIP Supported",
                value: carrier.allowsVOIP ? "Yes" : "No",
                apiName: "CTCarrier.allowsVOIP",
                availability: .limited,
                note: "Deprecated in iOS 16 with no replacement."
            )
        ]
    }

    private func fetchNetworkInfoFields() async -> [InfoField] {
        var fields: [InfoField] = []

        if #available(iOS 16.0, *) {
            fields.append(
                InfoField(
                    title: "Radio Access Technology",
                    value: unavailableText,
                    apiName: "CTTelephonyNetworkInfo.serviceCurrentRadioAccessTechnology",
                    availability: .unavailable,
                    note: "Deprecated in iOS 16 with no replacement."
                )
            )
        } else if #available(iOS 12.0, *) {
            let radioTechnologies = telephonyInfo.serviceCurrentRadioAccessTechnology ?? [:]
            if radioTechnologies.isEmpty {
                fields.append(
                    InfoField(
                        title: "Radio Access Technology",
                        value: unavailableText,
                        apiName: "CTTelephonyNetworkInfo.serviceCurrentRadioAccessTechnology",
                        availability: .limited,
                        note: "Can be nil on simulator, Wi-Fi only mode, or when unavailable by policy."
                    )
                )
            } else {
                let joined = radioTechnologies
                    .sorted { $0.key < $1.key }
                    .map { "\($0.key): \($0.value)" }
                    .joined(separator: ", ")

                fields.append(
                    InfoField(
                        title: "Radio Access Technology",
                        value: joined,
                        apiName: "CTTelephonyNetworkInfo.serviceCurrentRadioAccessTechnology",
                        availability: .limited,
                        note: "Maps to values such as CTRadioAccessTechnologyLTE or CTRadioAccessTechnologyNR."
                    )
                )
            }
        } else {
            fields.append(
                InfoField(
                    title: "Radio Access Technology",
                    value: telephonyInfo.currentRadioAccessTechnology ?? unavailableText,
                    apiName: "CTTelephonyNetworkInfo.currentRadioAccessTechnology",
                    availability: telephonyInfo.currentRadioAccessTechnology == nil ? .limited : .available,
                    note: "Legacy single-SIM API."
                )
            )
        }

        let pathSnapshot = await captureCurrentPath()
        fields.append(
            InfoField(
                title: "Current Path Status",
                value: pathSnapshot.statusText,
                apiName: "NWPathMonitor.currentPath.status",
                availability: .available,
                note: nil
            )
        )
        fields.append(
            InfoField(
                title: "Uses Cellular",
                value: pathSnapshot.usesCellular ? "Yes" : "No",
                apiName: "NWPath.usesInterfaceType(.cellular)",
                availability: .available,
                note: nil
            )
        )
        fields.append(
            InfoField(
                title: "Uses Wi-Fi",
                value: pathSnapshot.usesWiFi ? "Yes" : "No",
                apiName: "NWPath.usesInterfaceType(.wifi)",
                availability: .available,
                note: nil
            )
        )
        fields.append(
            InfoField(
                title: "Is Expensive",
                value: pathSnapshot.isExpensive ? "Yes" : "No",
                apiName: "NWPath.isExpensive",
                availability: .available,
                note: "Typically true for cellular or personal hotspot."
            )
        )
        fields.append(
            InfoField(
                title: "Is Constrained",
                value: pathSnapshot.isConstrained ? "Yes" : "No",
                apiName: "NWPath.isConstrained",
                availability: .available,
                note: "Low Data Mode or constrained networking policy."
            )
        )

        return fields
    }

    private func captureCurrentPath() async -> PathSnapshot {
        await withCheckedContinuation { continuation in
            let monitor = NWPathMonitor()
            var resumed = false

            monitor.pathUpdateHandler = { path in
                guard !resumed else { return }
                resumed = true
                continuation.resume(
                    returning: PathSnapshot(
                        statusText: path.status.debugText,
                        usesCellular: path.usesInterfaceType(.cellular),
                        usesWiFi: path.usesInterfaceType(.wifi),
                        isExpensive: path.isExpensive,
                        isConstrained: path.isConstrained
                    )
                )
                monitor.cancel()
            }

            monitor.start(queue: monitorQueue)
        }
    }

    private func buildGeneralNotes() -> [String] {
        [
            // iOS privacy model intentionally blocks sensitive subscriber data from apps.
            "Phone number, IMSI, ICCID, SMS content, and incoming SMS SIM route are not exposed to regular iOS apps.",
            "Carrier properties (CTCarrier) are deprecated starting iOS 16 and may be empty.",
            "SIM type (physical SIM vs eSIM) and inactive eSIM profiles are not publicly queryable."
        ]
    }

    private func nonEmpty(_ value: String?) -> String {
        guard let value, !value.isEmpty else {
            return unavailableText
        }
        return value
    }

    private func fieldAvailability(for value: String?) -> DataAvailability {
        guard let value, !value.isEmpty else {
            return .limited
        }
        return .available
    }

    private var unavailableText: String {
        "Not available"
    }
}

private struct PathSnapshot {
    let statusText: String
    let usesCellular: Bool
    let usesWiFi: Bool
    let isExpensive: Bool
    let isConstrained: Bool
}

private extension NWPath.Status {
    var debugText: String {
        switch self {
        case .satisfied:
            return "Satisfied"
        case .requiresConnection:
            return "Requires Connection"
        case .unsatisfied:
            return "Unsatisfied"
        @unknown default:
            return "Unknown"
        }
    }
}
