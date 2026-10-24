import XCTest
import UIKit
@testable import ApartmentPopupDemo

final class PhotoCarouselIntegrationTests: XCTestCase {
    func testCarouselConfiguredAtZeroSizeRendersAfterItsContainerIsLaidOut() {
        let hostView = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 260))
        let carousel = PhotoCarouselView()
        let image = makeTestImage(color: .blue)
        carousel.translatesAutoresizingMaskIntoConstraints = false
        hostView.addSubview(carousel)
        NSLayoutConstraint.activate([
            carousel.leadingAnchor.constraint(equalTo: hostView.leadingAnchor),
            carousel.trailingAnchor.constraint(equalTo: hostView.trailingAnchor),
            carousel.topAnchor.constraint(equalTo: hostView.topAnchor),
            carousel.bottomAnchor.constraint(equalTo: hostView.bottomAnchor)
        ])

        carousel.setContent(.items([.image(image)]))
        hostView.layoutIfNeeded()

        let collectionView: UICollectionView = tryUnwrap(carousel.firstDescendant())
        collectionView.layoutIfNeeded()
        let cell = collectionView.cellForItem(at: IndexPath(item: 0, section: 0))
        let imageView: UIImageView = tryUnwrap(cell?.firstDescendant())
        XCTAssertEqual(cell?.bounds.size, collectionView.bounds.size)
        XCTAssertGreaterThan(cell?.bounds.width ?? 0, 0)
        XCTAssertTrue(imageView.image === image)
    }

    func testCarouselStatesAndInitialPageClamping() {
        let carousel = PhotoCarouselView(frame: CGRect(x: 0, y: 0, width: 282, height: 278.5))
        let collectionView: UICollectionView = tryUnwrap(carousel.firstDescendant())
        let pageControl: UIPageControl = tryUnwrap(carousel.firstDescendant())
        let pageLabel: UILabel = tryUnwrap(carousel.firstDescendant())

        for content in [PhotoCarouselContent.empty, .loading, .failure] {
            carousel.setContent(content)
            XCTAssertEqual(collectionView.dataSource?.collectionView(collectionView, numberOfItemsInSection: 0), 0)
            XCTAssertTrue(pageControl.isHidden)
            XCTAssertTrue(pageLabel.isHidden)
        }

        carousel.setContent(
            .items([.image(UIImage()), .url(URL(fileURLWithPath: "/tmp/missing.png"))]),
            initialPage: 99
        )

        XCTAssertEqual(collectionView.dataSource?.collectionView(collectionView, numberOfItemsInSection: 0), 2)
        XCTAssertEqual(pageControl.numberOfPages, 2)
        XCTAssertEqual(pageControl.currentPage, 1)
        XCTAssertEqual(pageLabel.text, "2 of 2")
    }

    func testCarouselReportsSelectionAndPageChanges() {
        let carousel = PhotoCarouselView(frame: CGRect(x: 0, y: 0, width: 282, height: 278.5))
        let delegate = CarouselDelegateSpy()
        let collectionView: UICollectionView = tryUnwrap(carousel.firstDescendant())
        carousel.delegate = delegate
        carousel.setContent(.items([.image(UIImage()), .image(UIImage())]))

        carousel.collectionView(collectionView, didSelectItemAt: IndexPath(item: 1, section: 0))
        collectionView.contentOffset.x = collectionView.bounds.width
        carousel.scrollViewDidScroll(collectionView)

        XCTAssertEqual(delegate.selectedIndex, 1)
        XCTAssertEqual(delegate.changedPage, 1)
    }

    func testPhotoCellDisplaysInMemoryImageWithoutCallingLoader() {
        let cell = PhotoCarouselCell(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let imageView: UIImageView = tryUnwrap(cell.firstDescendant())
        let image = UIImage()
        let loader = ControlledImageLoader()

        cell.configure(with: .image(image), imageLoader: loader)

        XCTAssertTrue(imageView.image === image)
        XCTAssertEqual(imageView.contentMode, .scaleAspectFill)
        XCTAssertEqual(loader.requestCount, 0)
    }

    func testPhotoCellShowsPlaceholderAndClearsItWhenReused() {
        let cell = PhotoCarouselCell(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let imageView: UIImageView = tryUnwrap(cell.firstDescendant())
        let loader = ControlledImageLoader()
        let url = URL(string: "https://example.com/photo.png")!

        cell.configure(
            with: .url(url),
            imageLoader: loader
        )

        XCTAssertTrue(imageView.image === PhotoCarouselCell.loadingPlaceholderImage)
        XCTAssertEqual(imageView.contentMode, .scaleAspectFit)

        cell.prepareForReuse()
        loader.succeedRequest(to: url, with: UIImage())

        XCTAssertNil(imageView.image)
    }

    func testCarouselReturnsURLCellWhileImageLoadIsPending() {
        let carousel = PhotoCarouselView(frame: CGRect(x: 0, y: 0, width: 282, height: 278.5))
        let collectionView: UICollectionView = tryUnwrap(carousel.firstDescendant())
        let loader = ControlledImageLoader()
        carousel.imageLoader = loader
        carousel.setContent(
            .items([.url(URL(string: "https://example.com/delayed.png")!)])
        )

        let cell = carousel.collectionView(
            collectionView,
            cellForItemAt: IndexPath(item: 0, section: 0)
        ) as? PhotoCarouselCell
        let imageView: UIImageView = tryUnwrap(cell?.firstDescendant())

        XCTAssertTrue(imageView.image === PhotoCarouselCell.loadingPlaceholderImage)
        loader.succeedAllRequests(with: UIImage())
    }

    @MainActor
    func testPhotoCellCancelsLoadingWhenReused() async {
        let started = expectation(description: "Loading started")
        let cancelled = expectation(description: "Loading cancelled")
        let loader = CancellationObservingImageLoader(started: started, cancelled: cancelled)
        let cell = PhotoCarouselCell(frame: CGRect(x: 0, y: 0, width: 100, height: 100))

        cell.configure(
            with: .url(URL(string: "https://example.com/photo.png")!),
            imageLoader: loader
        )
        await fulfillment(of: [started], timeout: 1)

        cell.prepareForReuse()

        await fulfillment(of: [cancelled], timeout: 1)
    }

    @MainActor
    func testLateCompletionCannotOverwriteReconfiguredCell() async {
        let loader = ControlledImageLoader()
        let cell = PhotoCarouselCell(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let imageView: UIImageView = tryUnwrap(cell.firstDescendant())
        let firstURL = URL(string: "https://example.com/first.png")!
        let secondURL = URL(string: "https://example.com/second.png")!
        let firstImage = makeTestImage(color: .red)
        let secondImage = makeTestImage(color: .blue)

        cell.configure(with: .url(firstURL), imageLoader: loader)
        await loader.waitForRequest(to: firstURL)
        cell.configure(with: .url(secondURL), imageLoader: loader)
        await loader.waitForRequest(to: secondURL)

        loader.succeedRequest(to: secondURL, with: secondImage)
        await waitUntil { imageView.image === secondImage }
        loader.succeedRequest(to: firstURL, with: firstImage)
        try? await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertTrue(imageView.image === secondImage)
    }

    @MainActor
    func testPhotoCellDisplaysFailureImage() async {
        let loader = ControlledImageLoader()
        let cell = PhotoCarouselCell(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let imageView: UIImageView = tryUnwrap(cell.firstDescendant())
        let url = URL(string: "https://example.com/missing.png")!

        cell.configure(with: .url(url), imageLoader: loader)
        await loader.waitForRequest(to: url)
        loader.failRequest(to: url)
        await waitUntil { imageView.image === PhotoCarouselCell.failureImage }

        XCTAssertEqual(imageView.contentMode, .scaleAspectFit)
    }

    func testDefaultImageLoaderCachesSuccessfulNetworkImages() async throws {
        let data = makeTestImage(color: .green).pngData()!
        let requestCount = LockedCounter()
        URLProtocolStub.requestHandler = { request in
            requestCount.increment()
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, data)
        }
        defer { URLProtocolStub.requestHandler = nil }

        let loader = makeNetworkImageLoader()
        let url = URL(string: "https://example.com/cached.png")!
        _ = try await loader.image(for: url)
        _ = try await loader.image(for: url)

        XCTAssertEqual(requestCount.value, 1)
    }

    func testDefaultImageLoaderDoesNotCacheFailures() async {
        let requestCount = LockedCounter()
        URLProtocolStub.requestHandler = { request in
            requestCount.increment()
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 404,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }
        defer { URLProtocolStub.requestHandler = nil }

        let loader = makeNetworkImageLoader()
        let url = URL(string: "https://example.com/missing.png")!
        for _ in 0..<2 {
            do {
                _ = try await loader.image(for: url)
                XCTFail("Expected the request to fail")
            } catch {
                XCTAssertEqual(error as? ImageLoadingError, .unsuccessfulStatusCode(404))
            }
        }

        XCTAssertEqual(requestCount.value, 2)
    }

    func testDefaultImageLoaderRejectsInvalidImageData() async {
        URLProtocolStub.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data("not an image".utf8))
        }
        defer { URLProtocolStub.requestHandler = nil }

        do {
            _ = try await makeNetworkImageLoader().image(
                for: URL(string: "https://example.com/invalid.png")!
            )
            XCTFail("Expected invalid image data to fail")
        } catch {
            XCTAssertEqual(error as? ImageLoadingError, .invalidImageData)
        }
    }

    func testDefaultImageLoaderDoesNotCacheCancelledRequest() async throws {
        let started = expectation(description: "Request started")
        let stopped = expectation(description: "Request stopped")
        CancellableURLProtocolStub.reset(started: started, stopped: stopped)
        defer { CancellableURLProtocolStub.reset() }

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [CancellableURLProtocolStub.self]
        let loader = DefaultImageLoader(session: URLSession(configuration: configuration))
        let url = URL(string: "https://example.com/cancelled.png")!
        let task = Task {
            try await loader.image(for: url)
        }

        await fulfillment(of: [started], timeout: 1)
        task.cancel()
        do {
            _ = try await task.value
            XCTFail("Expected the cancelled load to fail")
        } catch {
            XCTAssertTrue(task.isCancelled)
        }
        await fulfillment(of: [stopped], timeout: 1)

        CancellableURLProtocolStub.setResponseData(makeTestImage(color: .orange).pngData()!)
        _ = try await loader.image(for: url)

        XCTAssertEqual(CancellableURLProtocolStub.requestCount, 2)
    }

    func testDefaultImageLoaderLoadsLocalFileURL() async throws {
        let expectedData = makeTestImage(color: .purple).pngData()!
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("image-loader-test-(UUID().uuidString).png")
        try expectedData.write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }

        let image = try await DefaultImageLoader().image(for: url)

        XCTAssertNotNil(image.pngData())
    }

    private func makeNetworkImageLoader() -> DefaultImageLoader {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        return DefaultImageLoader(session: URLSession(configuration: configuration))
    }

    private func makeTestImage(color: UIColor) -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 2, height: 2)).image { context in
            color.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 2, height: 2))
        }
    }

    @MainActor
    private func waitUntil(
        timeout: TimeInterval = 1,
        condition: @escaping () -> Bool
    ) async {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition(), Date() < deadline {
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
        XCTAssertTrue(condition(), "Condition was not satisfied before the timeout")
    }

    private func tryUnwrap<T>(_ value: T?, file: StaticString = #filePath, line: UInt = #line) -> T {
        guard let value else {
            XCTFail("Expected a \(T.self) in the view hierarchy", file: file, line: line)
            fatalError("Missing expected view")
        }
        return value
    }
}

private final class ControlledImageLoader: ImageLoading {
    private typealias Continuation = CheckedContinuation<UIImage, Error>

    private let lock = NSLock()
    private var continuations: [URL: [Continuation]] = [:]

    var requestCount: Int {
        lock.withLock { continuations.values.reduce(0) { $0 + $1.count } }
    }

    func image(for url: URL) async throws -> UIImage {
        try await withCheckedThrowingContinuation { continuation in
            lock.withLock {
                continuations[url, default: []].append(continuation)
            }
        }
    }

    func waitForRequest(to url: URL) async {
        while lock.withLock({ continuations[url] == nil }) {
            await Task.yield()
        }
    }

    func succeedRequest(to url: URL, with image: UIImage) {
        takeContinuation(for: url)?.resume(returning: image)
    }

    func failRequest(to url: URL) {
        takeContinuation(for: url)?.resume(throwing: ImageLoadingError.invalidImageData)
    }

    func succeedAllRequests(with image: UIImage) {
        let pending = lock.withLock { () -> [Continuation] in
            let values = continuations.values.flatMap { $0 }
            continuations.removeAll()
            return values
        }
        pending.forEach { $0.resume(returning: image) }
    }

    private func takeContinuation(for url: URL) -> Continuation? {
        lock.withLock {
            guard var pending = continuations[url], !pending.isEmpty else { return nil }
            let continuation = pending.removeFirst()
            continuations[url] = pending.isEmpty ? nil : pending
            return continuation
        }
    }
}

private final class CancellationObservingImageLoader: ImageLoading {
    private let started: XCTestExpectation
    private let cancelled: XCTestExpectation

    init(started: XCTestExpectation, cancelled: XCTestExpectation) {
        self.started = started
        self.cancelled = cancelled
    }

    func image(for url: URL) async throws -> UIImage {
        started.fulfill()
        do {
            try await Task.sleep(nanoseconds: 5_000_000_000)
            return UIImage()
        } catch {
            cancelled.fulfill()
            throw error
        }
    }
}

private final class URLProtocolStub: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

private final class CancellableURLProtocolStub: URLProtocol {
    private static let lock = NSLock()
    private static var responseData: Data?
    private static var startedExpectation: XCTestExpectation?
    private static var stoppedExpectation: XCTestExpectation?
    private static var count = 0

    static var requestCount: Int {
        lock.withLock { count }
    }

    static func reset(
        started: XCTestExpectation? = nil,
        stopped: XCTestExpectation? = nil
    ) {
        lock.withLock {
            responseData = nil
            startedExpectation = started
            stoppedExpectation = stopped
            count = 0
        }
    }

    static func setResponseData(_ data: Data) {
        lock.withLock {
            responseData = data
            startedExpectation = nil
            stoppedExpectation = nil
        }
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        let state = Self.lock.withLock { () -> (Data?, XCTestExpectation?) in
            Self.count += 1
            return (Self.responseData, Self.startedExpectation)
        }
        state.1?.fulfill()

        guard let data = state.0 else { return }
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {
        Self.lock.withLock { Self.stoppedExpectation }?.fulfill()
    }
}

private final class LockedCounter {
    private let lock = NSLock()
    private var count = 0

    var value: Int {
        lock.withLock { count }
    }

    func increment() {
        lock.withLock {
            count += 1
        }
    }
}

private extension NSLock {
    func withLock<T>(_ operation: () -> T) -> T {
        lock()
        defer { unlock() }
        return operation()
    }
}

private final class CarouselDelegateSpy: PhotoCarouselViewDelegate {
    var selectedIndex: Int?
    var changedPage: Int?

    func photoCarouselView(_ carouselView: PhotoCarouselView, didSelect item: PhotoCarouselItem, at index: Int) {
        selectedIndex = index
    }

    func photoCarouselView(_ carouselView: PhotoCarouselView, didChangePageTo index: Int) {
        changedPage = index
    }
}

private extension UIView {
    func firstDescendant<T: UIView>(of type: T.Type = T.self) -> T? {
        if let match = self as? T {
            return match
        }

        for subview in subviews {
            if let match: T = subview.firstDescendant(of: type) {
                return match
            }
        }

        return nil
    }
}
