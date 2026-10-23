import XCTest
import UIKit
@testable import ApartmentPopupDemo

final class MaintenanceRequestDemoTests: XCTestCase {
    func testScreenRendersRequestAndConfiguresSharedCarousel() {
        let request = MaintenanceRequest(
            title: "Leaking Kitchen Sink",
            status: "Open",
            location: "Kitchen",
            submittedDateText: "October 23, 2026",
            details: "Water is dripping beneath the sink.",
            photoURLs: [
                URL(string: "https://example.com/one.png")!,
                URL(string: "https://example.com/two.png")!,
                URL(string: "https://example.com/three.png")!
            ]
        )
        let controller = MaintenanceRequestViewController(request: request)

        controller.loadViewIfNeeded()

        XCTAssertEqual(controller.title, "Maintenance Request")
        XCTAssertEqual(label(in: controller, identifier: "maintenanceRequestTitle").text, request.title)
        XCTAssertEqual(label(in: controller, identifier: "maintenanceRequestStatus").text, "Status: Open")
        XCTAssertEqual(label(in: controller, identifier: "maintenanceRequestLocation").text, "Location: Kitchen")
        XCTAssertEqual(
            label(in: controller, identifier: "maintenanceRequestSubmittedDate").text,
            "Submitted: October 23, 2026"
        )
        XCTAssertEqual(label(in: controller, identifier: "maintenanceRequestDetails").text, request.details)

        let carousel = carousel(in: controller)
        let collectionView: UICollectionView = tryUnwrap(carousel.firstDescendant())
        let pageControl: UIPageControl = tryUnwrap(carousel.firstDescendant())
        let pageLabel: UILabel = tryUnwrap(carousel.firstDescendant())
        XCTAssertEqual(collectionView.dataSource?.collectionView(collectionView, numberOfItemsInSection: 0), 3)
        XCTAssertEqual(pageControl.numberOfPages, 3)
        XCTAssertEqual(pageControl.currentPage, 0)
        XCTAssertEqual(pageLabel.text, "1 of 3")
    }

    func testScreenConfiguresEmptyCarouselWhenRequestHasNoPhotos() {
        let request = MaintenanceRequest(
            title: "Loose Door Handle",
            status: "Open",
            location: "Front Door",
            submittedDateText: "October 23, 2026",
            details: "The inside handle is loose.",
            photoURLs: []
        )
        let controller = MaintenanceRequestViewController(request: request)

        controller.loadViewIfNeeded()

        let carousel = carousel(in: controller)
        let collectionView: UICollectionView = tryUnwrap(carousel.firstDescendant())
        let pageControl: UIPageControl = tryUnwrap(carousel.firstDescendant())
        let pageLabel: UILabel = tryUnwrap(carousel.firstDescendant())
        XCTAssertEqual(collectionView.dataSource?.collectionView(collectionView, numberOfItemsInSection: 0), 0)
        XCTAssertTrue(pageControl.isHidden)
        XCTAssertTrue(pageLabel.isHidden)
    }

    private func carousel(in controller: UIViewController) -> PhotoCarouselView {
        tryUnwrap(
            controller.view.firstDescendant(
                of: PhotoCarouselView.self,
                accessibilityIdentifier: "maintenancePhotoCarousel"
            )
        )
    }

    private func label(in controller: UIViewController, identifier: String) -> UILabel {
        tryUnwrap(
            controller.view.firstDescendant(
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
