import Foundation

final class DemoTenantCardSubmission {
    var submissionType: String?
    var ownerID: String?
    var propertyID: String?
    var unitID: String?
    var renterID: String?
    var address: String?
    var city: String?
    var state: String?
    var zip: String?

    var verb: String {
        switch submissionType {
        case "prequalification": return "prequalify"
        default: return "apply"
        }
    }

    var fullAddress: String {
        "\(address ?? ""), \(unitID ?? ""), \(city ?? ""), \(state ?? "") \(zip ?? "")"
    }

    init(address: String, unitID: String, city: String, state: String, zip: String) {
        self.address = address
        self.unitID = unitID
        self.city = city
        self.state = state
        self.zip = zip
        submissionType = nil
    }
}
