import Foundation

protocol NewsServiceProtocol: Sendable {
    func fetchNews(page: Int, pageSize: Int) async throws -> NewsResponse
}
