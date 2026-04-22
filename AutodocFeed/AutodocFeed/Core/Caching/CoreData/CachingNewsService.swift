import Foundation

final class CachingNewsService: NewsServiceProtocol {

    // MARK: - Properties

    private let networkService: NewsServiceProtocol
    private let cacheService: NewsCacheServiceProtocol

    // MARK: - Init

    init(networkService: NewsServiceProtocol, cacheService: NewsCacheServiceProtocol) {
        self.networkService = networkService
        self.cacheService = cacheService
    }

    // MARK: - NewsServiceProtocol

    func fetchNews(page: Int, pageSize: Int) async throws -> NewsResponse {
        do {
            let response = try await networkService.fetchNews(page: page, pageSize: pageSize)

            Task.detached(priority: .utility) { [cacheService] in
                await cacheService.save(news: response.news, page: page)
            }

            return response
        } catch {
            let cached = await cacheService.cachedNews(page: page, pageSize: pageSize)
            if !cached.isEmpty {
                return NewsResponse(news: cached, totalCount: 0)
            }
            throw error
        }
    }
}
