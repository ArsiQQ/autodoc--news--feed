import Foundation

final class NewsService: NewsServiceProtocol {
    private let client: APIClientProtocol

    init(client: APIClientProtocol) {
        self.client = client
    }

    func fetchNews(page: Int, pageSize: Int = 15) async throws -> NewsResponse {
        try await client.send(.news(page: page, pageSize: pageSize))
    }
}
