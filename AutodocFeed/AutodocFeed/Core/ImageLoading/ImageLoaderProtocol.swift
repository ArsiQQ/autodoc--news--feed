import UIKit

protocol ImageLoaderProtocol: Sendable {
    func image(for url: URL, targetSize: CGSize, scale: CGFloat) async throws -> UIImage
    func thumbnail(for url: URL) async throws -> UIImage
    func cachedImage(for url: URL, targetSize: CGSize, scale: CGFloat) async -> UIImage?
}
