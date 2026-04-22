import UIKit
import ImageIO

actor ImageLoader: ImageLoaderProtocol {

    // MARK: - Properties

    private nonisolated(unsafe) let cache: NSCache<NSString, UIImage>
    private var tasks: [URL: Task<UIImage, Error>] = [:]
    private let session: URLSession
    private let diskCache: DiskImageCacheProtocol?

    // MARK: - Init

    init(
        session: URLSession = .shared,
        diskCache: DiskImageCacheProtocol? = nil,
        cacheCountLimit: Int = 200
    ) {
        self.session = session
        self.diskCache = diskCache
        let memCache = NSCache<NSString, UIImage>()
        memCache.countLimit = cacheCountLimit
        self.cache = memCache
    }

    // MARK: - ImageLoaderProtocol

    func image(for url: URL, targetSize: CGSize, scale: CGFloat) async throws -> UIImage {
        let key = cacheKey(url: url, targetSize: targetSize, scale: scale)

        if let cached = cache.object(forKey: key) {
            return cached
        }

        if let diskCache,
           let diskData = await diskCache.data(forKey: url.absoluteString) {
            guard let image = Self.decode(data: diskData, targetSize: targetSize, scale: scale) else {
                throw NetworkError.decodingFailed(CacheError.readFailed)
            }
            cache.setObject(image, forKey: key)
            return image
        }

        if let running = tasks[url] {
            return try await running.value
        }

        let task = Task<UIImage, Error>.detached(priority: .userInitiated) { [session, diskCache] in
            let (data, response) = try await session.data(from: url)
            if let http = response as? HTTPURLResponse,
               !(200..<300).contains(http.statusCode) {
                throw NetworkError.serverError(statusCode: http.statusCode)
            }

            await diskCache?.store(data, forKey: url.absoluteString)

            guard let image = Self.decode(data: data, targetSize: targetSize, scale: scale) else {
                throw NetworkError.decodingFailed(CacheError.readFailed)
            }
            return image
        }
        tasks[url] = task

        do {
            let image = try await task.value
            tasks[url] = nil
            cache.setObject(image, forKey: key)
            return image
        } catch {
            tasks[url] = nil
            throw error
        }
    }

    func cachedImage(for url: URL, targetSize: CGSize, scale: CGFloat) async -> UIImage? {
        let key = cacheKey(url: url, targetSize: targetSize, scale: scale)
        return cache.object(forKey: key)
    }

    func thumbnail(for url: URL) async throws -> UIImage {
        let thumbSize = CGSize(width: 32, height: 32)
        let scale: CGFloat = 1
        let key = cacheKey(url: url, targetSize: thumbSize, scale: scale)

        if let cached = cache.object(forKey: key) {
            return cached
        }

        if let diskCache,
           let diskData = await diskCache.data(forKey: url.absoluteString) {
            guard let thumb = Self.decode(data: diskData, targetSize: thumbSize, scale: scale) else {
                throw NetworkError.decodingFailed(CacheError.readFailed)
            }
            cache.setObject(thumb, forKey: key)
            return thumb
        }

        let task = Task<UIImage, Error>.detached(priority: .userInitiated) { [session, diskCache] in
            let (data, response) = try await session.data(from: url)
            if let http = response as? HTTPURLResponse,
               !(200..<300).contains(http.statusCode) {
                throw NetworkError.serverError(statusCode: http.statusCode)
            }
            await diskCache?.store(data, forKey: url.absoluteString)
            guard let thumb = Self.decode(data: data, targetSize: thumbSize, scale: scale) else {
                throw NetworkError.decodingFailed(CacheError.readFailed)
            }
            return thumb
        }

        let thumb = try await task.value
        cache.setObject(thumb, forKey: key)
        return thumb
    }

    // MARK: - Private

    private func cacheKey(url: URL, targetSize: CGSize, scale: CGFloat) -> NSString {
        "\(url.absoluteString)|\(Int(targetSize.width))x\(Int(targetSize.height))@\(scale)" as NSString
    }

    private nonisolated static func decode(data: Data, targetSize: CGSize, scale: CGFloat) -> UIImage? {
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions) else {
            return nil
        }
        let maxPixel = max(targetSize.width, targetSize.height) * scale
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel
        ]
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }
        return UIImage(cgImage: cgImage, scale: scale, orientation: .up)
    }
}
