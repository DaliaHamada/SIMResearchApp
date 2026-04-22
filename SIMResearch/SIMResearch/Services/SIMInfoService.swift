//
//  SIMInfoService.swift
//  SIMResearch
//
//  Wraps `CTTelephonyNetworkInfo` and exposes a clean Swift API that
//  hides the deprecation warnings emitted by `CTCarrier` on iOS 16+.
//
//  IMPORTANT
//  ---------
//  * `CTCarrier` (and its `carrierName`, `mobileCountryCode`,
//    `mobileNetworkCode`, `isoCountryCode` properties) was deprecated
//    in iOS 16. Apple does not provide a replacement and the
//    deprecation messages are noisy at compile time. We isolate the
//    deprecated calls in a single `@available(iOS, deprecated: 16.0)`
//    shim (`readCarriers`) so that the rest of the codebase stays
//    warning free.
//  * `CTTelephonyNetworkInfo.serviceCurrentRadioAccessTechnology` is
//    not deprecated and is the preferred way to read the current RAT
//    on every supported iOS version.
//

import Foundation
import CoreTelephony

/// Reads cellular subscription / radio information.
final class SIMInfoService {

    /// CoreTelephony entry point. Held for the lifetime of the service
    /// so callers can subscribe to change notifications.
    private let networkInfo = CTTelephonyNetworkInfo()

    private var ratChangeObserver: NSObjectProtocol?

    /// Plain-Swift mirror of `CTCarrier` so the deprecated type does
    /// not leak into the rest of the codebase.
    private struct CarrierValues {
        let name: String?
        let mcc: String?
        let mnc: String?
        let iso: String?
        let allowsVOIP: Bool
    }

    // MARK: - Snapshot

    /// Returns the current `SIMSnapshot`.
    func currentSnapshot() -> SIMSnapshot {
        let radios = networkInfo.serviceCurrentRadioAccessTechnology ?? [:]
        let carriers = readCarriers()

        // Use `serviceSubscriberCellularProviders` keys as the canonical subscription
        // list when present. Union(carriers, radios) can report *two* keys on a single-SIM
        // phone because `serviceCurrentRadioAccessTechnology` sometimes retains an extra
        // service id with no matching provider row — that inflated "Dual SIM" in the UI.
        let subscriptionKeys: Set<String> = {
            if !carriers.isEmpty { return Set(carriers.keys) }
            return Set(radios.keys)
        }()

        var subs: [SIMSubscription] = []
        for key in subscriptionKeys.sorted() {
            let carrier = carriers[key]
            let rat = radios[key]
            subs.append(
                SIMSubscription(
                    id: key,
                    carrierName: carrier?.name,
                    mobileCountryCode: carrier?.mcc,
                    mobileNetworkCode: carrier?.mnc,
                    isoCountryCode: carrier?.iso,
                    allowsVOIP: carrier?.allowsVOIP ?? false,
                    radioAccessTechnology: rat,
                    radioAccessTechnologyDisplayName: Self.displayName(for: rat)
                )
            )
        }

        return SIMSnapshot(
            subscriptions: subs,
            dataServiceIdentifier: dataServiceIdentifier(),
            isLikelyESIMCapable: Self.isLikelyESIMCapable(serviceCount: subs.count)
        )
    }

    // MARK: - Notifications

    /// Subscribe for radio access technology / carrier updates.
    /// The handler is invoked on a CoreTelephony private queue – the
    /// caller is responsible for hopping to the main thread.
    func startObserving(_ handler: @escaping (SIMSnapshot) -> Void) {
        // `serviceSubscriberCellularProvidersDidUpdateNotifier` is deprecated in iOS 16 with
        // no replacement; still the practical hook for SIM / carrier changes.
        networkInfo.serviceSubscriberCellularProvidersDidUpdateNotifier = { [weak self] (_: String) in
            guard let self else { return }
            handler(self.currentSnapshot())
        }

        ratChangeObserver = NotificationCenter.default.addObserver(
            forName: .CTRadioAccessTechnologyDidChange,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            guard let self else { return }
            handler(self.currentSnapshot())
        }
    }

    func stopObserving() {
        networkInfo.serviceSubscriberCellularProvidersDidUpdateNotifier = nil
        if let token = ratChangeObserver {
            NotificationCenter.default.removeObserver(token)
            ratChangeObserver = nil
        }
    }

    // MARK: - Deprecated containment

    /// Reads `CTCarrier` values and adapts them to a non-deprecated
    /// Swift value type. The deprecation diagnostic is silenced for
    /// this single function so it cannot leak into the rest of the
    /// service.
    @available(iOS, deprecated: 16.0, message: "CTCarrier is deprecated; carrier metadata may be placeholders.")
    private func readCarriers() -> [String: CarrierValues] {
        guard let providers = networkInfo.serviceSubscriberCellularProviders else { return [:] }
        var out: [String: CarrierValues] = [:]
        for (key, carrier) in providers {
            out[key] = CarrierValues(
                name: carrier.carrierName,
                mcc: carrier.mobileCountryCode,
                mnc: carrier.mobileNetworkCode,
                iso: carrier.isoCountryCode,
                allowsVOIP: carrier.allowsVOIP
            )
        }
        return out
    }

    /// Returns the identifier of the "data" service, when CoreTelephony
    /// reports one. The property is available on iOS 13+.
    private func dataServiceIdentifier() -> String? {
        if #available(iOS 13.0, *) {
            return networkInfo.dataServiceIdentifier
        }
        return nil
    }

    /// Translates the raw `CTRadioAccessTechnology*` constants into a
    /// short, user friendly label.
    static func displayName(for rat: String?) -> String {
        guard let rat else { return "No service" }
        switch rat {
        case CTRadioAccessTechnologyGPRS:           return "2G (GPRS)"
        case CTRadioAccessTechnologyEdge:           return "2G (EDGE)"
        case CTRadioAccessTechnologyWCDMA:          return "3G (WCDMA)"
        case CTRadioAccessTechnologyHSDPA:          return "3G (HSDPA)"
        case CTRadioAccessTechnologyHSUPA:          return "3G (HSUPA)"
        case CTRadioAccessTechnologyCDMA1x:         return "2G (CDMA 1x)"
        case CTRadioAccessTechnologyCDMAEVDORev0:   return "3G (EV-DO Rev. 0)"
        case CTRadioAccessTechnologyCDMAEVDORevA:   return "3G (EV-DO Rev. A)"
        case CTRadioAccessTechnologyCDMAEVDORevB:   return "3G (EV-DO Rev. B)"
        case CTRadioAccessTechnologyeHRPD:          return "3G (eHRPD)"
        case CTRadioAccessTechnologyLTE:            return "4G (LTE)"
        default: break
        }
        if #available(iOS 14.1, *) {
            switch rat {
            case CTRadioAccessTechnologyNRNSA: return "5G (NSA)"
            case CTRadioAccessTechnologyNR:    return "5G (NR)"
            default: break
            }
        }
        return rat
    }

    /// Heuristic that flags devices reasonably expected to support eSIM.
    /// Apple does not expose a public capability flag, so we infer the
    /// answer from the number of services CoreTelephony reports plus
    /// the device family. The result is best-effort only.
    private static func isLikelyESIMCapable(serviceCount: Int) -> Bool {
        if serviceCount > 1 { return true }
        var sysinfo = utsname()
        uname(&sysinfo)
        let mirror = Mirror(reflecting: sysinfo.machine)
        let identifier = mirror.children.reduce(into: "") { partial, element in
            guard let value = element.value as? Int8, value != 0 else { return }
            partial.append(String(UnicodeScalar(UInt8(value))))
        }
        // Every iPhone XS / XR or newer ships with eSIM support.
        // A very lightweight heuristic: any iPhone identifier with a
        // major number >= 11.
        guard identifier.hasPrefix("iPhone"),
              let comma = identifier.firstIndex(of: ","),
              let major = Int(identifier[identifier.index(identifier.startIndex, offsetBy: 6)..<comma])
        else {
            return false
        }
        return major >= 11
    }
}
