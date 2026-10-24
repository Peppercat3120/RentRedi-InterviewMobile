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
