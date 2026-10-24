import Foundation

struct ApartmentPopupSubmission: Equatable {
    let submissionType: String?
    let ownerID: String?
    let propertyID: String?
    let unitID: String?
    let renterID: String?
    let address: String?
    let city: String?
    let state: String?
    let zip: String?

    init(
        submissionType: String? = nil,
        ownerID: String? = nil,
        propertyID: String? = nil,
        unitID: String? = nil,
        renterID: String? = nil,
        address: String? = nil,
        city: String? = nil,
        state: String? = nil,
        zip: String? = nil
    ) {
        self.submissionType = submissionType
        self.ownerID = ownerID
        self.propertyID = propertyID
        self.renterID = renterID
        self.address = address
        self.unitID = unitID
        self.city = city
        self.state = state
        self.zip = zip
    }
}
