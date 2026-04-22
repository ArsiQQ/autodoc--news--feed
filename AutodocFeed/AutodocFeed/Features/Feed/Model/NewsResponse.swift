import Foundation

struct NewsResponse: Decodable {
    let news: [NewsItem]
    let totalCount: Int
}
