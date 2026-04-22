import Foundation

enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(statusCode: Int)
    case decodingFailed(Error)
    case transport(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Некорректный URL запроса"
        case .invalidResponse:
            return "Некорректный ответ сервера"
        case .serverError(let code):
            return "Ошибка сервера: \(code)"
        case .decodingFailed(let error):
            return "Ошибка декодирования: \(error.localizedDescription)"
        case .transport(let error):
            return "Сетевая ошибка: \(error.localizedDescription)"
        }
    }
}
