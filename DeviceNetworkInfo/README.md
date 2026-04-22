# DeviceNetworkInfo — iOS Device & Network Information Demo

A SwiftUI demo application that collects and displays all accessible device, carrier/SIM, and network information available through public iOS APIs. Designed to run on real iPhones with SIM, eSIM, or dual SIM configurations.

## Key Features

- **Device Information** — Model, OS version, identifier, battery, screen specs, processor, memory, locale, and more.
- **SIM / eSIM Detection** — Detects single SIM, dual SIM, and multi-subscription configurations.
- **Carrier Information** — Carrier name, MCC, MNC, ISO country code, VoIP support (subject to iOS 16+ deprecations).
- **Radio Access Technology** — Current cellular technology per service (2G/3G/LTE/5G NR).
- **Network Status** — Wi-Fi detection, IP addresses, expensive/constrained connection flags, IPv4/IPv6 support.
- **Network Interfaces** — Full list of active network interfaces with addresses via `getifaddrs()`.
- **Graceful Degradation** — Handles missing, restricted, or deprecated data with clear UI indicators.

## Requirements

- **Xcode 15.0+**
- **iOS 16.0+** deployment target
- **Swift 5.9+**
- Physical iPhone recommended (SIM/eSIM features return empty data on simulators)

## Project Structure

```
DeviceNetworkInfo/
├── DeviceNetworkInfo.xcodeproj/
│   └── project.pbxproj
└── DeviceNetworkInfo/
    ├── App/
    │   └── DeviceNetworkInfoApp.swift        # @main entry point
    ├── Models/
    │   ├── DeviceInfo.swift                  # Device data model
    │   ├── CarrierInfo.swift                 # Carrier & SIM configuration models
    │   ├── NetworkInfo.swift                 # Network & interface models
    │   └── InfoRow.swift                     # Generic key-value display model
    ├── Services/
    │   ├── DeviceInfoService.swift           # UIDevice / ProcessInfo data collection
    │   ├── CarrierInfoService.swift          # CoreTelephony carrier data collection
    │   └── NetworkInfoService.swift          # NWPathMonitor / getifaddrs / Wi-Fi data
    ├── ViewModels/
    │   ├── DeviceInfoViewModel.swift         # Device info → UI rows
    │   ├── CarrierInfoViewModel.swift        # Carrier info → UI rows
    │   └── NetworkInfoViewModel.swift        # Network info → UI rows
    ├── Views/
    │   ├── ContentView.swift                 # Root view with all sections
    │   ├── DeviceInfoView.swift              # Device info section
    │   ├── CarrierInfoView.swift             # SIM/Carrier section
    │   ├── NetworkInfoView.swift             # Network section
    │   └── InfoRowView.swift                 # Reusable key-value row component
    ├── Assets.xcassets/                      # Asset catalog
    ├── DeviceNetworkInfo.entitlements        # Wi-Fi info entitlement
    └── Info.plist                            # App configuration
```

## Architecture

The app follows the **MVVM (Model-View-ViewModel)** pattern:

- **Models** — Plain data structures representing device, carrier, and network information.
- **Services** — Stateless classes that interface with Apple frameworks to collect raw data.
- **ViewModels** — `@ObservableObject` classes that transform service data into display-ready `InfoRow` arrays.
- **Views** — SwiftUI views that bind to ViewModels and render the UI.

---

## Data Points Reference

### Device Information

| Data Point | Example Value | API | Availability |
|---|---|---|---|
| Device Name | "iPhone" | `UIDevice.current.name` | Always available; returns generic name on iOS 16+ for privacy |
| Model | "iPhone" | `UIDevice.current.model` | Always available |
| Localized Model | "iPhone" | `UIDevice.current.localizedModel` | Always available |
| System Name | "iOS" | `UIDevice.current.systemName` | Always available |
| System Version | "17.4" | `UIDevice.current.systemVersion` | Always available |
| Identifier for Vendor | "A1B2C3D4-..." | `UIDevice.current.identifierForVendor` | Available; resets when all vendor apps are removed |
| User Interface Idiom | "iPhone" | `UIDevice.current.userInterfaceIdiom` | Always available |
| Multitasking Support | "Supported" | `UIDevice.current.isMultitaskingSupported` | Always available |
| Battery Level | "85%" | `UIDevice.current.batteryLevel` | Requires `isBatteryMonitoringEnabled = true` |
| Battery State | "Charging" | `UIDevice.current.batteryState` | Requires `isBatteryMonitoringEnabled = true` |
| Screen Size | "393 × 852 pts" | `UIScreen.main.bounds` | Always available |
| Screen Scale | "3.0x" | `UIScreen.main.scale` | Always available |
| Native Scale | "3.0x" | `UIScreen.main.nativeScale` | Always available |
| Processor Count | "6" | `ProcessInfo.processInfo.processorCount` | Always available |
| Physical Memory | "6.0 GB" | `ProcessInfo.processInfo.physicalMemory` | Always available |
| System Uptime | "2h 15m 30s" | `ProcessInfo.processInfo.systemUptime` | Always available |
| Preferred Languages | "en-US, fr-FR" | `Locale.preferredLanguages` | Always available |
| Locale | "en_US" | `Locale.current.identifier` | Always available |
| Time Zone | "America/New_York" | `TimeZone.current.identifier` | Always available |

### SIM / Carrier Information

| Data Point | Example Value | API | Availability |
|---|---|---|---|
| SIM Configuration | "Dual SIM" | Inferred from `serviceSubscriberCellularProviders` count | Available on physical devices |
| Active Subscriptions | "2" | `CTTelephonyNetworkInfo().serviceSubscriberCellularProviders?.count` | Available |
| Data Service Identifier | "0000000100000001" | `CTTelephonyNetworkInfo().dataServiceIdentifier` | Available |
| Carrier Name | "AT&T" | `CTCarrier.carrierName` | **Deprecated iOS 16+** — returns placeholder |
| Mobile Country Code (MCC) | "310" | `CTCarrier.mobileCountryCode` | **Deprecated iOS 16+** — returns "65535" |
| Mobile Network Code (MNC) | "410" | `CTCarrier.mobileNetworkCode` | **Deprecated iOS 16+** — returns "65535" |
| ISO Country Code | "us" | `CTCarrier.isoCountryCode` | **Deprecated iOS 16+** — returns "--" |
| Allows VoIP | "Yes" | `CTCarrier.allowsVOIP` | **Deprecated iOS 16+** |

### Network Information

| Data Point | Example Value | API | Availability |
|---|---|---|---|
| Radio Access Technology | "LTE (4G)" | `CTTelephonyNetworkInfo().serviceCurrentRadioAccessTechnology` | Available on cellular-capable devices |
| 5G NR / NR NSA | "5G NR" | `CTRadioAccessTechnologyNR` / `CTRadioAccessTechnologyNRNSA` | iOS 14.1+ |
| Connected to Wi-Fi | "Yes" | `NWPathMonitor` — `path.usesInterfaceType(.wifi)` | Always available |
| Wi-Fi SSID | "MyNetwork" | `CNCopyCurrentNetworkInfo` / `NEHotspotNetwork` | Requires entitlement + location permission; deprecated iOS 16+ |
| Wi-Fi BSSID | "AA:BB:CC:DD:EE:FF" | `CNCopyCurrentNetworkInfo` | Same restrictions as SSID |
| IPv4 Address | "192.168.1.42" | `getifaddrs()` | Always available |
| IPv6 Address | "fe80::1" | `getifaddrs()` | Always available |
| Expensive Connection | "Yes" | `NWPath.isExpensive` | Always available |
| Constrained Connection | "No" | `NWPath.isConstrained` | Always available |
| Supports IPv4 | "Yes" | `NWPath.supportsIPv4` | Always available |
| Supports IPv6 | "Yes" | `NWPath.supportsIPv6` | Always available |
| Network Interfaces | "en0 (IPv4): 192.168.1.42" | `getifaddrs()` | Always available |

---

## Limitations — Data That CANNOT Be Accessed

The following data points are **not accessible** on iOS due to Apple's privacy policies and API restrictions:

| Data | Reason | Since |
|---|---|---|
| **Phone Number** | Apple removed access to the phone number for privacy reasons. There is no public API to retrieve the device's own phone number. | iOS 4+ |
| **IMSI** (International Mobile Subscriber Identity) | Subscriber identity is considered highly sensitive. No public API exists. Carriers can access it server-side. | Never available |
| **IMEI** (International Mobile Equipment Identity) | Apple removed `UIDevice.uniqueIdentifier` (which returned UDID, not IMEI) in iOS 5. IMEI has never been accessible via public APIs. | Never available |
| **ICCID** (SIM Serial Number) | The SIM card's integrated circuit card identifier is not exposed by any public framework. | Never available |
| **UDID** (Unique Device Identifier) | Deprecated in iOS 5 and removed in iOS 7. Replaced by `identifierForVendor` and `ASIdentifierManager`. | iOS 7+ |
| **Serial Number** | Not accessible via public APIs. Was briefly available through private IOKit calls, which Apple blocked. | Never publicly available |
| **SIM Slot Type** (Physical vs eSIM) | No public API distinguishes between physical SIM and eSIM. You can only detect the number of active subscriptions. | N/A |
| **Signal Strength** (dBm / ASU) | Not available through any public API. Previously accessible via private `CTGetSignalStrength()`, which was removed. | Never publicly available |
| **Cell Tower Info** (LAC, Cell ID) | Cell tower information is not exposed by public APIs. Available only to carrier apps with special entitlements. | Never publicly available |
| **Wi-Fi MAC Address** | Since iOS 7, Wi-Fi MAC returns a fixed value (`02:00:00:00:00:00`). Private/randomized MAC is not accessible. | iOS 7+ |
| **Bluetooth MAC Address** | Not accessible via public APIs. | Never available |
| **Carrier Info (iOS 16+)** | `CTCarrier` class deprecated; properties return placeholder values ("--", "65535"). No replacement API provided by Apple. | iOS 16+ |

### Workarounds and Alternatives

| Inaccessible Data | Possible Workaround |
|---|---|
| Phone Number | Ask the user to input it manually, or use a verification service (SMS OTP via Firebase, Twilio, etc.) |
| IMEI / Serial | MDM (Mobile Device Management) solutions can access these for managed enterprise devices |
| Device Identity | Use `identifierForVendor` (per-vendor) or `ASIdentifierManager` (advertising, user-resettable) |
| Carrier Name (iOS 16+) | No workaround; the data is simply no longer available to third-party apps |
| Signal Strength | No workaround via public APIs; some network testing apps use `NetworkExtension` framework for limited metrics |
| Cell Tower Info | No workaround; carrier-privileged apps (with Apple-issued entitlements) may access this data |
| SIM Type (physical vs eSIM) | No reliable detection; you can only count active subscriptions |

---

## Frameworks and APIs Used

### CoreTelephony Framework
Provides access to cellular service information including carrier details and radio access technology.

- [`CTTelephonyNetworkInfo`](https://developer.apple.com/documentation/coretelephony/cttelephonynetworkinfo) — Central class for telephony information.
- [`CTCarrier`](https://developer.apple.com/documentation/coretelephony/ctcarrier) — Carrier properties (deprecated iOS 16+).
- [`serviceSubscriberCellularProviders`](https://developer.apple.com/documentation/coretelephony/cttelephonynetworkinfo/3024512-servicesubscribercellularprovide) — Per-service carrier info.
- [`serviceCurrentRadioAccessTechnology`](https://developer.apple.com/documentation/coretelephony/cttelephonynetworkinfo/3024511-servicecurrentradioaccesstechnol) — Current RAT per service.
- [`dataServiceIdentifier`](https://developer.apple.com/documentation/coretelephony/cttelephonynetworkinfo/3024510-dataserviceidentifier) — Identifies the data service.
- [Radio Access Technology Constants](https://developer.apple.com/documentation/coretelephony/cttelephonynetworkinfo/radio_access_technology_constants) — LTE, 5G NR, etc.

### UIKit — UIDevice
Provides basic device information.

- [`UIDevice`](https://developer.apple.com/documentation/uikit/uidevice) — Device model, name, system version, battery, etc.
- [`identifierForVendor`](https://developer.apple.com/documentation/uikit/uidevice/1620059-identifierforvendor) — Per-vendor unique identifier.

### Foundation — ProcessInfo
System-level information.

- [`ProcessInfo`](https://developer.apple.com/documentation/foundation/processinfo) — Processor count, physical memory, system uptime.

### UIKit — UIScreen
Display information.

- [`UIScreen`](https://developer.apple.com/documentation/uikit/uiscreen) — Screen bounds, scale factor, native scale.

### Network Framework — NWPathMonitor
Modern network path monitoring.

- [`NWPathMonitor`](https://developer.apple.com/documentation/network/nwpathmonitor) — Monitor network path changes.
- [`NWPath`](https://developer.apple.com/documentation/network/nwpath) — Connection type, expensive/constrained flags, IP version support.

### SystemConfiguration — CaptiveNetwork
Wi-Fi information (deprecated).

- [`CNCopyCurrentNetworkInfo`](https://developer.apple.com/documentation/systemconfiguration/1614126-cncopycurrentnetworkinfo) — SSID and BSSID (requires entitlement + location permission; deprecated iOS 14+).

### POSIX — getifaddrs
Low-level network interface enumeration.

- [`getifaddrs()`](https://man7.org/linux/man-pages/man3/getifaddrs.3.html) — Enumerate network interfaces and their IP addresses.

---

## Setup Instructions

1. **Clone the repository** and open `DeviceNetworkInfo.xcodeproj` in Xcode.
2. **Set your Development Team** in the project's Signing & Capabilities tab.
3. **Update the Bundle Identifier** if needed (default: `com.demo.DeviceNetworkInfo`).
4. **For Wi-Fi SSID access** (optional):
   - Add the "Access WiFi Information" capability in Xcode (already in the entitlements file).
   - Request location permission at runtime (the Info.plist already contains `NSLocationWhenInUseUsageDescription`).
5. **Build and run** on a physical iPhone for full functionality.

> **Note:** Running on the iOS Simulator will show device info and network interfaces, but SIM/carrier data and cellular radio information will be empty since the simulator has no telephony hardware.

---

## Summary

### What IS Feasible on iOS

- Retrieve device model, OS version, screen specs, processor/memory info, battery status.
- Obtain a per-vendor device identifier (`identifierForVendor`).
- Detect the number of active SIM/eSIM subscriptions.
- Read carrier name, MCC, MNC, and ISO country code (pre-iOS 16 only).
- Determine the current radio access technology (2G through 5G NR).
- Detect Wi-Fi vs cellular connection type, expensive/constrained status.
- Enumerate network interfaces and IP addresses.
- Retrieve Wi-Fi SSID/BSSID (with proper entitlements and location permission).

### What is NOT Possible and Why

- **Phone number, IMSI, ICCID, IMEI, serial number** — Apple's privacy-first approach prevents apps from accessing hardware identifiers that could be used for tracking or fingerprinting.
- **Signal strength, cell tower info** — Reserved for carrier-privileged apps; no public API exists.
- **Physical SIM vs eSIM distinction** — Apple provides no API to determine the SIM slot type.
- **Carrier metadata on iOS 16+** — `CTCarrier` is deprecated with no replacement, as Apple continues to restrict carrier information access for user privacy.
- **Wi-Fi MAC address** — Returns a fixed value since iOS 7; private MAC randomization prevents tracking.

These restrictions align with Apple's commitment to user privacy and prevention of device fingerprinting. For enterprise/MDM scenarios, managed device APIs provide additional data points not available to standard App Store applications.

---

## License

This project is provided as a demo/reference implementation. Use it freely for learning and development purposes.
