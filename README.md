## 🎯 Research Objectives

This R&D project answers critical questions about iOS SIM and SMS capabilities:

1. Can we detect the count of SIMs on a device?
2. Can we detect SMS sender information (number and name)?
3. Can we identify which SIM received an SMS?
4. Can we retrieve SIM operator information?
5. Can we get the phone number from SIM?
6. Can we detect SIM removal or updates?
7. Can we detect specific SIM changes and get detailed information?
8. Can we detect inactive eSIM profiles?

---

## 🔍 Research Findings

### 1️⃣ Can we detect the count of SIMs on the device?

**Status:** ⚠️ **LIMITED** (Deprecated in iOS 16+)

**Answer:**
- **iOS 15 and earlier:** YES, using `serviceSubscriberCellularProviders.count`
- **iOS 16+:** API deprecated, returns nil values with **no replacement**

**Details:**
```swift
let networkInfo = CTTelephonyNetworkInfo()
if let providers = networkInfo.serviceSubscriberCellularProviders {
    let simCount = providers.count
    print("Active cellular slots: \(simCount)")
}
```

**Limitations:**
- Cannot differentiate between physical SIM and eSIM
- Only detects **active** cellular plans, not total capacity
- CTCarrier deprecated in iOS 16 with no replacement
- Simulator always returns nil

**Official Reference:**
- [CTTelephonyNetworkInfo | Apple Developer](https://developer.apple.com/documentation/coretelephony/cttelephonynetworkinfo)
- [serviceSubscriberCellularProviders | Apple Developer](https://developer.apple.com/documentation/coretelephony/cttelephonynetworkinfo/servicesubscribercellularproviders)

---

### 2️⃣ When receiving SMS, can we detect the sender's number and name?

**Status:** ❌ **NOT POSSIBLE** (for regular apps)

**Answer:**
- **Regular apps:** Cannot access incoming SMS at all
- **SMS Filter Extension:** Can access sender **number only** (not name)
- **Sender name:** Not exposed to any app or extension

**Details:**
- iOS restricts SMS access for privacy and security
- Only limited SMS filtering extensions allowed
- Extension sees metadata only (sender number, not message body or contact name)

**What's Available:**
```swift
// In SMS Filter Extension only (ILMessageFilterExtension)
func handle(_ queryRequest: ILMessageFilterQueryRequest) async -> ILMessageFilterQueryResponse {
    let sender = queryRequest.sender // Phone number only
    // Cannot access contact name or message body
}
```

**Official Reference:**
- [SMS and MMS Message Filtering | Apple Developer](https://developer.apple.com/documentation/identitylookup/sms-and-mms-message-filtering)
- [Privacy Guidelines | Apple Developer](https://developer.apple.com/design/human-interface-guidelines/privacy)

---

### 3️⃣ When receiving SMS, can we detect which SIM received that SMS?

**Status:** ❌ **NOT POSSIBLE**

**Answer:**
- No API exposes which SIM (in dual-SIM devices) received an SMS
- iOS 17 added **user-facing** filtering by SIM in Messages app
- Developers cannot access this information programmatically

**User Feature (iOS 17+):**
- Users can filter messages by SIM in Settings
- Labels like "Primary" or "Secondary" visible to users only
- Not accessible via any API

**Official Reference:**
- [Use Dual SIM on iPhone | Apple Support](https://support.apple.com/guide/iphone/use-dual-sim-iph9c5776d3c/ios)

---

### 4️⃣ Can we get the SIM operator (Orange, Vodafone, etc.)?

**Status:** ⚠️ **DEPRECATED** (iOS 16+)

**Answer:**
- **iOS 15 and earlier:** YES, using CTCarrier
- **iOS 16+:** Deprecated, returns nil with **no replacement**

**Details:**
```swift
let networkInfo = CTTelephonyNetworkInfo()
if let carriers = networkInfo.serviceSubscriberCellularProviders {
    for (_, carrier) in carriers {
        print("Carrier: \(carrier.carrierName ?? "N/A")") // Returns nil on iOS 16+
        print("MCC: \(carrier.mobileCountryCode ?? "N/A")")
        print("MNC: \(carrier.mobileNetworkCode ?? "N/A")")
    }
}
```

**What You Could Get (iOS 15 and earlier):**
- Carrier name (e.g., "Vodafone", "Orange")
- Mobile Country Code (MCC)
- Mobile Network Code (MNC)
- ISO Country Code
- VoIP support status

**iOS 16+ Deprecation:**
```
@available(iOS, introduced: 4.0, deprecated: 16.0, message: "Deprecated with no replacement")
```

**Official Reference:**
- [CTCarrier | Apple Developer](https://developer.apple.com/documentation/coretelephony/ctcarrier) (Deprecated)

---

### 5️⃣ Can we get the phone number from SIM?

**Status:** ❌ **NOT POSSIBLE**

**Answer:**
- No public API provides access to device phone number
- Privacy restriction by Apple
- Not all carriers store phone number on SIM

**User Access:**
- Users can view in Settings > Phone > "My Number"
- Not accessible programmatically to apps

**Workaround:**
- Ask user to manually enter their phone number
- Use server-side verification (OTP)

**Official Reference:**
- [User Privacy and Data Use | Apple Developer](https://developer.apple.com/app-store/user-privacy-and-data-use/)

---

### 6️⃣ Can we detect generic SIM removal or update?

**Status:** ❌ **NOT POSSIBLE**

**Answer:**
- No public API for SIM removal/insertion detection
- No system notifications or callbacks
- Privacy and security restriction

**System Behavior:**
- iOS shows "No SIM" in status bar (system level only)
- Apps cannot detect or respond to these events

**Official Reference:**
- [Core Telephony | Apple Developer](https://developer.apple.com/documentation/coretelephony)

---

### 7️⃣ Can we detect specific SIM removal or change? What details can we get?

**Status:** ⚠️ **RUNTIME ONLY** (while app is running)

**Answer:**
- Can detect changes **only while app is actively running**
- Cannot detect changes when app is closed or backgrounded
- No unique SIM identifiers available (ICCID, IMSI)

**Details:**
```swift
let networkInfo = CTTelephonyNetworkInfo()
networkInfo.subscriberCellularProviderDidUpdateNotifier = { carrier in
    print("Carrier changed (runtime only)")
    // Note: carrier properties return nil on iOS 16+
}
```

**What You Can Get (iOS 15 and earlier):**
- Notification when carrier info changes
- Carrier name, MCC, MNC (if available)

**What You CANNOT Get:**
- Phone number
- ICCID (SIM card unique ID)
- IMSI (subscriber identity)
- Exact change timestamp when app not running

**Official Reference:**
- [subscriberCellularProviderDidUpdateNotifier | Apple Developer](https://developer.apple.com/documentation/coretelephony/cttelephonynetworkinfo/subscribercellularproviderdidupdatenotifier)

---

### 8️⃣ Can we detect inactive eSIM?

**Status:** ❌ **NOT POSSIBLE**

**Answer:**
- No API to query inactive eSIM profiles
- Only active cellular plans visible to apps
- Users can check in Settings > Cellular

**User Method:**
1. Go to Settings > Cellular
2. Inactive eSIMs show "No Service" or "Not in Use"
3. Not programmatically accessible

**Official Reference:**
- [About eSIM on iPhone | Apple Support](https://support.apple.com/en-us/118669)
---
