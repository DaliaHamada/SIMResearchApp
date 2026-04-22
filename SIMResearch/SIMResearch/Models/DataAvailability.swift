import Foundation

enum DataAvailability {
    case available
    case limited
    case unavailable

    var label: String {
        switch self {
        case .available:
            return "Available"
        case .limited:
            return "Limited"
        case .unavailable:
            return "Unavailable"
        }
    }

    var colorHex: String {
        switch self {
        case .available:
            return "#1C9E4E"
        case .limited:
            return "#C97E00"
        case .unavailable:
            return "#B42318"
        }
    }

}
