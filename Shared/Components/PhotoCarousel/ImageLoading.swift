import Foundation
import UIKit

protocol ImageLoading: AnyObject {
    func image(for url: URL) async throws -> UIImage
}

enum ImageLoadingError: Error, Equatable {
    case invalidResponse
    case unsuccessfulStatusCode(Int)
    case invalidImageData
}

final class DefaultImageLoader: ImageLoading {
    static let shared = DefaultImageLoader()

    private let session: URLSession
    private let cache: NSCache<NSURL, UIImage>

    init(
        session: URLSession = .shared,
        cache: NSCache<NSURL, UIImage> = NSCache()
    ) {
        self.session = session
        self.cache = cache
    }

    func image(for url: URL) async throws -> UIImage {
        try Task.checkCancellation()

        let cacheKey = url as NSURL
        if let cachedImage = cache.object(forKey: cacheKey) {
            return cachedImage
        }

        let data: Data
        if url.isFileURL {
            data = try await loadFileData(from: url)
        } else {
            let result = try await session.data(from: url)
            guard let response = result.1 as? HTTPURLResponse else {
                throw ImageLoadingError.invalidResponse
            }
            guard (200...299).contains(response.statusCode) else {
                throw ImageLoadingError.unsuccessfulStatusCode(response.statusCode)
            }
            data = result.0
        }

        try Task.checkCancellation()
        let image = try await decodeImage(from: data)
        try Task.checkCancellation()
        cache.setObject(image, forKey: cacheKey)
        return image
    }

    private func loadFileData(from url: URL) async throws -> Data {
        let task = Task.detached(priority: .utility) {
            try Task.checkCancellation()
            let data = try Data(contentsOf: url)
            try Task.checkCancellation()
            return data
        }

        return try await withTaskCancellationHandler {
            try await task.value
        } onCancel: {
            task.cancel()
        }
    }

    private func decodeImage(from data: Data) async throws -> UIImage {
        let task = Task.detached(priority: .utility) {
            try Task.checkCancellation()
            guard let image = UIImage(data: data) else {
                throw ImageLoadingError.invalidImageData
            }
            try Task.checkCancellation()
            return image
        }

        return try await withTaskCancellationHandler {
            try await task.value
        } onCancel: {
            task.cancel()
        }
    }
}
