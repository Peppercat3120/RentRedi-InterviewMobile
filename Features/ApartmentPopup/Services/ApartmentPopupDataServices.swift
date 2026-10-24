import Foundation

struct ApartmentListingIdentifier: Equatable {
    let ownerID: String
    let propertyID: String
    let unitID: String
}

struct ApartmentListingDetails: Equatable {
    let bedroomCount: String?
    let bathroomCount: String?
    let monthlyRent: String?
    let photoURLs: [URL]
}

enum ApartmentListingLoadError: Error {
    case backend(Error)
}

protocol ApartmentListingLoading {
    func loadListingDetails(
        for identifier: ApartmentListingIdentifier
    ) async throws -> ApartmentListingDetails
}

struct InviteIdentifier: Equatable {
    let ownerID: String
    let propertyID: String
    let unitID: String
    let renterID: String
    let submissionType: String
}

enum InviteStatus: String, Equatable {
    /// Used by production before routing into the application or prequalification flow.
    /// TODO: Persist this transition when the production Start coordinator is extracted.
    case accepted
    case viewed
}

enum InviteStatusUpdateError: Error {
    case backend(Error)
}

protocol InviteStatusUpdating {
    func updateStatus(
        _ status: InviteStatus,
        for invite: InviteIdentifier
    ) async throws
}
