import XCTest
@testable import ApartmentPopupDemo

final class ApartmentPopupPresentationBuilderTests: XCTestCase {
    private let builder = ApartmentPopupPresentationBuilder()

    func testApplicationWithPhotosBuildsCompletePhotoPresentation() {
        let firstURL = URL(string: "https://example.com/unit.jpg")!
        let secondURL = URL(string: "https://example.com/property.jpg")!
        let submission = makeSubmission(type: "application")
        let listingDetails = ApartmentListingDetails(
            bedroomCount: "2",
            bathroomCount: "1.5",
            monthlyRent: "2,450",
            photoURLs: [firstURL, secondURL]
        )

        let content = builder.build(submission: submission, listingDetails: listingDetails)

        XCTAssertEqual(content.title, "Invite to Apply")
        XCTAssertEqual(content.primaryActionTitle, "Apply")
        XCTAssertEqual(content.bedroomText, "2 Bedrooms")
        XCTAssertEqual(content.bathroomText, " • 1.5 Bathrooms")
        XCTAssertEqual(content.addressText, "123 Maple Street, Unit 4B")
        XCTAssertEqual(content.regionText, "Austin, TX 78701")
        XCTAssertEqual(content.rentText, "$2,450/month")
        XCTAssertEqual(photoURLs(from: content.media), [firstURL, secondURL])
    }

    func testPrequalificationWithoutListingBuildsDefaultInvitePresentation() {
        let content = builder.build(
            submission: makeSubmission(type: "prequalification"),
            listingDetails: nil
        )

        XCTAssertEqual(content.title, "Invite to Prequalify")
        XCTAssertEqual(content.primaryActionTitle, "Prequalify")
        XCTAssertNil(content.bedroomText)
        XCTAssertNil(content.bathroomText)
        XCTAssertEqual(
            content.addressText,
            "You have been invited to Prequalify to 123 Maple Street, 4B, Austin, TX 78701"
        )
        XCTAssertNil(content.regionText)
        XCTAssertNil(content.rentText)
        assertDefaultInvite(content.media)
    }

    func testUnsupportedAndMissingSubmissionTypesUseApplyWording() {
        for submissionType in ["unsupported", nil] {
            let content = builder.build(
                submission: makeSubmission(type: submissionType),
                listingDetails: nil
            )

            XCTAssertEqual(content.title, "Invite to Apply")
            XCTAssertEqual(content.primaryActionTitle, "Apply")
            XCTAssertTrue(content.addressText.hasPrefix("You have been invited to Apply to "))
        }
    }

    func testListingWithoutPhotosKeepsDetailsAndUsesDefaultInvitePresentation() {
        let listingDetails = ApartmentListingDetails(
            bedroomCount: "3",
            bathroomCount: "2",
            monthlyRent: "3,100",
            photoURLs: []
        )

        let content = builder.build(
            submission: makeSubmission(type: "application"),
            listingDetails: listingDetails
        )

        XCTAssertEqual(content.bedroomText, "3 Bedrooms")
        XCTAssertEqual(content.bathroomText, " • 2 Bathrooms")
        XCTAssertEqual(content.rentText, "$3,100/month")
        XCTAssertEqual(
            content.addressText,
            "You have been invited to Apply to 123 Maple Street, 4B, Austin, TX 78701"
        )
        XCTAssertNil(content.regionText)
        assertDefaultInvite(content.media)
    }

    func testMissingAddressFieldsPreserveSafeLegacyFormatting() {
        let submission = ApartmentPopupSubmission(
            submissionType: "application",
            city: "Austin"
        )

        let defaultContent = builder.build(submission: submission, listingDetails: nil)
        let photoContent = builder.build(
            submission: submission,
            listingDetails: ApartmentListingDetails(
                bedroomCount: nil,
                bathroomCount: nil,
                monthlyRent: nil,
                photoURLs: [URL(string: "https://example.com/unit.jpg")!]
            )
        )

        XCTAssertEqual(defaultContent.addressText, "You have been invited to Apply to , , Austin,  ")
        XCTAssertEqual(photoContent.addressText, "Error, Not Available, Unit ")
        XCTAssertEqual(photoContent.regionText, "Austin,  ")
    }

    private func makeSubmission(type: String?) -> ApartmentPopupSubmission {
        ApartmentPopupSubmission(
            submissionType: type,
            ownerID: "owner-1",
            propertyID: "property-2",
            unitID: "4B",
            renterID: "renter-4",
            address: "123 Maple Street",
            city: "Austin",
            state: "TX",
            zip: "78701"
        )
    }

    private func photoURLs(
        from media: ApartmentPopupContent.Media,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> [URL] {
        guard case .photos(let items) = media else {
            XCTFail("Expected photo media", file: file, line: line)
            return []
        }

        return items.compactMap { item in
            guard case .url(let url) = item else { return nil }
            return url
        }
    }

    private func assertDefaultInvite(
        _ media: ApartmentPopupContent.Media,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard case .defaultInvite = media else {
            XCTFail("Expected default invite media", file: file, line: line)
            return
        }
    }
}
