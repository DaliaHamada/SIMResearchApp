//
//  USSDLookupService.swift
//  SIMResearch
//
//  Drives the user-assisted USSD MSISDN lookup flow. Builds the
//  carrier-specific `tel://` URL, asks the system to open it, and
//  persists the MSISDN values the user copies back from the carrier's
//  USSD response.
//
//  iOS hard limits — read this before changing anything below
//  ----------------------------------------------------------
//  * `UIApplication.open(_:)` is the ONLY public way to dial a number.
//    It cannot be invoked from the background, it cannot bypass the
//    system call confirmation sheet, and it never returns the call
//    result to the calling app.
//  * The carrier's USSD response is rendered by SpringBoard / the
//    Phone app. There is no public CoreTelephony, CallKit, pasteboard
//    or accessibility API that exposes the response text. That is why
//    this service does not pretend to "capture" the number — only the
//    user can.
//  * USSD short codes that begin with `#` (Orange's `#119#`) are
//    routinely rejected by the `tel:` URL scheme. The dial method
//    reports back so the UI can fall back to a copy-to-clipboard
//    flow with manual-dial guidance.
//

import Foundation
import UIKit

/// Outcome of an attempt to open the system dialer with a USSD code.
enum USSDDialResult: Equatable {
    /// The system accepted the URL and presented the call confirmation
    /// sheet to the user. The carrier's response remains invisible to
    /// the app — only the user can read and report the number.
    case dialerPresented
    /// The URL was syntactically valid but iOS refused to open it
    /// (most commonly USSD codes starting with `#`). Fall back to
    /// copy-to-clipboard with manual-dial instructions.
    case dialerRefused
    /// The URL could not be constructed at all (programmer error).
    case malformedURL
}

/// User-assisted USSD MSISDN lookup. The class is intentionally
/// `final` and side-effect free apart from the `UIApplication.open`
/// call and the on-disk MSISDN store.
final class USSDLookupService {

    /// Storage backend for captured MSISDNs.
    private let store: MSISDNStore

    /// Application abstraction so tests can inject a fake. The default
    /// uses the live `UIApplication.shared`.
    private let application: USSDOpening

    init(store: MSISDNStore = .shared, application: USSDOpening = LiveUIApplication()) {
        self.store = store
        self.application = application
    }

    // MARK: - Dialing

    /// Builds the `tel://` URL for the carrier's USSD short code.
    /// `#` characters MUST be percent-encoded (`%23`); otherwise the
    /// rest of the URL is treated as a fragment and silently dropped
    /// by `URL`.
    func dialURL(for carrier: EgyptianCarrier) -> URL? {
        let code = carrier.ussdCode
        var encoded = ""
        for ch in code {
            switch ch {
            case "#": encoded.append("%23")
            case "*": encoded.append("*")
            default:
                if ch.isNumber {
                    encoded.append(ch)
                } else {
                    return nil
                }
            }
        }
        return URL(string: "tel://" + encoded)
    }

    /// Asks the system to open the dialer with the carrier's USSD
    /// pre-filled. The call ALWAYS shows the system confirmation
    /// sheet — there is no API path that bypasses it.
    @MainActor
    func dial(_ carrier: EgyptianCarrier, completion: @escaping (USSDDialResult) -> Void) {
        guard let url = dialURL(for: carrier) else {
            completion(.malformedURL)
            return
        }
        application.open(url) { success in
            completion(success ? .dialerPresented : .dialerRefused)
        }
    }

    // MARK: - Captured numbers

    /// All MSISDNs the user has saved, most recent first.
    func capturedEntries() -> [MSISDNEntry] {
        store.load().sorted { $0.capturedAt > $1.capturedAt }
    }

    /// Most recent captured MSISDN for `carrier`, or `nil`.
    func latestEntry(for carrier: EgyptianCarrier) -> MSISDNEntry? {
        capturedEntries().first { $0.carrier == carrier }
    }

    /// Persists a normalized MSISDN. Returns the stored entry on
    /// success; `nil` when the input cannot be parsed as an Egyptian
    /// mobile number.
    @discardableResult
    func saveCapturedNumber(_ raw: String, for carrier: EgyptianCarrier) -> MSISDNEntry? {
        guard let normalized = MSISDNNormalizer.normalizeEgyptian(raw) else { return nil }
        let entry = MSISDNEntry(carrier: carrier, msisdn: normalized)
        var current = store.load()
        current.append(entry)
        store.save(current)
        return entry
    }

    /// Removes every captured MSISDN.
    func clearAll() {
        store.save([])
    }
}

// MARK: - UIApplication seam

/// Minimal protocol the service depends on so tests can substitute
/// a stub for `UIApplication.shared`.
protocol USSDOpening {
    func open(_ url: URL, completion: @escaping (Bool) -> Void)
}

/// Live implementation that forwards to `UIApplication.shared`. The
/// completion handler is the only signal iOS gives us about whether
/// the URL was acceptable.
struct LiveUIApplication: USSDOpening {
    func open(_ url: URL, completion: @escaping (Bool) -> Void) {
        UIApplication.shared.open(url, options: [:], completionHandler: completion)
    }
}

// MARK: - On-disk store

/// Tiny `UserDefaults`-backed store for captured MSISDNs. Kept small
/// on purpose: this app is a research demo, not a contact manager.
final class MSISDNStore {
    static let shared = MSISDNStore()

    private let defaults: UserDefaults
    private let key = "SIMResearch.MSISDNStore.entries.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> [MSISDNEntry] {
        guard let data = defaults.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([MSISDNEntry].self, from: data)) ?? []
    }

    func save(_ entries: [MSISDNEntry]) {
        let data = (try? JSONEncoder().encode(entries)) ?? Data()
        defaults.set(data, forKey: key)
    }
}
