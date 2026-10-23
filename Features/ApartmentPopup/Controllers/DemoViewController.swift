import UIKit

enum ApartmentPopupControllerError: LocalizedError {
    case unsupportedSubmissionType(String)

    var errorDescription: String? {
        switch self {
        case .unsupportedSubmissionType(let type):
            return "Unsupported submission type: \(type)"
        }
    }
}

@MainActor
final class DemoViewController: RentRediPlusHomeVC {
    private let listingService: ApartmentListingLoading
    private let inviteStatusService: InviteStatusUpdating
    private let initialSubmission: ApartmentPopupSubmission?
    private let serviceErrorHandler: (Error) -> Void
    private var listingTask: Task<Void, Never>?

    private(set) var popupView: ApartmentPopupView?
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

    init(
        listingService: ApartmentListingLoading,
        inviteStatusService: InviteStatusUpdating,
        initialSubmission: ApartmentPopupSubmission? = nil,
        serviceErrorHandler: @escaping (Error) -> Void = { print($0) }
    ) {
        self.listingService = listingService
        self.inviteStatusService = inviteStatusService
        self.initialSubmission = initialSubmission
        self.serviceErrorHandler = serviceErrorHandler
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Use init(listingService:inviteStatusService:serviceErrorHandler:)")
    }

    deinit {
        listingTask?.cancel()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        if let initialSubmission {
            showApartmentPopup(for: initialSubmission)
        }
    }

    func showApartmentPopup(for submission: ApartmentPopupSubmission) {
        listingTask?.cancel()
        popupView?.removeFromSuperview()

        tenantCardSubmission = submission

        let popup = ApartmentPopupView(frame: view.bounds)
        popup.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        popup.delegate = self
        popup.accessibilityIdentifier = "apartmentPopup"
        view.addSubview(popup)

        applicationPopup = popup
        popupView = popup
        popup.configure(with: makePopupContent(for: submission, listingDetails: nil))

        hasExistingInviteApplication = true
        setupTenantToDoAlert()
        updateToDoAlert(
            title: "You have been invited to \(submission.verb.capitalizeFirstLetter()) to \(submission.fullAddress).",
            description: "Tap to start, or go to '\(submission.submissionType ?? "")'",
            type: .applicationInvite
        )

        guard let identifier = makeListingIdentifier(from: submission) else {
            return
        }

        let listingService = listingService
        let serviceErrorHandler = serviceErrorHandler
        listingTask = Task { [weak self, weak popup] in
            do {
                let details = try await listingService.loadListingDetails(for: identifier)
                try Task.checkCancellation()

                guard let self,
                      let popup,
                      self.popupView === popup else {
                    return
                }
                popup.configure(with: self.makePopupContent(for: submission, listingDetails: details))
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled else { return }
                serviceErrorHandler(error)
            }
        }
    }

    private func makePopupContent(
        for submission: ApartmentPopupSubmission,
        listingDetails: ApartmentListingDetails?
    ) -> ApartmentPopupContent {
        let photoURLs = listingDetails?.photoURLs ?? []
        let hasPhotos = !photoURLs.isEmpty

        return ApartmentPopupContent(
            title: "Invite to \(submission.verb.capitalizeFirstLetter())",
            bedroomText: listingDetails?.bedroomCount.map { "\($0) Bedrooms" },
            bathroomText: listingDetails?.bathroomCount.map { " • \($0) Bathrooms" },
            addressText: hasPhotos
                ? "\(submission.address ?? "Error, Not Available"), Unit \(submission.unitID ?? "")"
                : "You have been invited to \(submission.verb.capitalizeFirstLetter()) to \(submission.fullAddress)",
            regionText: hasPhotos
                ? "\(submission.city ?? ""), \(submission.state ?? "") \(submission.zip ?? "")"
                : nil,
            rentText: listingDetails?.monthlyRent.map { "$\($0)/month" },
            primaryActionTitle: applyPrequalifyVerb(noun: submission.submissionType ?? "").capitalizeFirstLetter(),
            media: hasPhotos
                ? .photos(photoURLs.map(PhotoCarouselItem.url))
                : .defaultInvite
        )
    }

    private func makeListingIdentifier(
        from submission: ApartmentPopupSubmission
    ) -> ApartmentListingIdentifier? {
        guard let ownerID = submission.ownerID,
              let propertyID = submission.propertyID,
              let unitID = submission.unitID else {
            return nil
        }
        return ApartmentListingIdentifier(
            ownerID: ownerID,
            propertyID: propertyID,
            unitID: unitID
        )
    }

    private func makeInviteIdentifier(
        from submission: ApartmentPopupSubmission
    ) -> InviteIdentifier? {
        guard let submissionType = submission.submissionType,
              let ownerID = submission.ownerID,
              let propertyID = submission.propertyID,
              let unitID = submission.unitID,
              let renterID = submission.renterID else {
            return nil
        }
        return InviteIdentifier(
            ownerID: ownerID,
            propertyID: propertyID,
            unitID: unitID,
            renterID: renterID,
            submissionType: submissionType
        )
    }

    private func persistStatus(_ status: InviteStatus, for invite: InviteIdentifier) {
        let inviteStatusService = inviteStatusService
        let serviceErrorHandler = serviceErrorHandler
        Task {
            do {
                try await inviteStatusService.updateStatus(status, for: invite)
            } catch is CancellationError {
                return
            } catch {
                serviceErrorHandler(error)
            }
        }
    }
}

extension DemoViewController: ApartmentPopupViewDelegate {
    func apartmentPopupViewDidRequestStart(_ popupView: ApartmentPopupView) {
        popupView.isHidden = true
        hideTenantToDoAlert()

        guard let tenantCardSubmission,
              let submissionType = tenantCardSubmission.submissionType,
              let invite = makeInviteIdentifier(from: tenantCardSubmission) else {
            return
        }

        persistStatus(.accepted, for: invite)

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
            serviceErrorHandler(ApartmentPopupControllerError.unsupportedSubmissionType(submissionType))
        }
    }

    func apartmentPopupViewDidRequestDismiss(_ popupView: ApartmentPopupView) {
        popupView.isHidden = true

        guard let tenantCardSubmission,
              let invite = makeInviteIdentifier(from: tenantCardSubmission) else {
            return
        }
        persistStatus(.viewed, for: invite)
    }
}
