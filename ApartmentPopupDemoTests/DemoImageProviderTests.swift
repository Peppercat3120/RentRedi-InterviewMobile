import XCTest
@testable import ApartmentPopupDemo

final class DemoImageProviderTests: XCTestCase {
    private var appBundle: Bundle {
        Bundle(for: ApartmentPopupViewController.self)
    }

    func testApartmentImageURLsResolveBundledPNGResourcesInDisplayOrder() throws {
        let urls = DemoImageProvider.apartmentImageURLs(bundle: appBundle)

        XCTAssertEqual(urls.map(\.lastPathComponent), [
            "apartment-living-room.png",
            "apartment-kitchen.png",
            "apartment-bedroom.png"
        ])
        try assertValidBundledPNGs(urls)
    }

    func testMaintenanceImageURLsResolveBundledPNGResourcesInDisplayOrder() throws {
        let urls = DemoImageProvider.maintenanceImageURLs(bundle: appBundle)

        XCTAssertEqual(urls.map(\.lastPathComponent), [
            "maintenance-under-sink.png",
            "maintenance-cabinet-base.png",
            "maintenance-water-stain.png"
        ])
        try assertValidBundledPNGs(urls)
    }

    func testAllDemoImageURLsAreDistinctNonemptyFilesDecodableByProductionLoader() async throws {
        let urls = DemoImageProvider.apartmentImageURLs(bundle: appBundle)
            + DemoImageProvider.maintenanceImageURLs(bundle: appBundle)

        XCTAssertEqual(urls.count, 6)
        XCTAssertEqual(Set(urls.map(\.standardizedFileURL)).count, 6)

        let loader = DefaultImageLoader()
        for url in urls {
            let values = try url.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey])
            XCTAssertEqual(values.isRegularFile, true, "Expected a regular file at \(url.path)")
            XCTAssertGreaterThan(values.fileSize ?? 0, 0, "Expected a nonempty file at \(url.path)")

            let image = try await loader.image(for: url)
            XCTAssertGreaterThan(image.size.width, 0, "Expected a decodable image at \(url.path)")
            XCTAssertGreaterThan(image.size.height, 0, "Expected a decodable image at \(url.path)")
        }
    }

    private func assertValidBundledPNGs(
        _ urls: [URL],
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        XCTAssertEqual(urls.count, 3, file: file, line: line)

        let pngSignature = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
        for url in urls {
            XCTAssertTrue(url.isFileURL, file: file, line: line)
            let data = try Data(contentsOf: url)
            XCTAssertEqual(data.prefix(pngSignature.count), pngSignature, file: file, line: line)
        }
    }
}
