import UIKit

@MainActor
final class ApartmentPopupViewController: UIViewController {
    private let listingService: ApartmentListingLoading
    private let inviteStatusService: InviteStatusUpdating
    private let presentationBuilder: ApartmentPopupPresentationBuilder
    private let initialSubmission: ApartmentPopupSubmission?
    private let serviceErrorHandler: (Error) -> Void
    private var listingTask: Task<Void, Never>?
    private var currentSubmission: ApartmentPopupSubmission?

    private(set) var popupView: ApartmentPopupView?

    init(
        listingService: ApartmentListingLoading,
        inviteStatusService: InviteStatusUpdating,
        presentationBuilder: ApartmentPopupPresentationBuilder = ApartmentPopupPresentationBuilder(),
        initialSubmission: ApartmentPopupSubmission? = nil,
        serviceErrorHandler: @escaping (Error) -> Void = { print($0) }
    ) {
        self.listingService = listingService
        self.inviteStatusService = inviteStatusService
        self.presentationBuilder = presentationBuilder
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

    override func loadView() {
        view = UIView()
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
        currentSubmission = submission

        let popup = ApartmentPopupView(frame: view.bounds)
        popup.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        popup.delegate = self
        popup.accessibilityIdentifier = "apartmentPopup"
        view.addSubview(popup)

        popupView = popup
        popup.configure(with: presentationBuilder.build(
            submission: submission,
            listingDetails: nil
        ))

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
                popup.configure(with: self.presentationBuilder.build(
                    submission: submission,
                    listingDetails: details
                ))
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled else { return }
                serviceErrorHandler(error)
            }
        }
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

extension ApartmentPopupViewController: ApartmentPopupViewDelegate {
    func apartmentPopupViewDidRequestStart(_ popupView: ApartmentPopupView) {
        // Mocked behavior for this challenge: dismiss instead of entering the production application flow.
        popupView.isHidden = true
    }

    func apartmentPopupViewDidRequestDismiss(_ popupView: ApartmentPopupView) {
        popupView.isHidden = true

        guard let currentSubmission,
              let invite = makeInviteIdentifier(from: currentSubmission) else {
            return
        }
        persistStatus(.viewed, for: invite)
    }
}
