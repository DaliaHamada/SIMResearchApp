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
| **Trust** | The four-layer App Store-safe device-identity stack that replaces IMEI / IMSI / ICCID / EID / MEID for banking / government use cases: IDFV + Keychain UUID + DeviceCheck + App Attest |
| **IDs** | Catalog of every identifier the app can read, with a per-trigger matrix showing exactly when each one is reset (reboot, OS update, app reinstall, all-vendor-apps removed, factory wipe, new iPhone). Sourced from Apple's documented behaviour for `Foundation.UUID` and `UIDevice.identifierForVendor`. |
| **MSISDN** | User-assisted MSISDN-via-USSD lookup for the four Egyptian operators (Vodafone, Etisalat, Orange, WE). Pre-fills the dialer; the user confirms the call and types the number back. |
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
        │   ├── NetworkInfo.swift
        │   ├── MSISDNLookup.swift     # EgyptianCarrier, MSISDNEntry, MSISDNNormalizer
        │   ├── DeviceTrust.swift      # DeviceTrustSnapshot, DeviceCheckState, AppAttestState
        │   └── IdentifierLifecycle.swift # IdentifierLifecycleEntry, change-trigger matrix
        ├── Services/
        │   ├── DeviceInfoService.swift
        │   ├── SIMInfoService.swift   # CoreTelephony + RAT notifications
        │   ├── NetworkInfoService.swift
        │   ├── USSDLookupService.swift       # tel:// dialer + on-disk MSISDN store
        │   ├── KeychainUUIDService.swift     # device-only Keychain UUID
        │   ├── DeviceCheckService.swift      # DCDevice.generateToken
        │   ├── AppAttestService.swift        # DCAppAttestService key / attest / assertion
        │   ├── DeviceTrustService.swift      # orchestrator
        │   └── IdentifierCatalogService.swift # collects every live identifier
        ├── ViewModels/
        │   ├── MSISDNLookupViewModel.swift
        │   ├── DeviceTrustViewModel.swift
        │   └── IdentifierCatalogViewModel.swift
        └── Views/
            ├── DeviceInfoView.swift
            ├── SIMInfoView.swift
            ├── NetworkInfoView.swift
            ├── MSISDNLookupView.swift
            ├── DeviceTrustView.swift
            ├── IdentifierCatalogView.swift
            ├── LimitationsView.swift
            └── Components/
```

Architecture: **Model → Service → ViewModel → View**. Services talk to Apple frameworks; view models are `@MainActor` `ObservableObject`s; views are SwiftUI.

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

### 2.3 MSISDN tab (`USSDLookupService`)

User-assisted lookup for Egyptian operators. The app cannot read the USSD response — only the user can — so the value the user types back is what gets stored.

| Carrier | USSD code | iOS dialer behavior |
| --- | --- | --- |
| Vodafone | `*878#` | Pre-fills via `tel://*878%23`; system confirmation sheet shown. |
| Etisalat | `*947#` | Pre-fills via `tel://*947%23`; system confirmation sheet shown. |
| Orange | `#119#` | iOS rejects USSD URLs starting with `#`. App copies the code to the clipboard and instructs manual dial. |
| WE | `*688#` | Pre-fills via `tel://*688%23`; system confirmation sheet shown. |

The carrier is **not** auto-detected (`CTCarrier` is deprecated and masked on iOS 16+); the user picks one of the four cards.

> Why isn't this silent / background? See `LimitationsView` and section 3 below. Silent USSD dialing is the textbook toll-fraud pattern; iOS has no API for it, in any tier (App Store, Enterprise, or MDM).

### 2.4 Trust tab (`DeviceTrustService`)

The four-layer device-trust stack. This is the artifact to take to a banking / regulator / government stakeholder when they ask for IMEI on iOS.

| Layer | API | What it gives you | Bank / KYC use case |
| --- | --- | --- | --- |
| 1. IDFV | `UIDevice.identifierForVendor` | UUID per (vendor, device); resets when all vendor apps uninstalled | Lightweight session/device fingerprint |
| 2. Keychain device UUID | `Security` + `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` | UUID that survives app uninstall on the same device, never syncs to iCloud | Persistent half of "remember this device" |
| 3. DeviceCheck | `DCDevice.generateToken` | Apple-issued opaque blob; backend exchanges with Apple to read/write 2 device-scoped bits per developer team | Fraud blocklist that survives app reinstall |
| 4. App Attest | `DCAppAttestService` | Hardware-attested Secure Enclave key; per-request signatures only an unmodified copy of the app on a real device can produce | Strong customer authentication / request integrity per CBE, EBA SCA, FFIEC |

> Why is this in this repo? Because this is the App Store-safe replacement for the blocked hardware identifiers (IMEI, IMSI, ICCID, EID, MEID, MAC). Every licensed banking app in MENA / EU uses some combination of these four. App Attest in particular is technically *stronger* than IMEI was for the fraud use case — IMEI is a 15-digit static string trivially spoofable in any HTTP client; App Attest is a per-request signature only this app on this device can produce.

### 2.5 IDs tab (`IdentifierCatalogService`)

Comprehensive answer to "what unique IDs can I get on iOS, and what changes each one?" Pulled live from the existing services and ordered most-stable → least-stable.

| Identifier | Stability | Resets on |
| --- | --- | --- |
| Hardware identifier (`utsname.machine`) | Immutable hardware fact | Replacing the device |
| Marketing model (derived) | Immutable hardware fact | Replacing the device |
| iOS version (`UIDevice.systemVersion`) | Per device | iOS update |
| Keychain device UUID (`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`) | Per device | Factory reset, new iPhone |
| App Attest key id (`DCAppAttestService.generateKey`) | Per Secure Enclave key | Factory reset, new iPhone, build signed by a different developer team |
| `identifierForVendor` (IDFV) | Per vendor install | Removing ALL vendor apps then reinstalling, factory reset, new iPhone, different developer team — see [Apple docs](https://developer.apple.com/documentation/uikit/uidevice/identifierforvendor) |
| CoreTelephony service identifier(s) | Per app install | SIM swap, factory reset, new iPhone, app reinstall |
| Locale identifier | Per device | Factory reset, new iPhone (also user changing language in Settings) |
| DeviceCheck token (`DCDevice.generateToken`) | Per call | Every call. The token bytes change every time, but the underlying (device, developer team) pair Apple's servers see is stable. |

> Practical guidance for a "phone id": use the 3-layer composite — Keychain UUID + IDFV + App Attest signature. The Trust tab implements all three. Only a factory reset or moving to a new physical iPhone resets all three at once.

### 2.6 Network tab (`NetworkInfoService`)

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
| Silent / background USSD dialing (e.g. `*878#`, `*947#`, `#119#`, `*688#`) | `tel:` always shows the system call sheet, cannot run from the background, and the carrier's USSD response is never delivered to the app. The MSISDN tab implements the only flow Apple permits: user-confirmed dial + manual copy-back. |
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
