# Device & Network Demo (iOS SwiftUI)

Demo iOS application (SwiftUI, latest iOS SDK) that collects and displays all **publicly accessible** device, SIM/carrier, and network information on real iPhones.

> This project intentionally avoids private APIs and explicitly marks data that is unavailable due to iOS privacy/security restrictions.

## 1) Overview

### What the app does
- Collects device information from `UIDevice`
- Collects SIM/carrier information from `CoreTelephony`
- Collects connectivity/network path information from `Network` (`NWPathMonitor`)
- Displays results in 3 sections:
  - **Device Info**
  - **SIM / Carrier Info**
  - **Network Info**
- Clearly labels each data point with:
  - API source
  - Availability state (Available / Limited / Unavailable)
  - Notes about restrictions and deprecations

### Key features
- SwiftUI dashboard designed for real iPhones (single SIM, dual SIM, physical SIM + eSIM combinations)
- Graceful handling of nil/missing data (`Not available`)
- Explicit SIM detection caveats (active plans are inferable; SIM type is not reliably exposed)
- Strong separation of concerns:
  - `Services` for data collection
  - `ViewModels` for state and refresh logic
  - `Views` for presentation
  - `Models` for typed snapshot representation

## 2) Project Structure

```text
SIMResearch/
  SIMResearch/
    App/
      SIMResearchApp.swift
    Models/
      DataAvailability.swift
      DeviceNetworkSnapshot.swift
      InfoField.swift
    Services/
      DeviceNetworkInfoProviding.swift
      DefaultDeviceNetworkInfoProvider.swift
    ViewModels/
      DeviceNetworkViewModel.swift
    Views/
      DeviceNetworkDashboardView.swift
      Components/
        AvailabilityBadge.swift
        InfoFieldRow.swift
        SectionCard.swift
```

## 3) Data Points Matrix

The table below documents each displayed data point, example values, API used, and practical availability.

| Data | Example Value | API | Availability |
|---|---|---|---|
| Device Name | `John’s iPhone` | `UIDevice.current.name` | Usually available |
| System Name | `iOS` | `UIDevice.current.systemName` | Available |
| System Version | `18.2` | `UIDevice.current.systemVersion` | Available |
| Device Model | `iPhone` | `UIDevice.current.model` | Available (generic) |
| Localized Model | `iPhone` | `UIDevice.current.localizedModel` | Available |
| Vendor Identifier | `D66E...-...` | `UIDevice.current.identifierForVendor` | Limited (can reset in lifecycle scenarios) |
| Active subscription count (inferred) | `2` | `CTTelephonyNetworkInfo.serviceSubscriberCellularProviders.count` | Limited (active plans only) |
| SIM Summary | `Multiple active cellular plans detected` | Derived from CoreTelephony map count | Limited |
| Carrier Name | `Vodafone` | `CTCarrier.carrierName` | Limited; deprecated in iOS 16+, may be nil |
| MCC | `602` | `CTCarrier.mobileCountryCode` | Limited; deprecated in iOS 16+, may be nil |
| MNC | `02` | `CTCarrier.mobileNetworkCode` | Limited; deprecated in iOS 16+, may be nil |
| ISO Country Code | `eg` | `CTCarrier.isoCountryCode` | Limited; deprecated in iOS 16+, may be nil |
| VoIP Supported | `Yes` / `No` | `CTCarrier.allowsVOIP` | Limited; deprecated in iOS 16+ |
| Radio Access Technology | `0000000100000001: CTRadioAccessTechnologyNR` | `CTTelephonyNetworkInfo.serviceCurrentRadioAccessTechnology` | Limited; may be nil |
| Network Path Status | `Satisfied` | `NWPathMonitor.currentPath.status` | Available |
| Uses Cellular | `Yes` / `No` | `NWPath.usesInterfaceType(.cellular)` | Available |
| Uses Wi‑Fi | `Yes` / `No` | `NWPath.usesInterfaceType(.wifi)` | Available |
| Is Expensive | `Yes` / `No` | `NWPath.isExpensive` | Available |
| Is Constrained | `Yes` / `No` | `NWPath.isConstrained` | Available |

### Availability legend
- **Available**: expected to work in normal runtime conditions.
- **Limited**: may be nil, deprecated, context-dependent, or only inferable.
- **Unavailable**: not exposed to regular iOS apps via public APIs.

## 4) What is NOT possible on iOS (public APIs)

The following are **not accessible** in regular App Store apps:

1. **Phone number from SIM/device**
   - No public API returns the line number.
   - Workaround: ask user input + verify via OTP.

2. **IMSI / ICCID / SIM serial details**
   - Blocked for privacy/security.
   - No public entitlement for third-party apps.

3. **Exact SIM type classification (physical SIM vs eSIM)**
   - Public APIs do not provide a reliable flag per subscription.
   - Workaround: infer active-plan count only (not SIM technology type).

4. **Inactive eSIM profile enumeration**
   - Not available through public APIs.
   - Users can view in Settings manually.

5. **Incoming SMS content, sender name, or which SIM received SMS**
   - Regular apps cannot read user SMS inbox.
   - SMS Filter extensions are heavily constrained and still do not provide full messaging access.

6. **Reliable background SIM insertion/removal history**
   - No full lifecycle SIM event API for apps.

### Why these limits exist
- User privacy protection
- Telecom security model
- Platform policy constraints for App Store distribution

## 5) Permissions and Runtime Behavior

- This app uses public frameworks only:
  - `UIKit` (`UIDevice`)
  - `CoreTelephony`
  - `Network`
- No special user permission dialog is required for these specific reads.
- Some values can still be absent depending on:
  - Simulator vs real device
  - Airplane mode / Wi‑Fi-only state
  - iOS version behavior (especially CoreTelephony deprecations)
  - Carrier provisioning

## 6) Build and Run

1. Open `SIMResearch/SIMResearch.xcodeproj`
2. Select a real iPhone target (recommended over simulator)
3. Build and run with latest Xcode/iOS SDK
4. Tap refresh icon to recapture current snapshot

## 7) References (Official Documentation)

### CoreTelephony
- `CTTelephonyNetworkInfo`  
  https://developer.apple.com/documentation/coretelephony/cttelephonynetworkinfo
- `serviceSubscriberCellularProviders`  
  https://developer.apple.com/documentation/coretelephony/cttelephonynetworkinfo/servicesubscribercellularproviders
- `serviceCurrentRadioAccessTechnology`  
  https://developer.apple.com/documentation/coretelephony/cttelephonynetworkinfo/servicecurrentradioaccesstechnology
- `CTCarrier` (deprecated iOS 16+)  
  https://developer.apple.com/documentation/coretelephony/ctcarrier

### UIDevice (UIKit)
- `UIDevice`  
  https://developer.apple.com/documentation/uikit/uidevice
- `identifierForVendor`  
  https://developer.apple.com/documentation/uikit/uidevice/1620059-identifierforvendor

### Network framework
- `NWPathMonitor`  
  https://developer.apple.com/documentation/network/nwpathmonitor
- `NWPath`  
  https://developer.apple.com/documentation/network/nwpath

### Privacy / Policy
- User Privacy and Data Use  
  https://developer.apple.com/app-store/user-privacy-and-data-use/

## 8) Summary

### Feasible on iOS (public APIs)
- Device-level metadata (name/model/system/version, vendor ID)
- Limited carrier metadata (often deprecated/nil on modern iOS)
- Radio access technology (context-dependent)
- Current network path characteristics (cellular/wifi/expensive/constrained)
- Approximate active subscription count inference

### Not feasible on iOS (public APIs)
- Phone number retrieval
- IMSI/ICCID access
- Definite physical SIM vs eSIM classification
- Inactive eSIM access
- SMS inbox inspection / sender name / SIM-specific SMS routing

### Suggested alternatives
- Ask the user for phone number and verify with OTP
- Use carrier-agnostic server-side onboarding flow
- For telecom workflows, rely on user-provided settings screenshots/instructions when OS data is inaccessible
