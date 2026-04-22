import Foundation

struct NewsItem: Decodable, Identifiable, Sendable {
    let id: Int
    let title: String
    let description: String
    let publishedDate: Date
    let url: String
    let fullUrl: URL
    let titleImageUrl: URL?
    let categoryType: String
}

extension NewsItem: @preconcurrency Hashable {}
