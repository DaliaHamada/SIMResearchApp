import Foundation

/// A generic key-value row used for display in the UI.
struct InfoRow: Identifiable {
    let id = UUID()
    let label: String
    let value: String
    let detail: String?

    init(label: String, value: String, detail: String? = nil) {
        self.label = label
        self.value = value
        self.detail = detail
    }
}
