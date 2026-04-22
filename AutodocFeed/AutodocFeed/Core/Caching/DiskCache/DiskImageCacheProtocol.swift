import Foundation

protocol DiskImageCacheProtocol: Sendable {
    func data(forKey key: String) async -> Data?
    func store(_ data: Data, forKey key: String) async
}
