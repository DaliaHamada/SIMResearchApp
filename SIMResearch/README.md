# SIMResearch — Device and network information demo (iOS)

## Overview

**SIMResearch** is a small SwiftUI demonstration app for **real iPhones** (physical SIM, eSIM, or dual-SIM) that shows **as much public API data** as iOS will expose about the device, cellular subscription metadata, and the current local network path.

### Key features

- **Device:** marketing model, hardware id string, OS version, IDFV, screen metrics, battery snapshot.
- **SIM & carrier (Core Telephony):** one row per *active* cellular line reported by the system, including carrier name, MCC/MNC, ISO country, VoIP hint, radio access technology, and (on iOS 16+) which subscription matches the **cellular data** line.
- **Network (Network framework):** path status, cellular/expensive/constrained flags, on-path interface list, and system HTTP proxy summary (no Wi-Fi SSID without extra entitlements).

The UI is a single scrollable **dashboard** with three clear sections. Pull to refresh is available via the toolbar; cellular data is also re-fetched when `subscriberCellularProviderDidUpdateNotifier` fires (while the app is running).

---

## Data points

Each item below is shown in the app (or explained when empty). *Example* values are illustrative; **your** device may return blanks where Apple or the carrier redacts data.

| Data (label in app) | Example value | API / framework | Availability / restriction |
| ------------------- | ------------- | ----------------- | --------------------------- |
| User-set device name | `Alex’s iPhone` | [UIDevice.name](https://developer.apple.com/documentation/uidevice/1620054-name) | **Usually** present; user can change it. |
| Marketing / generic model | `iPhone` — `iPhone` | [UIDevice.model](https://developer.apple.com/documentation/uidevice/1622007-model), [localizedModel](https://developer.apple.com/documentation/uidevice/1620024-localizedmodel) | **Usually** present. |
| Hardware model id | `iPhone15,2` | [uname(2) / `utsname.machine`](https://man.freebsd.org/cgi/man.cgi?query=uname&sektion=2) (Darwin) | **Device** (Simulator differs). |
| System version | `iOS 18.2` | [UIDevice.systemName](https://developer.apple.com/documentation/uidevice/1620043-systemname), [systemVersion](https://developer.apple.com/documentation/uidevice/1620040-systemversion) | **Usually** present. |
| IDFV (identifier for vendor) | `6D79E0E0-...` | [UIDevice.identifierForVendor](https://developer.apple.com/documentation/uidevice/1620059-identifierforvendor) | **Usually** present; not stable across *all* vendor app removals. Not UDID. |
| User interface idiom | `iPhone` | [UIDevice.userInterfaceIdiom](https://developer.apple.com/documentation/uidevice/1620037-userinterfaceidiom) | **Usually** present. |
| Main display (size / scale) | `2556 × 1179 @ 3x` | [UIScreen](https://developer.apple.com/documentation/uikit/uiscreen) (nativeBounds, nativeScale) | **Usually** (multi-display iPad may need scene-specific APIs for detail). |
| Battery level / state | `45% — unplugged` | [UIDevice.isBatteryMonitoringEnabled](https://developer.apple.com/documentation/uidevice/1620010-isbatterymonitoringenabled), [batteryLevel](https://developer.apple.com/documentation/uidevice/1620040-batterylevel), [batteryState](https://developer.apple.com/documentation/uidevice/1620040-batterystate) | **User / policy** — level can be -1 if unknown. |
| Service / subscription key | opaque string | [CTTelephonyNetworkInfo.serviceSubscriberCellularProviders](https://developer.apple.com/documentation/coretelephony/cttelephonynetworkinfo/3024510-servicesubscribercellularproviders) keys | **Not** ICCID/IMSI; use as opaque service id for lookups. **Device** only. |
| Carrier name | `T-Mobile` or `—` | [CTCarrier.carrierName](https://developer.apple.com/documentation/coretelephony/ctcarrier/1614088-carriername) (deprecated iOS 16) | **Often empty** on iOS 16+ (privacy; deprecated API). |
| MCC | `310` or `—` | [CTCarrier.mobileCountryCode](https://developer.apple.com/documentation/coretelephony/ctcarrier/1614099-mobilecountrycode) | **Often empty** in same situations as carrier name. |
| MNC | `260` or `—` | [CTCarrier.mobileNetworkCode](https://developer.apple.com/documentation/coretelephony/ctcarrier/1614095-mobilenetworkcode) | **Often empty** as above. |
| ISO country | `us` or `—` | [CTCarrier.isoCountryCode](https://developer.apple.com/documentation/coretelephony/ctcarrier/1614094-isocountrycode) | **Often empty** as above. |
| VoIP allowed | `Yes` / `No` | [CTCarrier.allowsVOIP](https://developer.apple.com/documentation/coretelephony/ctcarrier/1614093-allowsvoip) | Same deprecation caveats as other `CTCarrier` properties. |
| RAT (generation) | `5G` / `LTE (4G)` / raw | [CTTelephonyNetworkInfo.serviceCurrentRadioAccessTechnology](https://developer.apple.com/documentation/coretelephony/cttelephonynetworkinfo/3024511-servicecurrentradioaccesstechnology), [currentRadioAccessTechnology](https://developer.apple.com/documentation/coretelephony/cttelephonynetworkinfo/1614097-currentradioaccesstechnology) | **Best on device**; Simulator / no service may yield `—`. Constants like [CTRadioAccessTechnologyNR](https://developer.apple.com/documentation/coretelephony/ctradioaccesstechnologynr). |
| Data line (which SIM carries data) | “matches data service id” / “not the data line” | [CTTelephonyNetworkInfo.dataServiceIdentifier](https://developer.apple.com/documentation/coretelephony/cttelephonynetworkinfo/3956558-dataserviceidentifier) (iOS 16+) | **Often** useful; compare to keys in the provider map. |
| Path status / cellular use / cost | `Satisfied` / `Yes` for `usesInterfaceType(.cellular)` / `isExpensive` | [NWPath](https://developer.apple.com/documentation/network/nwpath), [usesInterfaceType(_:)](https://developer.apple.com/documentation/network/nwpath/usesinterfacetype), [isExpensive](https://developer.apple.com/documentation/network/nwpath/isexpensive), [isConstrained](https://developer.apple.com/documentation/network/nwpath/isconstrained) | **Generally** from Network framework. |
| Interfaces on current path | `en0` → `Wi-Fi` | [NWPath.availableInterfaces](https://developer.apple.com/documentation/network/nwpath/availableinterfaces) | **Generally**; snapshot may be empty in edge cases. |
| System HTTP proxy | `proxy.example:8080` or “not enabled” | [CFNetworkCopySystemProxySettings](https://developer.apple.com/documentation/cfnetwork/1426315-cfnetworkcopysystemproxysettings) | **User** settings; does not list every VPN. |
| Wi-Fi SSID / BSSID | Not read in this demo | Would require *Access Wi-Fi Information* entitlement and often location consent — see *Limitations* | **Not shown** in this build. |

---

## Limitations — data that **cannot** be read in App Store–safe, public API apps

| Want | Public API? | Why / workaround |
| ---- | ------------- | ----------------- |
| Phone number of the line | **No** | Not exposed to third-party apps; user can see “My Number” in Settings. **Workaround:** user entry + OTP. |
| IMSI, ICCID, EID, IMEI | **No** | Identifiers for SIM and device are protected; not in Core Telephony public surface. **Workaround:** support flows in MDM/enterprise (different distribution), not a general App Store app. |
| Distinguish physical SIM vs eSIM in software | **No** | No stable public property; users see labels in Settings. |
| Inactive eSIM profiles | **No** | Only **active** plans are visible through Core Telephony–style data; inactive profiles are Settings-only. |
| SMS content or which SIM received an SMS in the main app | **No** (main app) | Isolated and privacy-controlled; SMS **filtering** extension has a separate, narrow API. |
| Precise Wi-Fi SSID without entitlements | **Not in this project** | Requires the **Access Wi-Fi Information** capability; often [location usage for SSID on recent iOS](https://developer.apple.com/documentation/technotes/tn1123-analyzing-http-traffic#Detecting-which-wi-fi-network-a-device-is-using). |
| Push reliable “SIM removed” when app is killed | **No** | [subscriberCellularProviderDidUpdateNotifier](https://developer.apple.com/documentation/coretelephony/cttelephonynetworkinfo/subscribercellularproviderdidupdatenotifier) runs only while the process is alive. |

`CTCarrier` and related accessors are **deprecated** from iOS 16; Apple’s messaging indicates **reduced** availability of carrier strings for privacy. The app still calls them so you can *see* what the OS returns on your test hardware.

### Permissions in this project

- **No** microphone, camera, contacts, or **location** usage strings are required for the features implemented here.
- Reading Wi-Fi SSID would add entitlement + usually location permission; that is **documented** but not compiled into this demo to keep the project simple.

---

## Official references (APIs used)

- **Core Telephony** — [https://developer.apple.com/documentation/coretelephony](https://developer.apple.com/documentation/coretelephony)
- **CTTelephonyNetworkInfo** — [https://developer.apple.com/documentation/coretelephony/cttelephonynetworkinfo](https://developer.apple.com/documentation/coretelephony/cttelephonynetworkinfo)
- **CTCarrier** (deprecated) — [https://developer.apple.com/documentation/coretelephony/ctcarrier](https://developer.apple.com/documentation/coretelephony/ctcarrier)
- **UIDevice** — [https://developer.apple.com/documentation/uidevice](https://developer.apple.com/documentation/uidevice)
- **Network framework; NWPathMonitor, NWPath** — [https://developer.apple.com/documentation/network](https://developer.apple.com/documentation/network)
- **CFNetwork (system proxy)** — [https://developer.apple.com/documentation/cfnetwork](https://developer.apple.com/documentation/cfnetwork)
- **User privacy and data** — [https://developer.apple.com/app-store/user-privacy-and-data-use/](https://developer.apple.com/app-store/user-privacy-and-data-use/)
- **Dual SIM user documentation (not a dev API list)** — [https://support.apple.com/guide/iphone/use-dual-sim-iph9c5776d3c/ios](https://support.apple.com/guide/iphone/use-dual-sim-iph9c5776d3c/ios)

---

## Project layout (code map)

- `Services/DeviceInfoService.swift` — UIDevice, screen, battery, `utsname` hardware id.
- `Services/CellularInfoService.swift` — CTTelephonyNetworkInfo / CTCarrier / RAT mapping.
- `Services/NetworkInfoService.swift` — NWPathMonitor helper + row builder for `NWPath`.
- `ViewModels/DeviceNetworkViewModel.swift` — single `@MainActor` state object; wires path updates and telephony refresh.
- `Views/DeviceNetworkDashboard.swift` — main three-section UI.
- `Models/DataField.swift` — one row of UI + `api` string and availability enum.

`CarrierInfoView.swift` and related files remain as an optional **legacy** second UI (`LegacyCarrierTabsView` in `SIMResearchApp.swift` is not the default entry point).

---

## Build requirements

- Xcode 16+ recommended (project currently targets a recent iOS; see `IPHONEOS_DEPLOYMENT_TARGET` in the Xcode project).
- Open `SIMResearch.xcodeproj`, select a **real device** team for signing, build and run.

**Simulator** will not show real cellular; use a physical iPhone with a plan for the full “SIM & carrier” section.

---

## Summary

| You can (public APIs) | You cannot (typical third-party app) |
| --------------------- | ------------------------------------ |
| Hardware model id, OS, IDFV, user-set name, basic display + battery. | MSISDN (phone #), IMSI, ICCID, EID, IMEI as carrier-equipment ids. |
| Opaque per-line keys, and often (if system allows) MCC/MNC, carrier name, RAT, data-line id. | Reliable carrier **name** from `CTCarrier` is **not** guaranteed on modern iOS. |
| `NWPath` for routing, “expensive / constrained,” interface types. | Full “network intelligence” (signal bars as number, exact band, neighbor cells) is not in these APIs. |
| Re-fetch when the OS notifies the app that the cellular **subscription** data changed. | System-wide SIM hot-plug notifications for killed apps. |

**Practical alternatives** when data is missing: let the user type a phone number; verify with **SMS or carrier OTP**; for enterprise, use your organization’s approved MDM/ABM tools where applicable—not general App Store APIs.

---

*This README is part of the SIMResearch demo. Older SMS/SIM “research” Q&A from the original repo is preserved in the repository file [`RESEARCH_NOTES.md`](../RESEARCH_NOTES.md).*
