import Foundation

enum DemoApartmentPopupFixture {
    static func makeSubmission() -> ApartmentPopupSubmission {
        ApartmentPopupSubmission(
            submissionType: "application",
            ownerID: "demo-owner",
            propertyID: "demo-property",
            unitID: "4B",
            renterID: "demo-renter",
            address: "123 Maple Street",
            city: "Austin",
            state: "TX",
            zip: "78701"
        )
    }

    static func makeListingDetails() -> ApartmentListingDetails {
        ApartmentListingDetails(
            bedroomCount: "2",
            bathroomCount: "2",
            monthlyRent: "2,450",
            photoURLs: DemoImageProvider.apartmentImageURLs()
        )
    }
}
