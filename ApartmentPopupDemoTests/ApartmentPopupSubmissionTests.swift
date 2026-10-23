import XCTest
@testable import ApartmentPopupDemo

final class ApartmentPopupSubmissionTests: XCTestCase {
    func testApplicationAndFallbackSubmissionTypesUseApplyVerb() {
        XCTAssertEqual(ApartmentPopupSubmission(submissionType: "application").verb, "apply")
        XCTAssertEqual(ApartmentPopupSubmission(submissionType: "unsupported").verb, "apply")
        XCTAssertEqual(ApartmentPopupSubmission().verb, "apply")
    }

    func testPrequalificationSubmissionTypeUsesPrequalifyVerb() {
        XCTAssertEqual(
            ApartmentPopupSubmission(submissionType: "prequalification").verb,
            "prequalify"
        )
    }

    func testFullAddressPreservesExistingFormatting() {
        let submission = ApartmentPopupSubmission(
            unitID: "4B",
            address: "123 Maple Street",
            city: "Austin",
            state: "TX",
            zip: "78701"
        )

        XCTAssertEqual(submission.fullAddress, "123 Maple Street, 4B, Austin, TX 78701")
    }

    func testMissingAddressFieldsRemainSafeAndPreserveFormatting() {
        let submission = ApartmentPopupSubmission(city: "Austin")

        XCTAssertEqual(submission.fullAddress, ", , Austin,  ")
    }
}
