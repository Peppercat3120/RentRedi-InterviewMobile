import XCTest
import UIKit
@testable import ApartmentPopupDemo

final class PhotoCarouselIntegrationTests: XCTestCase {
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
