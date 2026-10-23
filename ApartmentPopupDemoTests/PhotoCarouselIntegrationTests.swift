import XCTest
import UIKit
@testable import ApartmentPopupDemo

final class PhotoCarouselIntegrationTests: XCTestCase {
    func testPopupShowsURLsInReusableCarousel() {
        let popup = ApartmentPopupView(frame: CGRect(x: 0, y: 0, width: 414, height: 896))
        popup.applicationPhotosUrls = [
            URL(fileURLWithPath: "/tmp/apartment-photo-1.png"),
            URL(fileURLWithPath: "/tmp/apartment-photo-2.png")
        ]

        popup.showAndUpdateApplicationUnitAndPropertyPhotos()
        flushMainQueue()

        let carousel = popup.applicationPhotoCarousel!
        let collectionView: UICollectionView = tryUnwrap(carousel.firstDescendant())
        let pageControl: UIPageControl = tryUnwrap(carousel.firstDescendant())
        let pageLabel: UILabel = tryUnwrap(carousel.firstDescendant())

        XCTAssertFalse(carousel.isHidden)
        XCTAssertTrue(popup.applicationInviteImage.isHidden)
        XCTAssertFalse(popup.applicationPopupRegion.isHidden)
        XCTAssertEqual(collectionView.dataSource?.collectionView(collectionView, numberOfItemsInSection: 0), 2)
        XCTAssertEqual(pageControl.numberOfPages, 2)
        XCTAssertEqual(pageControl.currentPage, 0)
        XCTAssertEqual(pageLabel.text, "1 of 2")
    }

    func testPopupShowsDefaultInviteAndClearsCarousel() {
        let popup = ApartmentPopupView(frame: CGRect(x: 0, y: 0, width: 414, height: 896))
        popup.tenantCardSubmission = DemoTenantCardSubmission(
            address: "123 Maple Street",
            unitID: "4B",
            city: "Austin",
            state: "TX",
            zip: "78701"
        )
        popup.applicationPhotosUrls = [URL(fileURLWithPath: "/tmp/apartment-photo.png")]
        popup.showAndUpdateApplicationUnitAndPropertyPhotos()
        flushMainQueue()

        popup.showDefaultApplicationInvite()
        flushMainQueue()

        let carousel = popup.applicationPhotoCarousel!
        let collectionView: UICollectionView = tryUnwrap(carousel.firstDescendant())
        let pageControl: UIPageControl = tryUnwrap(carousel.firstDescendant())

        XCTAssertTrue(carousel.isHidden)
        XCTAssertFalse(popup.applicationInviteImage.isHidden)
        XCTAssertTrue(popup.applicationPopupRegion.isHidden)
        XCTAssertTrue(pageControl.isHidden)
        XCTAssertEqual(collectionView.dataSource?.collectionView(collectionView, numberOfItemsInSection: 0), 0)
        XCTAssertEqual(
            popup.applicationPopupStreetAddress.text,
            "You have been invited to Apply to 123 Maple Street, 4B, Austin, TX 78701"
        )
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

    func testPhotoCellClearsImageWhenReused() {
        let cell = PhotoCarouselCell(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let imageView: UIImageView = tryUnwrap(cell.firstDescendant())
        cell.setImage(UIImage())

        cell.prepareForReuse()

        XCTAssertNil(imageView.image)
    }

    private func flushMainQueue() {
        let expectation = expectation(description: "Main queue work completed")
        DispatchQueue.main.async {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
    }

    private func tryUnwrap<T>(_ value: T?, file: StaticString = #filePath, line: UInt = #line) -> T {
        guard let value else {
            XCTFail("Expected a \(T.self) in the view hierarchy", file: file, line: line)
            fatalError("Missing expected view")
        }
        return value
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
