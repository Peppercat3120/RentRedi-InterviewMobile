import Foundation

struct ApartmentPopupPresentationBuilder {
    func build(
        submission: ApartmentPopupSubmission,
        listingDetails: ApartmentListingDetails?
    ) -> ApartmentPopupContent {
        let actionTitle = actionTitle(for: submission.submissionType)
        let photoURLs = listingDetails?.photoURLs ?? []
        let hasPhotos = !photoURLs.isEmpty

        return ApartmentPopupContent(
            title: "Invite to \(actionTitle)",
            bedroomText: listingDetails?.bedroomCount.map { "\($0) Bedrooms" },
            bathroomText: listingDetails?.bathroomCount.map { " • \($0) Bathrooms" },
            addressText: hasPhotos
                ? photoAddress(for: submission)
                : defaultInviteAddress(for: submission, actionTitle: actionTitle),
            regionText: hasPhotos ? region(for: submission) : nil,
            rentText: listingDetails?.monthlyRent.map { "$\($0)/month" },
            primaryActionTitle: actionTitle,
            media: hasPhotos
                ? .photos(photoURLs.map(PhotoCarouselItem.url))
                : .defaultInvite
        )
    }

    private func actionTitle(for submissionType: String?) -> String {
        submissionType == "prequalification" ? "Prequalify" : "Apply"
    }

    private func photoAddress(for submission: ApartmentPopupSubmission) -> String {
        "\(submission.address ?? "Error, Not Available"), Unit \(submission.unitID ?? "")"
    }

    private func defaultInviteAddress(
        for submission: ApartmentPopupSubmission,
        actionTitle: String
    ) -> String {
        "You have been invited to \(actionTitle) to \(fullAddress(for: submission))"
    }

    private func fullAddress(for submission: ApartmentPopupSubmission) -> String {
        "\(submission.address ?? ""), \(submission.unitID ?? ""), \(submission.city ?? ""), "
            + "\(submission.state ?? "") \(submission.zip ?? "")"
    }

    private func region(for submission: ApartmentPopupSubmission) -> String {
        "\(submission.city ?? ""), \(submission.state ?? "") \(submission.zip ?? "")"
    }
}
