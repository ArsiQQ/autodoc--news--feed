import Foundation
import CryptoKit

actor DiskImageCache: DiskImageCacheProtocol {

    // MARK: - Properties

    private let directory: URL
    private let maxSize: Int
    private let maxAge: TimeInterval
    private nonisolated(unsafe) let fileManager: FileManager

    // MARK: - Init

    init(
        maxSize: Int = 150 * 1024 * 1024,
        maxAge: TimeInterval = 7 * 24 * 3600
    ) {
        let fm = FileManager.default
        let caches = fm.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let dir = caches.appendingPathComponent("ImageCache", isDirectory: true)
        self.directory = dir
        self.maxSize = maxSize
        self.maxAge = maxAge
        self.fileManager = fm

        if !fm.fileExists(atPath: dir.path) {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
    }

    // MARK: - DiskImageCacheProtocol

    func data(forKey key: String) async -> Data? {
        let fileURL = fileURL(forKey: key)
        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }

        guard let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
              let modificationDate = attributes[.modificationDate] as? Date,
              Date().timeIntervalSince(modificationDate) < maxAge else {
            try? fileManager.removeItem(at: fileURL)
            return nil
        }

        try? fileManager.setAttributes(
            [.modificationDate: Date()],
            ofItemAtPath: fileURL.path
        )

        return try? Data(contentsOf: fileURL)
    }

    func store(_ data: Data, forKey key: String) async {
        let fileURL = fileURL(forKey: key)
        try? data.write(to: fileURL, options: .atomic)
        evictIfNeeded()
    }

    // MARK: - Private

    private func fileURL(forKey key: String) -> URL {
        let hash = SHA256.hash(data: Data(key.utf8))
        let fileName = hash.compactMap { String(format: "%02x", $0) }.joined()
        return directory.appendingPathComponent(fileName)
    }

    private func evictIfNeeded() {
        guard let files = try? fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey],
            options: .skipsHiddenFiles
        ) else { return }

        var totalSize = 0
        var fileInfos: [(url: URL, size: Int, date: Date)] = []

        for file in files {
            guard let values = try? file.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey]),
                  let size = values.fileSize,
                  let date = values.contentModificationDate else { continue }
            totalSize += size
            fileInfos.append((url: file, size: size, date: date))
        }

        guard totalSize > maxSize else { return }

        fileInfos.sort { $0.date < $1.date }

        for info in fileInfos {
            guard totalSize > maxSize else { break }
            try? fileManager.removeItem(at: info.url)
            totalSize -= info.size
        }
    }
}
