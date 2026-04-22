import Foundation

struct InfoField: Identifiable {
    let title: String
    let value: String
    let apiName: String
    let availability: DataAvailability
    let note: String?

    var id: String {
        "\(title)|\(apiName)"
    }
}
