import Foundation

enum CacheError: LocalizedError {
    case readFailed
    case writeFailed
    case storeNotLoaded

    var errorDescription: String? {
        switch self {
        case .readFailed:
            return "Не удалось прочитать данные из кэша"
        case .writeFailed:
            return "Не удалось записать данные в кэш"
        case .storeNotLoaded:
            return "Хранилище не загружено"
        }
    }
}
