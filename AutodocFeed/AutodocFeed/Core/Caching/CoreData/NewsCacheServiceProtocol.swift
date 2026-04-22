import Foundation

protocol NewsCacheServiceProtocol: Sendable {
    func cachedNews(page: Int, pageSize: Int) async -> [NewsItem]
    func save(news: [NewsItem], page: Int) async
    func clearAll() async
}
