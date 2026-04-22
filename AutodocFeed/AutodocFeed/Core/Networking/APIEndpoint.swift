import Foundation

struct APIEndpoint {
    let path: String
    let method: String
    let queryItems: [URLQueryItem]

    init(path: String, method: String = "GET", queryItems: [URLQueryItem] = []) {
        self.path = path
        self.method = method
        self.queryItems = queryItems
    }

    static func news(page: Int, pageSize: Int = 15) -> APIEndpoint {
        APIEndpoint(path: "/api/news/\(page)/\(pageSize)")
    }
}
