//
//  MSISDNLookup.swift
//  SIMResearch
//
//  Models for the "MSISDN via carrier USSD" tab.
//
//  Background
//  ----------
//  iOS does NOT allow an app to dial a USSD code, place a call, or read
//  a USSD response without the user's knowledge. The `tel:` URL scheme
//  always opens the system call confirmation sheet, cannot run from the
//  background, and the carrier's USSD reply is rendered by the system
//  Phone UI — third-party apps have zero programmatic access to it.
//
//  This model therefore describes a *user-assisted* lookup flow:
//  the app pre-fills the dialer with the carrier-specific USSD code,
//  the user confirms the call, reads the number returned by the
//  carrier, and types it back into the app for storage.
//

import Foundation

/// Egyptian mobile network operators supported by the USSD MSISDN
/// lookup tab. We intentionally do not try to auto-detect the carrier:
/// `CTCarrier` is deprecated since iOS 16 and returns placeholders, so
/// the user is presented with all four options and picks their own.
enum EgyptianCarrier: String, CaseIterable, Identifiable, Codable {
    case vodafone
    case etisalat
    case orange
    case we

    var id: String { rawValue }

    /// Human-readable carrier name.
    var displayName: String {
        switch self {
        case .vodafone: return "Vodafone"
        case .etisalat: return "Etisalat"
        case .orange:   return "Orange"
        case .we:       return "WE"
        }
    }

    /// Raw USSD short code as the user would type it on the dialer.
    /// Includes leading `*` or `#` and trailing `#`.
    var ussdCode: String {
        switch self {
        case .vodafone: return "*878#"
        case .etisalat: return "*947#"
        case .orange:   return "#119#"
        case .we:       return "*688#"
        }
    }

    /// SF Symbol used in the UI.
    var symbol: String {
        switch self {
        case .vodafone: return "v.circle.fill"
        case .etisalat: return "e.circle.fill"
        case .orange:   return "o.circle.fill"
        case .we:       return "w.circle.fill"
        }
    }

    /// `true` for codes that iOS reliably refuses to open through the
    /// `tel:` URL scheme. Codes starting with `#` (e.g. Orange's
    /// `#119#`) are routinely stripped or rejected by the dialer; the
    /// app falls back to copy-to-clipboard with manual-dial guidance.
    var requiresManualDial: Bool {
        ussdCode.hasPrefix("#")
    }

    /// Mobile Network Codes (MNC) historically allocated to the
    /// operator. Surfaced for reference only — `CTCarrier.mobileNetworkCode`
    /// is masked on iOS 16+ so we cannot use these to auto-pick the
    /// carrier at runtime.
    var mobileNetworkCodes: [String] {
        switch self {
        case .vodafone: return ["02"]
        case .etisalat: return ["03"]
        case .orange:   return ["01"]
        case .we:       return ["04"]
        }
    }
}

/// A single MSISDN value the user copied back from the carrier's USSD
/// response. Stored locally so the user can review the four results
/// after running each lookup.
struct MSISDNEntry: Identifiable, Codable, Equatable {
    let id: UUID
    let carrier: EgyptianCarrier
    let msisdn: String
    let capturedAt: Date

    init(id: UUID = UUID(), carrier: EgyptianCarrier, msisdn: String, capturedAt: Date = Date()) {
        self.id = id
        self.carrier = carrier
        self.msisdn = msisdn
        self.capturedAt = capturedAt
    }
}

// MARK: - MSISDN normalization

/// Lightweight Egyptian-MSISDN normalization. Accepts user-pasted
/// values such as "0100 123 4567", "+20 100 123 4567", "20 100 123 4567"
/// and returns either an E.164-style "+20XXXXXXXXXX" string or `nil`
/// when the input cannot be interpreted as a valid Egyptian mobile
/// number.
enum MSISDNNormalizer {

    /// Strip whitespace, dashes, parentheses; keep digits and an
    /// optional leading `+`.
    static func sanitize(_ raw: String) -> String {
        var out = ""
        for ch in raw {
            if ch == "+" && out.isEmpty {
                out.append(ch)
            } else if ch.isNumber {
                out.append(ch)
            }
        }
        return out
    }

    /// Attempts to convert `raw` into the canonical "+20XXXXXXXXXX"
    /// form. Returns `nil` when the digits do not match an Egyptian
    /// mobile number.
    ///
    /// Egyptian mobile numbers have:
    ///   * country code 20
    ///   * a 10-digit national subscriber number that begins with 1
    ///     (e.g. 10x, 11x, 12x, 15x).
    static func normalizeEgyptian(_ raw: String) -> String? {
        let cleaned = sanitize(raw)
        guard !cleaned.isEmpty else { return nil }

        let digits: String
        if cleaned.hasPrefix("+20") {
            digits = String(cleaned.dropFirst(3))
        } else if cleaned.hasPrefix("0020") {
            digits = String(cleaned.dropFirst(4))
        } else if cleaned.hasPrefix("20") && cleaned.count == 12 {
            digits = String(cleaned.dropFirst(2))
        } else if cleaned.hasPrefix("0") && cleaned.count == 11 {
            digits = String(cleaned.dropFirst())
        } else if cleaned.count == 10 {
            digits = cleaned
        } else {
            return nil
        }

        guard digits.count == 10, digits.first == "1" else { return nil }
        return "+20" + digits
    }
}
