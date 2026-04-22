# SIMResearch — iOS Device, SIM/eSIM & Network Inspector

A demo iOS application (Swift, SwiftUI) that surfaces **device**, **cellular**, and **network reachability** data available through **public** Apple APIs. It is meant to run on real iPhones with a physical SIM, eSIM, or both.

The app uses only public APIs (`UIDevice`, `CoreTelephony`, `Network`, POSIX `uname()`). No private selectors, swizzling, or entitlement-restricted system frameworks. It is App Store–safe.

---

## 1. Overview

### What the app does

* Counts **active** cellular subscriptions (single / dual SIM) and shows a best-effort **eSIM-capable** heuristic.
* Reads **CoreTelephony** data per subscription: service id, VoIP flag, radio access technology (RAT), and deprecated `CTCarrier` fields when the OS still returns real values (often masked on iOS 16+).
* Reads **device / OS / locale** context from `UIDevice`, `uname()`, `Locale`, and `TimeZone`.
* Monitors **NWPathMonitor** (Wi‑Fi, cellular, flags, IPv4/IPv6/DNS).
* Lists **limitations** inside the **Limitations** tab (aligned with Apple’s privacy and API restrictions).

### Tabs

| Tab | Content |
| --- | ------- |
| **Device** | Identity (model, `uname` id, IDFV), OS, locale & region |
| **SIM / Carrier** | Subscriptions, RAT, optional operator strings when not placeholders; summary & data line when present |
| **Network** | `NWPathMonitor` status, interfaces, expensive/constrained, IP family support |
| **Limitations** | What iOS does not expose and practical workarounds |

### Non-empty / “concrete” fields in code

For logging or UI that should **omit nil, blank, or `--` operator masks**:

* `SIMSubscription.concreteCollectedFields` — tuples of label + value with real content.
* `SIMSnapshot.concreteContextFields` — non-empty snapshot strings (e.g. data subscription id).
* `SIMSubscription.meaningfulOperatorString(_:)` — helper for MCC/MNC/name/ISO filtering.
* `DeviceInfo.concreteCollectedStringFields` — non-empty strings from the device snapshot (skips blank optionals).

### Project layout

```
SIMResearchApp/
├── README.md                          # this file
└── SIMResearch/
    ├── SIMResearch.xcodeproj/
    └── SIMResearch/
        ├── SIMResearchApp.swift       # @main + TabView
        ├── Models/
        │   ├── DeviceInfo.swift
        │   ├── SIMInfo.swift          # SIMSubscription, SIMSnapshot
        │   └── NetworkInfo.swift
        ├── Services/
        │   ├── DeviceInfoService.swift
        │   ├── SIMInfoService.swift   # CoreTelephony + RAT notifications
        │   └── NetworkInfoService.swift
        ├── ViewModels/
        └── Views/
            ├── DeviceInfoView.swift
            ├── SIMInfoView.swift
            ├── NetworkInfoView.swift
            ├── LimitationsView.swift
            └── Components/
```

Architecture: **Model → Service → ViewModel → View**. Services talk to Apple frameworks; view models are `@MainActor` `ObservableObject`s; views are SwiftUI.

### Build & run

1. Open `SIMResearch/SIMResearch.xcodeproj` in **Xcode 16+**.
2. Select the **SIMResearch** scheme and an **iPhone** destination. The **Simulator does not report cellular subscriptions** (SIM tab will be empty).
3. **Signing**: set **Automatically manage signing** and choose your **Team** under *Signing & Capabilities*. The bundle identifier must match an App ID your team is allowed to use (org-specific IDs may be required for some provisioning setups).
4. Build and run (**⌘R**). The app does not declare runtime permission strings; `CoreTelephony` and `Network` do not require user prompts for the reads used here.

**Minimum deployment target:** **iOS 18.2** (as set in the Xcode project).

### Permissions

These APIs do **not** require `Info.plist` usage descriptions for the features shipped in this demo:

* CoreTelephony (public subscription/RAT reads)
* Network (`NWPathMonitor`)
* `UIDevice` / `Locale` / `TimeZone` / `uname()`

If you add location or tracking, you must add the appropriate keys and flows.

---

## 2. Data points (reference)

### 2.1 Device tab (`DeviceInfoService`)

| Name | Example | API | Availability |
| --- | --- | --- | --- |
| Marketing model | `iPhone 15 Pro` | Mapped from `utsname.machine` | Always |
| Hardware identifier | `iPhone16,1` | `uname()` → `utsname.machine` | Always |
| Generic / localized model | `iPhone` | `UIDevice.model`, `localizedModel` | Always |
| Device name | `iPhone` (iOS 16+) | `UIDevice.name` | Restricted on iOS 16+ without special entitlements |
| `identifierForVendor` | UUID string | `UIDevice.identifierForVendor` | Usually present; may be `nil` briefly after install |
| System name / version | `iOS`, `18.x` | `UIDevice.systemName`, `systemVersion` | Always |
| Kernel name | `Darwin` | `uname()` → `utsname.sysname` | Always |
| Locale, region, timezone, languages | `en_DE`, `DE`, `Europe/Berlin`, … | `Locale`, `TimeZone` | Region may be `nil` in edge cases |

### 2.2 SIM / Carrier tab (`SIMInfoService`)

| Name | Example (iOS ≤ 15) | Example (iOS 16+) | API | Availability |
| --- | --- | --- | --- | --- |
| Service identifier | `0000000100000001` | same | Keys in `serviceSubscriberCellularProviders` / RAT maps | When a subscription exists |
| Carrier name, MCC, MNC, ISO | real strings | often `--` or empty | `CTCarrier` via `serviceSubscriberCellularProviders` | **Deprecated** iOS 16+; placeholders common |
| Allows VoIP | `Yes` / `No` | `CTCarrier.allowsVOIP` | When provider dict exists |
| Radio access technology | `LTE`, `5G NR`, … | same | `serviceCurrentRadioAccessTechnology` | Best-effort; display may show “No service” when unregistered |
| Data subscription id | `0000000100000001` | `CTTelephonyNetworkInfo.dataServiceIdentifier` | iOS 13+; may be `nil` |
| Active subscription count | `1` / `2` | Keys from `serviceSubscriberCellularProviders` when non-empty; otherwise RAT map keys (avoids extra RAT-only ids inflating single-SIM counts) | Conditional |

**Live updates:** `serviceSubscriberCellularProvidersDidUpdateNotifier` (deprecated iOS 16, no replacement) plus `NotificationCenter` observation of **`CTRadioAccessTechnologyDidChange`** for RAT changes. There is **no** public `serviceCurrentRadioAccessTechnologyDidUpdateNotifier` on `CTTelephonyNetworkInfo`.

### 2.3 Network tab (`NetworkInfoService`)

| Name | Example | API | Availability |
| --- | --- | --- | --- |
| Path status | Connected / … | `NWPath.status` | Live |
| Primary / available interfaces | Wi‑Fi, Cellular, … | `NWPath.usesInterfaceType`, `availableInterfaces` | Live |
| Expensive / constrained | Yes / No | `NWPath.isExpensive`, `isConstrained` | Live |
| IPv4 / IPv6 / DNS | Supported / not | `NWPath.supportsIPv4` / `supportsIPv6` / `supportsDNS` | Live |

---

## 3. Limitations — what iOS does **not** allow

The **Limitations** tab mirrors this for stakeholders. Short version:

| Topic | Status |
| --- | --- |
| Phone number (MSISDN), IMEI, ICCID, IMSI | Not available to App Store apps |
| Carrier name / MCC / MNC / ISO on iOS 16+ | Deprecated `CTCarrier`; placeholders; **no public replacement** |
| Inactive eSIM profiles | Not visible; only **active** services |
| Physical SIM vs eSIM slot | Not distinguishable via public API |
| SIM hot-swap while suspended | No guaranteed delivery to apps |
| SMS body / which SIM received SMS | Not exposed (filters: very limited sender info only) |
| Wi‑Fi / cellular MAC, tower IDs | Not exposed / randomized |

### Workarounds (high level)

* **Phone ownership:** OTP or Sign in with Apple.
* **Stable install id:** `identifierForVendor` or Keychain-stored UUID.
* **“SIM may have changed”:** server re-challenge on sensitive actions.
* **5G / LTE connected:** RAT from `CTTelephonyNetworkInfo` (this app).
* **Wi‑Fi vs cellular:** `NWPathMonitor` (this app).

---

## 4. References (Apple)

* [Core Telephony](https://developer.apple.com/documentation/coretelephony) — [`CTTelephonyNetworkInfo`](https://developer.apple.com/documentation/coretelephony/cttelephonynetworkinfo), [`serviceCurrentRadioAccessTechnology`](https://developer.apple.com/documentation/coretelephony/cttelephonynetworkinfo/servicecurrentradioaccesstechnology), [`serviceSubscriberCellularProvidersDidUpdateNotifier`](https://developer.apple.com/documentation/coretelephony/cttelephonynetworkinfo/servicesubscribercellularprovidersdidupdatenotifier), [`CTCarrier`](https://developer.apple.com/documentation/coretelephony/ctcarrier) (deprecated)
* `CTRadioAccessTechnologyDidChange` — posted on `NotificationCenter` when radio access technology changes (see Apple’s *Core Telephony* and *NSNotification.Name* documentation).
* [UIDevice](https://developer.apple.com/documentation/uikit/uidevice), [Locale](https://developer.apple.com/documentation/foundation/locale), [TimeZone](https://developer.apple.com/documentation/foundation/timezone), [`uname`](https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man3/uname.3.html)
* [Network](https://developer.apple.com/documentation/network) — [`NWPathMonitor`](https://developer.apple.com/documentation/network/nwpathmonitor), [`NWPath`](https://developer.apple.com/documentation/network/nwpath)
* [App privacy details](https://developer.apple.com/app-store/app-privacy-details/), [Required reason APIs](https://developer.apple.com/documentation/bundleresources/privacy_manifest_files/describing_use_of_required_reason_api)

---

## 5. Summary

**Feasible with public APIs:** device/OS/locale snapshot; active cellular subscription count and identifiers; RAT per service; live path monitoring.

**Not feasible or heavily degraded:** MSISDN, IMEI, ICCID, IMSI; trustworthy operator strings on modern iOS without server-side or MDM solutions; inactive eSIM inventory; SIM form-factor and SMS routing details.

---

## License

This sample is released under the **MIT** license unless otherwise noted in the repository. Marketing model strings map Apple hardware codes to public product names.
