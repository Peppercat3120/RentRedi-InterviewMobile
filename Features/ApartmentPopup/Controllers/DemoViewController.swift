import UIKit

final class DemoViewController: RentRediPlusHomeVC {
    private var popupView: ApartmentPopupView?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        showMockApartment()
    }

    private func showMockApartment() {
        let submission = DemoTenantCardSubmission(
            address: "123 Maple Street",
            unitID: "4B",
            city: "Austin",
            state: "TX",
            zip: "78701"
        )

        tenantCardSubmission = submission

        let popup = ApartmentPopupView(frame: view.bounds)
        popup.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        popup.delegate = self
        popup.tenantCardSubmission = submission
        popup.accessibilityIdentifier = "apartmentPopup"
        view.addSubview(popup)

        applicationPopup = popup
        popupView = popup

        popup.configure(with: makePopupContent(for: submission))

        hasExistingInviteApplication = true
        setupTenantToDoAlert()
        updateToDoAlert(
            title: "You have been invited to \(submission.verb.capitalizeFirstLetter())) to \(submission.fullAddress).",
            description: "Tap to start, or go to '\(submission.submissionType ?? "")'",
            type: .applicationInvite
        )
    }

    private func makePopupContent(for submission: DemoTenantCardSubmission) -> ApartmentPopupContent {
        ApartmentPopupContent(
            title: "Invite to \(submission.verb.capitalizeFirstLetter())",
            bedroomText: "2 Bedrooms",
            bathroomText: " • 2 Bathrooms",
            addressText: "\(submission.address ?? "Error, Not Available"), Unit \(submission.unitID ?? "")",
            regionText: "\(submission.city ?? ""), \(submission.state ?? "") \(submission.zip ?? "")",
            rentText: "$2,450/month",
            primaryActionTitle: applyPrequalifyVerb(noun: submission.submissionType ?? "").capitalizeFirstLetter(),
            media: .photos(DemoImageFactory.makeImageURLs().map(PhotoCarouselItem.url))
        )
    }
}
