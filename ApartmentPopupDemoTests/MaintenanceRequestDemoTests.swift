import XCTest
import UIKit
@testable import ApartmentPopupDemo

final class MaintenanceRequestPresentationBuilderTests: XCTestCase {
    private let builder = MaintenanceRequestPresentationBuilder()

    func testBuildFormatsDisplayValuesAndPreservesPhotoOrder() {
        let firstURL = URL(string: "https://example.com/one.png")!
        let secondURL = URL(string: "https://example.com/two.png")!
        let request = makeMaintenanceRequest(photoURLs: [firstURL, secondURL])

        let content = builder.build(request: request)

        XCTAssertEqual(content.navigationTitle, "Maintenance Request")
        XCTAssertEqual(content.titleText, "Leaking Kitchen Sink")
        XCTAssertEqual(content.statusText, "Status: Open")
        XCTAssertEqual(content.locationText, "Location: Kitchen")
        XCTAssertEqual(content.submittedDateText, "Submitted: October 23, 2026")
        XCTAssertEqual(content.detailsHeadingText, "Description")
        XCTAssertEqual(content.detailsText, "Water is dripping beneath the sink.")

        guard case .items(let items) = content.carouselContent else {
            return XCTFail("Expected carousel items")
        }
        let mappedURLs = items.compactMap { item -> URL? in
            guard case .url(let url) = item else { return nil }
            return url
        }
        XCTAssertEqual(mappedURLs, [firstURL, secondURL])
    }

    func testBuildUsesEmptyCarouselContentWhenRequestHasNoPhotos() {
        let content = builder.build(request: makeMaintenanceRequest(photoURLs: []))

        guard case .empty = content.carouselContent else {
            return XCTFail("Expected empty carousel content")
        }
    }
}

final class MaintenanceRequestViewTests: XCTestCase {
    func testConfigureAppliesContentToLabelsAndCarousel() {
        let view = MaintenanceRequestView()
        let photoURLs = [
            URL(string: "https://example.com/one.png")!,
            URL(string: "https://example.com/two.png")!
        ]
        let content = MaintenanceRequestPresentationBuilder().build(
            request: makeMaintenanceRequest(photoURLs: photoURLs)
        )

        view.configure(with: content)

        XCTAssertEqual(view.accessibilityIdentifier, "maintenanceRequestScreen")
        XCTAssertEqual(label(in: view, identifier: "maintenanceRequestTitle").text, content.titleText)
        XCTAssertEqual(label(in: view, identifier: "maintenanceRequestStatus").text, content.statusText)
        XCTAssertEqual(label(in: view, identifier: "maintenanceRequestLocation").text, content.locationText)
        XCTAssertEqual(
            label(in: view, identifier: "maintenanceRequestSubmittedDate").text,
            content.submittedDateText
        )
        XCTAssertEqual(label(in: view, identifier: "maintenanceRequestDetails").text, content.detailsText)

        let carousel = carousel(in: view)
        let collectionView: UICollectionView = tryUnwrap(carousel.firstDescendant())
        let pageControl: UIPageControl = tryUnwrap(carousel.firstDescendant())
        let pageLabel: UILabel = tryUnwrap(carousel.firstDescendant())
        XCTAssertEqual(collectionView.dataSource?.collectionView(collectionView, numberOfItemsInSection: 0), 2)
        XCTAssertEqual(pageControl.numberOfPages, 2)
        XCTAssertEqual(pageControl.currentPage, 0)
        XCTAssertEqual(pageLabel.text, "1 of 2")
    }

    func testConfigureCanReplaceItemsWithEmptyContent() {
        let view = MaintenanceRequestView()
        let builder = MaintenanceRequestPresentationBuilder()
        view.configure(with: builder.build(request: makeMaintenanceRequest(
            photoURLs: [URL(string: "https://example.com/photo.png")!]
        )))

        view.configure(with: builder.build(request: makeMaintenanceRequest(photoURLs: [])))

        let carousel = carousel(in: view)
        let collectionView: UICollectionView = tryUnwrap(carousel.firstDescendant())
        let pageControl: UIPageControl = tryUnwrap(carousel.firstDescendant())
        let pageLabel: UILabel = tryUnwrap(carousel.firstDescendant())
        XCTAssertEqual(collectionView.dataSource?.collectionView(collectionView, numberOfItemsInSection: 0), 0)
        XCTAssertTrue(pageControl.isHidden)
        XCTAssertTrue(pageLabel.isHidden)
    }
}

final class MaintenanceRequestViewControllerTests: XCTestCase {
    func testControllerInstallsAndConfiguresMaintenanceView() {
        let request = makeMaintenanceRequest(
            photoURLs: [URL(string: "https://example.com/photo.png")!]
        )
        let controller = MaintenanceRequestViewController(request: request)

        controller.loadViewIfNeeded()

        XCTAssertTrue(controller.view is MaintenanceRequestView)
        XCTAssertEqual(controller.title, "Maintenance Request")
        XCTAssertEqual(label(in: controller.view, identifier: "maintenanceRequestTitle").text, request.title)
        XCTAssertEqual(label(in: controller.view, identifier: "maintenanceRequestStatus").text, "Status: Open")
        XCTAssertNotNil(carousel(in: controller.view))
    }
}

private func makeMaintenanceRequest(photoURLs: [URL]) -> MaintenanceRequest {
    MaintenanceRequest(
        title: "Leaking Kitchen Sink",
        status: "Open",
        location: "Kitchen",
        submittedDateText: "October 23, 2026",
        details: "Water is dripping beneath the sink.",
        photoURLs: photoURLs
    )
}

private func carousel(in view: UIView) -> PhotoCarouselView {
    tryUnwrap(
        view.firstDescendant(
            of: PhotoCarouselView.self,
            accessibilityIdentifier: "maintenancePhotoCarousel"
        )
    )
}

private func label(in view: UIView, identifier: String) -> UILabel {
    tryUnwrap(
        view.firstDescendant(
            of: UILabel.self,
            accessibilityIdentifier: identifier
        )
    )
}

private func tryUnwrap<T>(
    _ value: T?,
    file: StaticString = #filePath,
    line: UInt = #line
) -> T {
    guard let value else {
        XCTFail("Expected a \(T.self) in the view hierarchy", file: file, line: line)
        fatalError("Missing expected view")
    }
    return value
}

final class DemoMenuNavigationTests: XCTestCase {
    func testMenuButtonsAreAccessibleAndRouteToInjectedDestinations() {
        let apartmentDestination = UIViewController()
        let maintenanceDestination = UIViewController()
        let menu = DemoMenuViewController(
            makeApartmentDemo: { apartmentDestination },
            makeMaintenanceDemo: { maintenanceDestination }
        )
        let navigationController = UINavigationController(rootViewController: menu)

        menu.loadViewIfNeeded()

        XCTAssertEqual(menu.apartmentButton.accessibilityIdentifier, "openApartmentDemoButton")
        XCTAssertEqual(menu.apartmentButton.configuration?.title, "Apartment Popup")
        XCTAssertEqual(menu.maintenanceButton.accessibilityIdentifier, "openMaintenanceDemoButton")
        XCTAssertEqual(menu.maintenanceButton.configuration?.title, "Maintenance Request")

        menu.apartmentButton.sendActions(for: .touchUpInside)
        XCTAssertTrue(navigationController.topViewController === apartmentDestination)

        navigationController.popViewController(animated: false)
        menu.maintenanceButton.sendActions(for: .touchUpInside)
        XCTAssertTrue(navigationController.topViewController === maintenanceDestination)
    }
}

private extension UIView {
    func firstDescendant<T: UIView>(
        of type: T.Type = T.self,
        accessibilityIdentifier: String? = nil
    ) -> T? {
        if let match = self as? T,
           accessibilityIdentifier == nil || match.accessibilityIdentifier == accessibilityIdentifier {
            return match
        }

        for subview in subviews {
            if let match: T = subview.firstDescendant(
                of: type,
                accessibilityIdentifier: accessibilityIdentifier
            ) {
                return match
            }
        }
        return nil
    }
}
