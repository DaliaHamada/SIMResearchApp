import Foundation

protocol DeviceNetworkInfoProviding {
    func fetchSnapshot() async -> DeviceNetworkSnapshot
}
