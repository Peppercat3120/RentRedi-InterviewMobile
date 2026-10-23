import Foundation

#if canImport(FirebaseDatabase)
import FirebaseDatabase

final class FirebaseApartmentListingService: ApartmentListingLoading {
    private let rootReference: DatabaseReference

    init(rootReference: DatabaseReference) {
        self.rootReference = rootReference
    }

    func loadListingDetails(
        for identifier: ApartmentListingIdentifier
    ) async throws -> ApartmentListingDetails {
        let unitDetailsPath = "allUsers/ownerProfiles/\(identifier.ownerID)/profile/properties/\(identifier.propertyID)/units/\(identifier.unitID)/unitDetails"
        let propertyDetailsPath = "allUsers/ownerProfiles/\(identifier.ownerID)/profile/properties/\(identifier.propertyID)/propertyDetails"

        do {
            try Task.checkCancellation()

            async let bedroomCount = readOptionalString(at: "\(unitDetailsPath)/numberOfBedrooms")
            async let bathroomCount = readOptionalString(at: "\(unitDetailsPath)/numberOfBathrooms")
            async let monthlyRent = readOptionalString(at: "\(unitDetailsPath)/listingMonthlyRent")
            async let unitPhotoURLs = readPhotoURLs(at: "\(unitDetailsPath)/photos")
            async let propertyPhotoURLs = readPhotoURLs(at: "\(propertyDetailsPath)/photos")

            let values = try await (
                bedroomCount,
                bathroomCount,
                monthlyRent,
                unitPhotoURLs,
                propertyPhotoURLs
            )
            try Task.checkCancellation()

            return ApartmentListingDetails(
                bedroomCount: values.0,
                bathroomCount: values.1,
                monthlyRent: values.2,
                photoURLs: values.3 + values.4
            )
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            if Task.isCancelled {
                throw CancellationError()
            }
            throw ApartmentListingLoadError.backend(error)
        }
    }

    private func readOptionalString(at path: String) async throws -> String? {
        let snapshot = try await readSnapshot(at: path)
        guard let value = snapshot.value as? String, !value.isEmpty else {
            return nil
        }
        return value
    }

    private func readPhotoURLs(at path: String) async throws -> [URL] {
        let snapshot = try await readSnapshot(at: path)
        guard let photos = snapshot.value as? [String: Any] else {
            return []
        }

        return photos.keys.sorted().compactMap { key in
            guard let photo = photos[key] as? [String: Any],
                  let downloadURL = photo["downloadURL"] as? String else {
                return nil
            }
            return URL(string: downloadURL)
        }
    }

    private func readSnapshot(at path: String) async throws -> DataSnapshot {
        try Task.checkCancellation()
        return try await withCheckedThrowingContinuation { continuation in
            rootReference.child(path).observeSingleEvent(
                of: .value,
                with: { snapshot in
                    continuation.resume(returning: snapshot)
                },
                withCancel: { error in
                    continuation.resume(throwing: error)
                }
            )
        }
    }
}

final class FirebaseInviteStatusService: InviteStatusUpdating {
    private let rootReference: DatabaseReference

    init(rootReference: DatabaseReference) {
        self.rootReference = rootReference
    }

    func updateStatus(
        _ status: InviteStatus,
        for invite: InviteIdentifier
    ) async throws {
        let inviteKey = "\(invite.ownerID)\(invite.propertyID)\(invite.unitID)\(invite.renterID)_\(invite.submissionType)"
        let statusReference = rootReference
            .child("inviteTenant")
            .child(inviteKey)
            .child("inviteStatus")

        do {
            try Task.checkCancellation()
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                statusReference.setValue(status.rawValue) { error, _ in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: ())
                    }
                }
            }
            try Task.checkCancellation()
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            if Task.isCancelled {
                throw CancellationError()
            }
            throw InviteStatusUpdateError.backend(error)
        }
    }
}
#endif
