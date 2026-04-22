import Foundation

/// Represents all retrievable device-level information.
struct DeviceInfo {
    let name: String
    let model: String
    let localizedModel: String
    let systemName: String
    let systemVersion: String
    let identifierForVendor: String?
    let isMultitaskingSupported: Bool
    let userInterfaceIdiom: String
    let batteryLevel: Float
    let batteryState: String
    let screenBounds: String
    let screenScale: String
    let screenNativeScale: String
    let processorCount: Int
    let physicalMemory: String
    let systemUptime: String
    let preferredLanguages: [String]
    let currentLocale: String
    let timeZone: String
}
