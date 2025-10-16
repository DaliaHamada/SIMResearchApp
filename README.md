# iOS SIM & SMS R&D Project

## Overview
This R&D project investigates what SIM and SMS information can be accessed on iOS devices through official Apple APIs.

---

## R&D Questions & Findings

### ✅ 1. Can we detect count of SIMs on the device?
**Status:** ❌ **NOT POSSIBLE**

**Reason:**
- Apple does not expose any public API to directly count SIM cards (physical or eSIM)
- The `CTTelephonyNetworkInfo.serviceSubscriberCellularProviders` returns carrier info but not guaranteed SIM count
- Available only to system apps or MDM with special entitlements

---

### ✅ 2. When receive SMS, can we detect the sender number and name?
**Status:** ⚠️ **PARTIALLY POSSIBLE** (sender number only)

**Reason:**
- Regular apps: **CANNOT** read incoming SMS at all (privacy/security)
- SMS Filter Extension: Can access **sender number only** via `ILMessageFilterQueryRequest`
- Sender name from Contacts: **NOT EXPOSED** to extensions or apps

**Implementation:**
- Requires creating an SMS Filter Extension target
- User must manually enable the extension in Settings > Messages > Unknown & Spam

---

### ✅ 3. When receive SMS, can we detect which SIM received that SMS?
**Status:** ❌ **NOT POSSIBLE**

**Reason:**
- Apple's `ILMessageFilterExtension` API does not provide SIM slot information
- No public API exposes which SIM (in dual-SIM devices) received an SMS

---

### ✅ 4. Can we get the SIM operator (Orange, Vodafone, etc)?
**Status:** ✅ **YES** (with limitations)

**Reason:**
- Use `CTTelephonyNetworkInfo` from CoreTelephony framework
- Returns `CTCarrier` with carrier name, country code, MNC, MCC
- Works on real devices only (not Simulator)
- iOS 12+ supports multiple carriers via `serviceSubscriberCellularProviders`

**Implementation:**
```swift
let networkInfo = CTTelephonyNetworkInfo()
if let providers = networkInfo.serviceSubscriberCellularProviders {
    for (key, carrier) in providers {
        print("Carrier: \(carrier.carrierName ?? "Unknown")")
    }
}
```

---

### ✅ 5. Can we get phone number from SIM?
**Status:** ❌ **NOT POSSIBLE**

**Reason:**
- No public API provides device phone number
- CoreTelephony does not expose phone numbers
- Privacy restriction by Apple
- Some carriers don't store phone number on SIM

**Note:**
- MDM solutions with special profiles may access this
- Regular App Store apps cannot

---

### ✅ 6. Can we detect generic SIM removal or update?
**Status:** ❌ **NOT POSSIBLE**

**Reason:**
- No public API or notification for SIM status changes
- No callback when SIM is removed or inserted
- Background app refresh doesn't help (no trigger event)

---

### ✅ 7. Can we detect specific SIM removal or change? What details can we get?
**Status:** ❌ **NOT POSSIBLE**

**Reason:**
- Same as #6 - no SIM change detection APIs
- Cannot track which specific SIM was removed/changed
- No details available about SIM hardware changes

**Workaround (unreliable):**
- Poll carrier info periodically and compare (battery drain)
- Only detects carrier changes, not physical SIM changes

---

## What This Sample App Demonstrates

### ✅ Implemented Features:
1. **Carrier Information Display**
   - Carrier name (e.g., "Vodafone", "Orange")
   - Country code (ISO code)
   - Mobile Network Code (MNC)
   - Mobile Country Code (MCC)
   - Support for multiple SIMs (dual-SIM devices)

2. **SMS Filter Extension** (Optional)
   - Demonstrates access to sender phone number
   - Shows filtering capabilities
   - Must be enabled manually in iOS Settings

3. **Professional SwiftUI UI**
   - Clean, modern interface
   - List view with carrier details
   - Refresh capability
   - Error handling

### ❌ NOT Possible (Documented):
- SIM count detection
- Phone number retrieval
- SMS sender name
- SIM slot identification for SMS
- SIM removal/change detection

---

## Project Structure

//

---

## Testing

### Testing Carrier Info:
1. **Must test on REAL device** (not Simulator)
2. Build and run the app
3. View carrier information on main screen
4. For dual-SIM testing, use device with 2 active SIMs

### Testing SMS Filter Extension:
1. Build and install app with extension
2. Go to **Settings** → **Messages** → **Unknown & Spam**
3. Enable your app's filter extension
4. Send test SMS to device
5. Check Xcode console for sender number logs

---

## References

- [CoreTelephony Framework](https://developer.apple.com/documentation/coretelephony)
- [CTCarrier](https://developer.apple.com/documentation/coretelephony/ctcarrier)
- [SMS Filter Extension](https://developer.apple.com/documentation/identitylookup)
- [ILMessageFilterExtension](https://developer.apple.com/documentation/identitylookup/ilmessagefilterextension)

---
