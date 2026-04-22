# SIMResearch — iOS Device, SIM/eSIM & Network Inspector

A demo iOS application (Swift, SwiftUI, latest iOS SDK) that collects and
displays every piece of device and network-related information that is
accessible through **public** Apple APIs. It is designed to run on real
iPhones with a physical SIM, an eSIM, or both.

> The app deliberately **only** uses public APIs (`UIDevice`,
> `ProcessInfo`, `CoreTelephony`, `Network` framework). No private
> selectors, no swizzling, no entitlement-restricted system frameworks.
> It is App Store safe.

---

## 1. Overview

### What the app does

* Detects the number of active cellular subscriptions (single SIM / dual
  SIM, with a best-effort eSIM-capability heuristic).
* Reads every public field exposed by `CoreTelephony` for each
  subscription — including the radio access technology that is currently
  in use.
* Reads every public field exposed by `UIDevice` / `ProcessInfo` /
  `utsname()` — model, OS version, identifier-for-vendor, locale,
  region, time zone, memory, CPU count, battery level, Low Power Mode.
* Monitors live connectivity using `NWPathMonitor` (Wi-Fi, Cellular,
  Wired Ethernet, Loopback) and exposes path flags such as
  `isExpensive`, `isConstrained`, IPv4 / IPv6 / DNS support.
* Documents — directly inside the app — every value that *cannot* be
  read on iOS, with the reason and the recommended workaround.

### Key features

| Feature                                        | Where in the app             |
| ---------------------------------------------- | ---------------------------- |
| Device identity (model, OS, IDFV, locale, …)   | **Device** tab               |
| SIM / eSIM count, carrier metadata, RAT (5G…)  | **SIM / Carrier** tab        |
| Live connectivity / interface / path flags     | **Network** tab              |
| Documented limitations and references          | **Limitations** tab          |

### Project layout

```
SIMResearch/
├── README.md                       <- this file
└── SIMResearch/
    ├── SIMResearch.xcodeproj/
    └── SIMResearch/
        ├── SIMResearchApp.swift           # @main + tab navigation
        ├── Models/
        │   ├── DeviceInfo.swift
        │   ├── SIMInfo.swift               # SIMSubscription + SIMSnapshot
        │   └── NetworkInfo.swift
        ├── Services/
        │   ├── DeviceInfoService.swift     # UIDevice / ProcessInfo / uname()
        │   ├── SIMInfoService.swift        # CoreTelephony wrapper
        │   └── NetworkInfoService.swift    # NWPathMonitor wrapper
        ├── ViewModels/
        │   ├── DeviceInfoViewModel.swift
        │   ├── SIMInfoViewModel.swift
        │   └── NetworkInfoViewModel.swift
        └── Views/
            ├── DeviceInfoView.swift
            ├── SIMInfoView.swift
            ├── NetworkInfoView.swift
            ├── LimitationsView.swift
            └── Components/
                ├── SectionCard.swift
                ├── InfoRow.swift
                └── StatusBadge.swift
```

The architecture follows a strict **Model → Service → ViewModel → View**
flow. Services are the only types that touch Apple frameworks, view
models are `@MainActor` `ObservableObject`s, and views are pure SwiftUI.

### Build & run

1. Open `SIMResearch/SIMResearch.xcodeproj` in Xcode 16 (or newer).
2. Select an **iPhone** scheme and a real device. The Simulator does
   not return any cellular information.
3. ⚠️ Update the *Signing & Capabilities → Team* to your own Apple
   Developer account before running on device.
4. Build and run (`⌘R`). Grant any prompts the OS shows (the app does
   not request any permission today; see *Permissions* below).

Minimum deployment target: **iOS 16.0** (the app uses the
`serviceCurrentRadioAccessTechnology` API and the `Network` framework
APIs that were introduced in iOS 12 / 14).

### Permissions

This demo deliberately uses APIs that **do not** require a runtime
permission prompt:

* `CoreTelephony` carrier and radio access technology APIs are
  unrestricted.
* `Network` framework reachability is unrestricted.
* `UIDevice` / `ProcessInfo` are unrestricted.

If you later extend the app with location-based info (cell tower
location requires `CoreLocation`) you will need to add
`NSLocationWhenInUseUsageDescription` to the Info.plist and call
`CLLocationManager.requestWhenInUseAuthorization()`.

---

## 2. Data Points

For every field shown by the app, the table below documents:

* **Name** – the label shown in the UI.
* **Example value** – what you might see on a real iPhone 15 in Germany.
* **API** – the public Apple symbol that produced the value.
* **Availability** – *Always*, *Restricted* (returns placeholder /
  `nil`), *Conditional* (depends on hardware / OS).

### 2.1 Device tab (`DeviceInfoService`)

| Name                  | Example                              | API                                                    | Availability |
| --------------------- | ------------------------------------ | ------------------------------------------------------ | ------------ |
| Marketing model       | `iPhone 15 Pro`                      | derived from `utsname.machine`                         | Always       |
| Hardware identifier   | `iPhone16,1`                         | `uname()` → `utsname.machine`                          | Always       |
| Generic model         | `iPhone`                             | `UIDevice.current.model`                               | Always       |
| Localized model       | `iPhone`                             | `UIDevice.current.localizedModel`                      | Always       |
| Device name           | `iPhone` (iOS 16+) / `Anna's iPhone` | `UIDevice.current.name`                                | Restricted on iOS 16+ — generic name unless app holds the `com.apple.developer.device-information.user-assigned-device-name` entitlement |
| `identifierForVendor` | `B0E…-…`                             | `UIDevice.current.identifierForVendor`                 | Always (may be `nil` while device is locked right after install) |
| System name           | `iOS`                                | `UIDevice.current.systemName`                          | Always       |
| System version        | `17.4.1`                             | `UIDevice.current.systemVersion`                       | Always       |
| Kernel name           | `Darwin`                             | `uname()` → `utsname.sysname`                          | Always       |
| Active CPU cores      | `6`                                  | `ProcessInfo.processInfo.activeProcessorCount`         | Always       |
| Physical memory       | `7.45 GB`                            | `ProcessInfo.processInfo.physicalMemory`               | Always       |
| Multitasking          | `Yes`                                | `UIDevice.current.isMultitaskingSupported`             | Always       |
| Locale                | `en_DE`                              | `Locale.current.identifier`                            | Always       |
| Region                | `DE`                                 | `Locale.current.region` / `regionCode`                 | Always       |
| Time zone             | `Europe/Berlin`                      | `TimeZone.current.identifier`                          | Always       |
| Preferred languages   | `en, de-DE, fr`                      | `Locale.preferredLanguages`                            | Always       |
| Battery level         | `87 %`                               | `UIDevice.current.batteryLevel`                        | Conditional (returns `-1` until `isBatteryMonitoringEnabled = true`) |
| Battery state         | `Charging`                           | `UIDevice.current.batteryState`                        | Conditional (same as above) |
| Low Power Mode        | `Off`                                | `ProcessInfo.processInfo.isLowPowerModeEnabled`        | Always       |

### 2.2 SIM / Carrier tab (`SIMInfoService` → `CoreTelephony`)

| Name                          | Example (iOS ≤ 15)         | Example (iOS 16+)        | API                                                                                          | Availability |
| ----------------------------- | -------------------------- | ------------------------ | -------------------------------------------------------------------------------------------- | ------------ |
| Service identifier            | `0000000100000001`         | `0000000100000001`       | key in `CTTelephonyNetworkInfo.serviceCurrentRadioAccessTechnology`                          | Always       |
| Carrier name                  | `Vodafone`                 | `--`                     | `CTCarrier.carrierName`                                                                       | Restricted on iOS 16+ (returns placeholder, **deprecated**) |
| Mobile Country Code (MCC)     | `262`                      | `--`                     | `CTCarrier.mobileCountryCode`                                                                 | Restricted on iOS 16+ (deprecated) |
| Mobile Network Code (MNC)     | `02`                       | `--`                     | `CTCarrier.mobileNetworkCode`                                                                 | Restricted on iOS 16+ (deprecated) |
| ISO country code              | `de`                       | `--`                     | `CTCarrier.isoCountryCode`                                                                    | Restricted on iOS 16+ (deprecated) |
| Allows VoIP                   | `Yes`                      | `false`                  | `CTCarrier.allowsVOIP`                                                                        | Restricted on iOS 16+ (deprecated) |
| Radio access technology       | `LTE`, `5G NR`, …          | `LTE`, `5G NR`, …        | `CTTelephonyNetworkInfo.serviceCurrentRadioAccessTechnology` (`CTRadioAccessTechnology*`)     | Always       |
| Data subscription identifier  | `0000000100000001`         | `0000000100000001`       | `CTTelephonyNetworkInfo.dataServiceIdentifier`                                                | iOS 13+ — may be `nil` on single-SIM devices |
| Number of active subscriptions| `1` or `2`                 | `1` or `2`               | count of `serviceCurrentRadioAccessTechnology` keys                                           | Always (counts only *active* services) |
| Live update notification      | —                          | —                        | `serviceSubscriberCellularProvidersDidUpdateNotifier`, `serviceCurrentRadioAccessTechnologyDidUpdateNotifier` | While app is running |

### 2.3 Network tab (`NetworkInfoService` → `NWPathMonitor`)

| Name                  | Example       | API                                                                | Availability |
| --------------------- | ------------- | ------------------------------------------------------------------ | ------------ |
| Connectivity status   | `Connected`   | `NWPath.status`                                                    | Always (live) |
| Primary interface     | `Cellular`    | `NWPath.usesInterfaceType(_:)`                                     | Always       |
| Available interfaces  | `Cellular, Loopback` | `NWPath.availableInterfaces`                                | Always       |
| Expensive             | `Yes`         | `NWPath.isExpensive`                                               | iOS 12+      |
| Constrained           | `No`          | `NWPath.isConstrained`                                             | iOS 13+      |
| Supports IPv4         | `Supported`   | `NWPath.supportsIPv4`                                              | Always       |
| Supports IPv6         | `Supported`   | `NWPath.supportsIPv6`                                              | Always       |
| Supports DNS          | `Supported`   | `NWPath.supportsDNS`                                               | Always       |

---

## 3. Limitations — what iOS does **not** allow

The list below is the *complete* set of fields the user query asked
about that we **cannot** read on iOS, together with the reason. The app
also surfaces this list inside the **Limitations** tab.

| Field                                     | Status        | Reason                                                                                                                                                   |
| ----------------------------------------- | ------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Device phone number / MSISDN              | ❌ Not allowed | No public API. Apple removed all access years ago for privacy reasons. Even the user-visible "My Number" field in *Settings → Phone* is not exposed.       |
| IMEI                                      | ❌ Not allowed | The IMEI is a globally unique hardware identifier; Apple gates it behind MDM private entitlements. Never exposed to App Store apps.                       |
| ICCID (SIM serial number)                 | ❌ Not allowed | Same as IMEI — restricted to MDM and carrier-private frameworks.                                                                                          |
| IMSI                                      | ❌ Not allowed | Same as IMEI / ICCID.                                                                                                                                     |
| Carrier name (`CTCarrier.carrierName`)    | ⚠️ Deprecated  | Apple deprecated `CTCarrier` in iOS 16. The property still compiles but returns a placeholder string (`--`) at runtime, **with no replacement API**.       |
| MCC / MNC / ISO country code              | ⚠️ Deprecated  | Same root cause as the carrier name — gated behind the same iOS 16 deprecation.                                                                           |
| Inactive eSIM profiles                    | ❌ Not allowed | `CoreTelephony` only reports services that are **active**. Inactive eSIM profiles installed in the secure enclave are invisible to apps.                  |
| Distinguishing physical SIM from eSIM     | ❌ Not allowed | The CoreTelephony API does not surface the form factor of a subscription. Only carriers / Apple know which slot a service uses.                           |
| SIM removal / insertion notifications     | ❌ Not allowed | There is no public notification. CoreTelephony only invokes its update callbacks while the app is in the foreground and only when the *active* set changes. |
| Which SIM received an SMS                 | ❌ Not allowed | The OS does not surface the receiving-slot metadata to apps or to the SMS Filter Extension. Users can only filter by SIM in the system Messages app.       |
| Reading SMS contents / sender name        | ❌ Not allowed | Apps cannot read the SMS database. SMS Filter Extensions can see the sender phone number only, never the contact name or message body.                    |
| MAC address (Wi-Fi / cellular)            | ❌ Not allowed | Always returns `02:00:00:00:00:00` since iOS 7. Apple uses MAC randomization on Wi-Fi.                                                                    |
| Advertising identifier (IDFA)             | ⚠️ Restricted  | Available only after `ATTrackingManager.requestTrackingAuthorization` — not used by this demo because we do not advertise.                                |
| Cell tower / base-station identifiers     | ❌ Not allowed | Removed from public APIs years ago.                                                                                                                       |
| WHOIS / IP address of the device          | ⚠️ Restricted  | The local IP is reachable via `getifaddrs()` but the public-internet IP requires a network round-trip to a third-party service. Not exposed by Apple.      |

### Recommended workarounds

| Use case                            | Workaround                                                                                                  |
| ----------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| You need the user's phone number    | Ask them to enter it, then verify with an OTP sent through your own SMS gateway / Sign in with Apple.       |
| You need a stable per-install ID    | Use `identifierForVendor` (resets on uninstall) or generate a UUID stored in the Keychain (resets only on full device wipe). |
| You need to detect SIM swap         | Trigger a server-side OTP re-verification when the user opens the app after a long pause. Apple does not let you observe SIM events while the app is suspended. |
| You need to detect "5G connected"   | Read the radio access technology from `CTTelephonyNetworkInfo.serviceCurrentRadioAccessTechnology` (covered by this app). |
| You need to detect Wi-Fi vs. cellular | Use `NWPathMonitor.usesInterfaceType(_:)` (covered by this app).                                            |

---

## 4. References

Official Apple documentation for every API used by the app:

### CoreTelephony

* [Core Telephony framework](https://developer.apple.com/documentation/coretelephony)
* [`CTTelephonyNetworkInfo`](https://developer.apple.com/documentation/coretelephony/cttelephonynetworkinfo)
* [`serviceCurrentRadioAccessTechnology`](https://developer.apple.com/documentation/coretelephony/cttelephonynetworkinfo/servicecurrentradioaccesstechnology)
* [`serviceCurrentRadioAccessTechnologyDidUpdateNotifier`](https://developer.apple.com/documentation/coretelephony/cttelephonynetworkinfo/servicecurrentradioaccesstechnologydidupdatenotifier)
* [`serviceSubscriberCellularProvidersDidUpdateNotifier`](https://developer.apple.com/documentation/coretelephony/cttelephonynetworkinfo/servicesubscribercellularprovidersdidupdatenotifier)
* [`CTCarrier` (deprecated)](https://developer.apple.com/documentation/coretelephony/ctcarrier)
* [`CTRadioAccessTechnology…` constants](https://developer.apple.com/documentation/coretelephony/ctradioaccesstechnology)

### UIDevice / ProcessInfo / Locale

* [`UIDevice`](https://developer.apple.com/documentation/uikit/uidevice)
* [`UIDevice.identifierForVendor`](https://developer.apple.com/documentation/uikit/uidevice/identifierforvendor)
* [`ProcessInfo`](https://developer.apple.com/documentation/foundation/processinfo)
* [`Locale`](https://developer.apple.com/documentation/foundation/locale)
* [`TimeZone`](https://developer.apple.com/documentation/foundation/timezone)
* [`utsname` / `uname(2)`](https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man3/uname.3.html)

### Network framework

* [Network framework](https://developer.apple.com/documentation/network)
* [`NWPathMonitor`](https://developer.apple.com/documentation/network/nwpathmonitor)
* [`NWPath`](https://developer.apple.com/documentation/network/nwpath)
* [`NWInterface.InterfaceType`](https://developer.apple.com/documentation/network/nwinterface/interfacetype)

### Privacy & policy

* [App privacy details on the App Store](https://developer.apple.com/app-store/app-privacy-details/)
* [User privacy and data use](https://developer.apple.com/app-store/user-privacy-and-data-use/)
* [Required reasons API – Apple Developer](https://developer.apple.com/documentation/bundleresources/privacy_manifest_files/describing_use_of_required_reason_api)

---

## 5. Summary

### Feasible on iOS

* Full **device profile**: model, OS version, locale, region, time
  zone, IDFV, CPU/RAM, battery, Low Power Mode.
* **Cellular subscription presence**: number of active services,
  per-service identifier, VoIP support, live notifications when the
  active set changes (while the app is in the foreground).
* **Radio access technology** per service (LTE, 5G NSA, 5G NR, …) with
  live updates.
* Full **network reachability**: status, primary interface, available
  interfaces, expensive / constrained / IPv4 / IPv6 / DNS flags, with
  live updates.

### Not possible on iOS — and why

* **Phone number / MSISDN, IMEI, ICCID, IMSI** — restricted by Apple's
  privacy policy. Reserved for MDM / carrier private frameworks.
* **Carrier name, MCC, MNC, ISO country code** — Apple deprecated
  `CTCarrier` in iOS 16 and returns placeholder values. There is **no
  replacement** public API today.
* **Inactive eSIM profiles** — only active services are visible.
* **SIM insertion / removal events** — no notification while the app is
  suspended; even while running, only changes to the *active* set fire.
* **Reading SMS** or knowing **which SIM received an SMS** — completely
  blocked. SMS Filter Extensions only see the sender number, never the
  body, sender name or receiving slot.
* **MAC address / cell tower IDs** — randomized or removed years ago.

### Suggested alternatives

* For phone number ownership use **OTP verification** through your own
  back-end or **Sign in with Apple**.
* For "did the SIM change since last login" use a **server-side
  challenge** when the app re-opens.
* For 5G detection use the **radio access technology** field exposed by
  this app (it is the official, supported way).
* For per-device analytics use **`identifierForVendor`** combined with
  the App Store's privacy nutrition labels — never the IMEI / MAC /
  IDFA.

---

## License

This sample is released under the MIT license. See the source files for
full attribution. Marketing model names © Apple Inc.
