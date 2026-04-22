import Foundation

protocol APIClientProtocol: Sendable {
    func send<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T
}
