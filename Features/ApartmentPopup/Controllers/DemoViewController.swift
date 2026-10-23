import UIKit

final class DemoViewController: RentRediPlusHomeVC {
    private var popupView: ApartmentPopupView?
    var makeApplyHomeViewController: () -> ApplyHomeVC = {
        UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewController(withIdentifier: "applyHomeScreen") as! ApplyHomeVC
    }
    var makePrequalifyHomeViewController: () -> PrequalifyHomeVC = {
        UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewController(withIdentifier: "prequalifyHomeScreen") as! PrequalifyHomeVC
    }
    lazy var presentDestination: (UIViewController) -> Void = { [weak self] destination in
        self?.present(destination, animated: true, completion: nil)
    }

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

extension DemoViewController: ApartmentPopupViewDelegate {
    func apartmentPopupViewDidRequestStart(_ popupView: ApartmentPopupView) {
        popupView.isHidden = true
        hideTenantToDoAlert()

        guard let tenantCardSubmission,
              let submissionType = tenantCardSubmission.submissionType,
              let ownerID = tenantCardSubmission.ownerID,
              let propertyID = tenantCardSubmission.propertyID,
              let unitID = tenantCardSubmission.unitID,
              let renterID = tenantCardSubmission.renterID else {
            return
        }

        updateInviteStatus(
            "accepted",
            ownerID: ownerID,
            propertyID: propertyID,
            unitID: unitID,
            renterID: renterID,
            submissionType: submissionType
        )

        switch submissionType {
        case "application":
            let destination = makeApplyHomeViewController()
            destination.modalPresentationStyle = .fullScreen
            destination.tenantCardSubmission = tenantCardSubmission
            destination.homeVC = self
            presentDestination(destination)
        case "prequalification":
            let destination = makePrequalifyHomeViewController()
            destination.modalPresentationStyle = .fullScreen
            destination.tenantCardSubmission = tenantCardSubmission
            presentDestination(destination)
        default:
            DatabaseFunctions().log(message: "Error: No submission type found")
        }
    }

    func apartmentPopupViewDidRequestDismiss(_ popupView: ApartmentPopupView) {
        if let tenantCardSubmission,
           let submissionType = tenantCardSubmission.submissionType,
           let ownerID = tenantCardSubmission.ownerID,
           let propertyID = tenantCardSubmission.propertyID,
           let unitID = tenantCardSubmission.unitID,
           let renterID = tenantCardSubmission.renterID {
            updateInviteStatus(
                "viewed",
                ownerID: ownerID,
                propertyID: propertyID,
                unitID: unitID,
                renterID: renterID,
                submissionType: submissionType
            )
        }

        popupView.isHidden = true
    }

    private func updateInviteStatus(
        _ status: String,
        ownerID: String,
        propertyID: String,
        unitID: String,
        renterID: String,
        submissionType: String
    ) {
        ref.child("inviteTenant")
            .child("\(ownerID)\(propertyID)\(unitID)\(renterID)_\(submissionType)")
            .child("inviteStatus")
            .setValue(status)
    }
}
