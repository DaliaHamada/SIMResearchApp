# SIM Research Demo

SwiftUI demo application for iPhone that collects and displays all device, SIM/carrier, and network information that is realistically available to a normal iOS app through public Apple APIs.

## Overview

This demo is designed for testing on real iPhones, including:

- iPhones with a physical SIM
- iPhones with eSIM
- iPhones with two active cellular plans
- Wi-Fi only or simulator scenarios where telephony data is unavailable

The app displays data in three sections:

1. **Device Info**
2. **SIM / Carrier Info**
3. **Network Info**

The implementation uses only public Apple frameworks:

- `UIKit` / `UIDevice`
- `CoreTelephony`
- `Network`

No private APIs are used.

## Key Features

- SwiftUI-based dashboard UI
- Modular services for device, telephony, and network collection
- Best-effort SIM/service summary using public CoreTelephony APIs
- Carrier information display when iOS exposes it
- Radio access technology display (LTE, 5G NSA, 5G SA, etc.)
- Live network path monitoring using `NWPathMonitor`
- Clear fallback messaging when data is restricted, deprecated, unavailable, or simulator-only
- Detailed documentation of what iOS can and cannot expose

## Project Structure

```text
SIMResearch/
├── SIMResearch.xcodeproj
└── SIMResearch/
    ├── App/
    │   └── SIMResearchApp.swift
    ├── Models/
    │   └── DashboardModels.swift
    ├── Services/
    │   ├── DeviceInfoService.swift
    │   ├── NetworkPathMonitorService.swift
    │   └── TelephonyInfoService.swift
    ├── ViewModels/
    │   └── DashboardViewModel.swift
    ├── Views/
    │   ├── DashboardView.swift
    │   └── Components/
    │       ├── InfoItemRow.swift
    │       ├── SectionHeaderCard.swift
    │       └── SubscriptionCard.swift
    ├── Assets.xcassets
    └── Preview Content/
```

## How the App Works

### Device Info

Collected from `UIDevice` and `uname()`:

- Device name
- Model
- Localized model
- Machine identifier
- System name
- System version
- `identifierForVendor`

### SIM / Carrier Info

Collected from `CTTelephonyNetworkInfo` and `CTCellularData`:

- Best-effort active subscription count
- Best-effort SIM status summary
- Current data service identifier
- Cellular data restricted state
- Per-service carrier information, when available:
  - Carrier name
  - MCC
  - MNC
  - ISO country code
  - Allows VoIP
  - Current radio access technology

### Network Info

Collected from `NWPathMonitor`:

- Path status
- Active interface types
- Whether Wi-Fi is in use
- Whether cellular is in use
- Whether wired Ethernet is in use
- Whether the path is expensive
- Whether the path is constrained
- DNS, IPv4, and IPv6 support

## Permissions

This demo does not require a runtime permission prompt for the APIs it currently uses.

Important notes:

- `UIDevice` properties used here do not require user permission.
- `NWPathMonitor` does not require a prompt for general path monitoring.
- `CoreTelephony` APIs used here do not trigger a standard iOS permission dialog.
- Some telephony values may still be blank, stubbed, deprecated, or restricted by the system on modern iOS.

## Data Points

The table below documents the data displayed by the app, the API used, example values, and whether the data is reliably available.

| Data | Example value | API used | Availability |
| --- | --- | --- | --- |
| Device name | `iPhone` | `UIDevice.current.name` | Restricted in practice on iOS 16+; normally generic unless Apple grants the user-assigned-device-name entitlement |
| Model | `iPhone` | `UIDevice.current.model` | Usually available |
| Localized model | `iPhone` | `UIDevice.current.localizedModel` | Usually available |
| Machine identifier | `iPhone16,2` | `uname()` | Usually available |
| System name | `iOS` | `UIDevice.current.systemName` | Usually available |
| System version | `18.2` | `UIDevice.current.systemVersion` | Usually available |
| Identifier for vendor | `E2D4...` | `UIDevice.current.identifierForVendor` | Usually available, but scoped to the app vendor and not stable across all reinstalls |
| SIM status summary | `Two active subscriptions exposed` | `CTTelephonyNetworkInfo.serviceSubscriberCellularProviders` | Limited; best effort only |
| Active subscription count | `2` | `CTTelephonyNetworkInfo.serviceSubscriberCellularProviders.count` | Limited; active exposed services only |
| Current data service identifier | `0000000100000001` | `CTTelephonyNetworkInfo.dataServiceIdentifier` | Sometimes available |
| Cellular data restriction | `Not restricted` | `CTCellularData.restrictedState` | Usually available |
| Carrier name | `Vodafone` | `CTCarrier.carrierName` | Deprecated on iOS 16+ and may be blank or placeholder |
| MCC | `262` | `CTCarrier.mobileCountryCode` | Deprecated on iOS 16+ and may be blank or placeholder |
| MNC | `02` | `CTCarrier.mobileNetworkCode` | Deprecated on iOS 16+ and may be blank or placeholder |
| ISO country code | `de` | `CTCarrier.isoCountryCode` | Deprecated on iOS 16+ and may be blank or placeholder |
| Allows VoIP | `Yes` | `CTCarrier.allowsVOIP` | May still be available but belongs to deprecated `CTCarrier` |
| Radio access technology | `LTE (4G)` / `5G NSA` | `CTTelephonyNetworkInfo.serviceCurrentRadioAccessTechnology` | Sometimes available on real cellular devices |
| Path status | `Satisfied` | `NWPath.status` | Usually available |
| Interface types in use | `Wi-Fi`, `Cellular` | `NWPath.usesInterfaceType(_:)` | Usually available |
| Uses Wi-Fi | `Yes` | `NWPath.usesInterfaceType(.wifi)` | Usually available |
| Uses cellular | `No` | `NWPath.usesInterfaceType(.cellular)` | Usually available |
| Uses wired Ethernet | `No` | `NWPath.usesInterfaceType(.wiredEthernet)` | Usually available |
| Is expensive | `Yes` | `NWPath.isExpensive` | Usually available |
| Is constrained | `No` | `NWPath.isConstrained` | Usually available |
| Supports DNS | `Yes` | `NWPath.supportsDNS` | Usually available |
| Supports IPv4 | `Yes` | `NWPath.supportsIPv4` | Usually available |
| Supports IPv6 | `Yes` | `NWPath.supportsIPv6` | Usually available |

## SIM / eSIM Detection Reality on iOS

The requirement asks for detection of SIM / eSIM availability, including single SIM, dual SIM, and eSIM. On iOS, this must be described carefully:

### What is feasible

- You can count the number of **active cellular services currently exposed** by CoreTelephony.
- If one service is exposed, you can say **one active cellular subscription is exposed**.
- If two services are exposed, you can say **two active cellular subscriptions are exposed**.
- This is the closest public-API approximation to “single SIM” versus “dual SIM active”.

### What is not feasible with normal public app APIs

- You cannot determine whether a specific active plan is:
  - physical SIM
  - eSIM
  - which slot it belongs to
- You cannot enumerate inactive eSIM profiles.
- You cannot discover the total number of supported SIM slots or plan capacity.

### Practical wording used by this demo

To stay accurate, the app labels this as:

- **Single active subscription exposed**
- **Two active subscriptions exposed (dual active)**

It does **not** claim it can positively identify “physical SIM” vs “eSIM”, because public APIs do not expose that distinction to standard apps.

## Limitations

### Data that cannot be accessed by normal iOS apps

The following items are **not available** to ordinary App Store apps through public APIs:

- Phone number
- IMSI
- ICCID
- IMEI
- Serial number
- UDID
- Which SIM received a specific SMS
- Incoming SMS contents in a normal app
- Sender contact name for received SMS
- Whether a subscription is physical SIM or eSIM
- Inactive eSIM profiles
- Exact SIM insertion/removal events in a reliable, general-purpose way
- Cellular signal bars / precise modem diagnostics for general apps

### Why these limits exist

Apple restricts this data because of:

- user privacy
- anti-fingerprinting protections
- carrier/security boundaries
- platform policy decisions

In recent iOS releases, Apple has further reduced the usefulness of `CTCarrier` by deprecating it and allowing placeholder or static values.

## What the App Explicitly Does Not Try to Do

This project intentionally does **not** attempt to:

- use private APIs
- inspect SMS messages
- access phone numbers from the SIM
- access unique SIM identifiers
- differentiate physical SIM from eSIM
- access hidden modem or carrier internals

## Workarounds and Alternatives

If a product requirement depends on information iOS will not expose directly, these are the practical alternatives:

### Phone number

**Not available from iOS APIs**

Suggested workaround:

- Ask the user to enter their number
- Verify it with OTP / SMS code server-side

### Country or locale inference

If SIM country is not reliable or unavailable:

- use `Locale.current`
- use app onboarding
- use server-side account settings
- use `CoreLocation` if actual location is needed and the user grants location permission

### Device naming

On iOS 16+, `UIDevice.current.name` usually returns a generic value such as `iPhone`.

Suggested workaround:

- Let the user assign a display name inside your app
- Only request Apple’s special entitlement if your app truly meets their criteria

### Carrier-specific logic

If you need guaranteed carrier identification:

- do not depend on `CTCarrier` for critical flows on recent iOS
- prefer explicit user selection, backend configuration, or carrier-partner integrations

### SIM presence

There are newer CoreTelephony symbols related to SIM presence in Apple documentation, but for a normal public demo app this is not a robust replacement for the old carrier-based heuristics. This project therefore sticks to the broadly usable public APIs above and treats direct SIM-type detection as not generally available.

## Official References

### UIKit / Device

- [UIDevice](https://developer.apple.com/documentation/uikit/uidevice)
- [UIDevice.name](https://developer.apple.com/documentation/uikit/uidevice/name)
- [UIDevice.identifierForVendor](https://developer.apple.com/documentation/uikit/uidevice/1620059-identifierforvendor)
- [User-assigned device name entitlement](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.device-information.user-assigned-device-name)

### Core Telephony

- [Core Telephony](https://developer.apple.com/documentation/coretelephony)
- [CTTelephonyNetworkInfo](https://developer.apple.com/documentation/coretelephony/cttelephonynetworkinfo)
- [serviceSubscriberCellularProviders](https://developer.apple.com/documentation/coretelephony/cttelephonynetworkinfo/servicesubscribercellularproviders)
- [serviceSubscriberCellularProvidersDidUpdateNotifier](https://developer.apple.com/documentation/coretelephony/cttelephonynetworkinfo/servicesubscribercellularprovidersdidupdatenotifier)
- [serviceCurrentRadioAccessTechnology](https://developer.apple.com/documentation/coretelephony/cttelephonynetworkinfo/servicecurrentradioaccesstechnology)
- [dataServiceIdentifier](https://developer.apple.com/documentation/coretelephony/cttelephonynetworkinfo/dataserviceidentifier)
- [CTServiceRadioAccessTechnologyDidChangeNotification](https://developer.apple.com/documentation/coretelephony/ctserviceradioaccesstechnologydidchangenotification)
- [CTCellularData](https://developer.apple.com/documentation/coretelephony/ctcellulardata)
- [CTCarrier](https://developer.apple.com/documentation/coretelephony/ctcarrier)
- [CTSubscriber](https://developer.apple.com/documentation/coretelephony/ctsubscriber)

### Network

- [Network framework](https://developer.apple.com/documentation/network)
- [NWPathMonitor](https://developer.apple.com/documentation/network/nwpathmonitor)
- [NWPath](https://developer.apple.com/documentation/network/nwpath)

### Privacy / Platform Policy

- [User Privacy and Data Use](https://developer.apple.com/app-store/user-privacy-and-data-use/)
- [What’s new in privacy (WWDC)](https://developer.apple.com/videos/play/wwdc2022/10096/)

## Build and Run

1. Open `SIMResearch/SIMResearch.xcodeproj` in Xcode.
2. Select an iPhone running a recent iOS version.
3. Build and run the app.
4. Test on:
   - simulator
   - a Wi-Fi only device if available
   - a physical-SIM iPhone
   - an eSIM iPhone
   - a dual-active-line iPhone if available

## Expected Testing Behavior

### Simulator

- Carrier and radio information are usually unavailable.
- Network path information still works.
- Device values are mostly available.

### Real iPhone with cellular

- Some telephony values may appear.
- Carrier values may still be blank or placeholder on modern iOS due to deprecation/restriction.
- Radio access technology may show LTE / 5G when available.

### Dual-line iPhone

- The app may show two active exposed services.
- The app still cannot tell you which one is physical SIM vs eSIM.

## Summary

### What is feasible on iOS

- Read general device properties
- Read app-scoped vendor identifier
- Monitor network path status and interface usage
- Read some telephony service information through public CoreTelephony APIs
- Show radio access technology when iOS exposes it
- Approximate active subscription count by counting exposed services

### What is not feasible for ordinary apps

- Read phone number from the SIM
- Read IMSI, ICCID, IMEI, serial number, or UDID
- Reliably identify physical SIM vs eSIM
- Enumerate inactive eSIM profiles
- Read incoming SMS details in a normal app
- Determine which SIM received a message
- Depend on carrier metadata as a stable source on iOS 16+

### Bottom line

For a normal public iOS app, the best you can do is build a **best-effort diagnostic dashboard**. You can show:

- device info
- current network path characteristics
- any telephony/carrier values the system still exposes

But you must clearly communicate that modern iOS intentionally restricts many SIM and subscriber details for privacy and security reasons.
