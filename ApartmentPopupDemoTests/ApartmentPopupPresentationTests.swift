import XCTest
import UIKit
@testable import ApartmentPopupDemo

final class ApartmentPopupPresentationTests: XCTestCase {
    func testCompleteContentRendersEveryValueAndPhotoMedia() {
        let popup = makePopup()
        let content = ApartmentPopupContent(
            title: "Invite to Apply",
            bedroomText: "2 Bedrooms",
            bathroomText: " • 2 Bathrooms",
            addressText: "123 Maple Street, Unit 4B",
            regionText: "Austin, TX 78701",
            rentText: "$2,450/month",
            primaryActionTitle: "Apply",
            media: .photos([.image(UIImage()), .image(UIImage()), .image(UIImage())])
        )

        popup.configure(with: content)

        XCTAssertEqual(popup.applicationPopupTitle.text, "Invite to Apply")
        XCTAssertEqual(popup.applicationPopupBedrooms.text, "2 Bedrooms")
        XCTAssertFalse(popup.applicationPopupBedrooms.isHidden)
        XCTAssertEqual(popup.applicationPopupBathrooms.text, " • 2 Bathrooms")
        XCTAssertFalse(popup.applicationPopupBathrooms.isHidden)
        XCTAssertEqual(popup.applicationPopupStreetAddress.text, "123 Maple Street, Unit 4B")
        XCTAssertFalse(popup.applicationPopupStreetAddress.isHidden)
        XCTAssertEqual(popup.applicationPopupRegion.text, "Austin, TX 78701")
        XCTAssertFalse(popup.applicationPopupRegion.isHidden)
        XCTAssertEqual(popup.applicationPopupRentAmount.text, "$2,450/month")
        XCTAssertFalse(popup.applicationPopupRentAmount.isHidden)
        XCTAssertEqual(popup.startApplicationButton.title(for: .normal), "Apply")
        assertCarousel(on: popup, itemCount: 3, currentPage: 0, pageText: "1 of 3")
        XCTAssertFalse(popup.applicationPhotoCarousel.isHidden)
        XCTAssertTrue(popup.applicationInviteImage.isHidden)
    }

    func testMissingOptionalValuesAreClearedAndHiddenDuringReconfiguration() {
        let popup = makePopup()
        popup.configure(with: populatedContent(media: .photos([.image(UIImage())])))

        popup.configure(with: ApartmentPopupContent(
            title: "Invite to Apply",
            bedroomText: nil,
            bathroomText: nil,
            addressText: "You have been invited to Apply to 123 Maple Street, 4B, Austin, TX 78701",
            regionText: nil,
            rentText: nil,
            primaryActionTitle: "Apply",
            media: .defaultInvite
        ))

        XCTAssertNil(popup.applicationPopupBedrooms.text)
        XCTAssertTrue(popup.applicationPopupBedrooms.isHidden)
        XCTAssertNil(popup.applicationPopupBathrooms.text)
        XCTAssertTrue(popup.applicationPopupBathrooms.isHidden)
        XCTAssertNil(popup.applicationPopupRegion.text)
        XCTAssertTrue(popup.applicationPopupRegion.isHidden)
        XCTAssertNil(popup.applicationPopupRentAmount.text)
        XCTAssertTrue(popup.applicationPopupRentAmount.isHidden)
        XCTAssertEqual(
            popup.applicationPopupStreetAddress.text,
            "You have been invited to Apply to 123 Maple Street, 4B, Austin, TX 78701"
        )
    }

    func testMediaStateResetsBetweenPhotosDefaultInviteAndEmptyPhotos() {
        let popup = makePopup()
        popup.configure(with: populatedContent(media: .photos([.image(UIImage()), .image(UIImage())])))
        assertCarousel(on: popup, itemCount: 2, currentPage: 0, pageText: "1 of 2")

        popup.configure(with: populatedContent(
            addressText: "You have been invited to Apply to 123 Maple Street, 4B, Austin, TX 78701",
            media: .defaultInvite
        ))
        assertDefaultInvite(on: popup)
        XCTAssertEqual(
            popup.applicationPopupStreetAddress.text,
            "You have been invited to Apply to 123 Maple Street, 4B, Austin, TX 78701"
        )
        XCTAssertTrue(popup.applicationPopupRegion.isHidden)

        popup.configure(with: populatedContent(media: .photos([.image(UIImage()), .image(UIImage()), .image(UIImage())])))
        assertCarousel(on: popup, itemCount: 3, currentPage: 0, pageText: "1 of 3")
        XCTAssertFalse(popup.applicationPopupRegion.isHidden)

        popup.configure(with: populatedContent(media: .photos([])))
        assertDefaultInvite(on: popup)
    }

    func testFrameInitializerLoadsXIBAndConnectsPresentationOutlets() {
        let popup = makePopup()

        XCTAssertNotNil(popup.applicationPopupTitle)
        XCTAssertNotNil(popup.applicationPopupBedrooms)
        XCTAssertNotNil(popup.applicationPopupBathrooms)
        XCTAssertNotNil(popup.applicationPopupStreetAddress)
        XCTAssertNotNil(popup.applicationPopupRentAmount)
        XCTAssertNotNil(popup.applicationPopupRegion)
        XCTAssertNotNil(popup.applicationPhotoCarousel)
        XCTAssertNotNil(popup.applicationInviteImage)
        XCTAssertNotNil(popup.startApplicationButton)
        XCTAssertTrue(popup.applicationPhotoCarousel.isDescendant(of: popup))
    }

    private func makePopup() -> ApartmentPopupView {
        ApartmentPopupView(frame: CGRect(x: 0, y: 0, width: 414, height: 896))
    }

    private func populatedContent(
        addressText: String = "123 Maple Street, Unit 4B",
        regionText: String? = "Austin, TX 78701",
        media: ApartmentPopupContent.Media
    ) -> ApartmentPopupContent {
        ApartmentPopupContent(
            title: "Invite to Apply",
            bedroomText: "2 Bedrooms",
            bathroomText: " • 2 Bathrooms",
            addressText: addressText,
            regionText: regionText,
            rentText: "$2,450/month",
            primaryActionTitle: "Apply",
            media: media
        )
    }

    private func assertCarousel(
        on popup: ApartmentPopupView,
        itemCount: Int,
        currentPage: Int,
        pageText: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let collectionView: UICollectionView = tryUnwrap(popup.applicationPhotoCarousel.firstDescendant(), file: file, line: line)
        let pageControl: UIPageControl = tryUnwrap(popup.applicationPhotoCarousel.firstDescendant(), file: file, line: line)
        let pageLabel: UILabel = tryUnwrap(popup.applicationPhotoCarousel.firstDescendant(), file: file, line: line)

        XCTAssertEqual(collectionView.dataSource?.collectionView(collectionView, numberOfItemsInSection: 0), itemCount, file: file, line: line)
        XCTAssertEqual(pageControl.numberOfPages, itemCount, file: file, line: line)
        XCTAssertEqual(pageControl.currentPage, currentPage, file: file, line: line)
        XCTAssertEqual(pageLabel.text, pageText, file: file, line: line)
        XCTAssertFalse(pageControl.isHidden, file: file, line: line)
    }

    private func assertDefaultInvite(
        on popup: ApartmentPopupView,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let collectionView: UICollectionView = tryUnwrap(popup.applicationPhotoCarousel.firstDescendant(), file: file, line: line)
        let pageControl: UIPageControl = tryUnwrap(popup.applicationPhotoCarousel.firstDescendant(), file: file, line: line)
        let pageLabel: UILabel = tryUnwrap(popup.applicationPhotoCarousel.firstDescendant(), file: file, line: line)

        XCTAssertTrue(popup.applicationPhotoCarousel.isHidden, file: file, line: line)
        XCTAssertFalse(popup.applicationInviteImage.isHidden, file: file, line: line)
        XCTAssertTrue(popup.applicationPopupRegion.isHidden, file: file, line: line)
        XCTAssertEqual(collectionView.dataSource?.collectionView(collectionView, numberOfItemsInSection: 0), 0, file: file, line: line)
        XCTAssertTrue(pageControl.isHidden, file: file, line: line)
        XCTAssertTrue(pageLabel.isHidden, file: file, line: line)
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
