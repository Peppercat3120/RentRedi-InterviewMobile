import XCTest
import UIKit
@testable import ApartmentPopupDemo

@MainActor
final class ApartmentPopupInteractionTests: XCTestCase {
    func testStartActionNotifiesDelegateExactlyOnceWithOriginatingPopup() {
        let popup = makePopup()
        let delegate = ApartmentPopupDelegateSpy()
        popup.delegate = delegate

        popup.startApplicationTapped(self)

        XCTAssertEqual(delegate.startRequests.count, 1)
        XCTAssertTrue(delegate.startRequests.first === popup)
        XCTAssertTrue(delegate.dismissRequests.isEmpty)
        XCTAssertFalse(popup.isHidden)
    }

    func testDismissActionNotifiesDelegateExactlyOnceWithOriginatingPopup() {
        let popup = makePopup()
        let delegate = ApartmentPopupDelegateSpy()
        popup.delegate = delegate

        popup.dismissApplicationTapped(self)

        XCTAssertEqual(delegate.dismissRequests.count, 1)
        XCTAssertTrue(delegate.dismissRequests.first === popup)
        XCTAssertTrue(delegate.startRequests.isEmpty)
        XCTAssertFalse(popup.isHidden)
    }

    func testActionsAreSafeWithoutDelegateAndDoNotChangeVisibility() {
        let popup = makePopup()
        popup.isHidden = false

        popup.startApplicationTapped(self)
        XCTAssertFalse(popup.isHidden)

        popup.dismissApplicationTapped(self)
        XCTAssertFalse(popup.isHidden)
    }

    func testSuccessfulListingLoadRendersDetailsAndOrderedPhotoURLs() async {
        let firstURL = URL(string: "https://example.com/unit.jpg")!
        let secondURL = URL(string: "https://example.com/property.jpg")!
        let listingService = ControlledListingService()
        let controller = makeController(listingService: listingService)
        let submission = makeSubmission(type: "application")

        controller.loadViewIfNeeded()
        controller.showApartmentPopup(for: submission)
        await listingService.waitUntilRequestCount(1)
        await listingService.resolveNext(with: ApartmentListingDetails(
            bedroomCount: "2",
            bathroomCount: "1.5",
            monthlyRent: "2,450",
            photoURLs: [firstURL, secondURL]
        ))

        let popup = tryUnwrap(controller.popupView)
        await waitUntil { popup.applicationPopupBedrooms.text == "2 Bedrooms" }

        XCTAssertEqual(popup.applicationPopupBathrooms.text, " • 1.5 Bathrooms")
        XCTAssertEqual(popup.applicationPopupRentAmount.text, "$2,450/month")
        XCTAssertEqual(popup.applicationPopupStreetAddress.text, "123 Maple Street, Unit unit-3")
        XCTAssertEqual(popup.applicationPopupRegion.text, "Austin, TX 78701")
        XCTAssertFalse(popup.applicationPhotoCarousel.isHidden)
        XCTAssertTrue(popup.applicationInviteImage.isHidden)
        XCTAssertEqual(selectedURLs(from: popup.applicationPhotoCarousel), [firstURL, secondURL])
    }

    func testEmptyListingDetailsKeepDefaultInviteAndHideOptionalLabels() async {
        let listingService = ControlledListingService()
        let controller = makeController(listingService: listingService)
        let submission = makeSubmission(type: "application")

        controller.loadViewIfNeeded()
        controller.showApartmentPopup(for: submission)
        await listingService.waitUntilRequestCount(1)
        await listingService.resolveNext(with: emptyListingDetails)
        await waitUntil { await listingService.completedRequestCount == 1 }

        let popup = tryUnwrap(controller.popupView)
        XCTAssertTrue(popup.applicationPopupBedrooms.isHidden)
        XCTAssertTrue(popup.applicationPopupBathrooms.isHidden)
        XCTAssertTrue(popup.applicationPopupRentAmount.isHidden)
        XCTAssertTrue(popup.applicationPopupRegion.isHidden)
        XCTAssertTrue(popup.applicationPhotoCarousel.isHidden)
        XCTAssertFalse(popup.applicationInviteImage.isHidden)
        XCTAssertEqual(
            popup.applicationPopupStreetAddress.text,
            "You have been invited to Apply to 123 Maple Street, unit-3, Austin, TX 78701"
        )
    }

    func testListingFailureReportsErrorAndKeepsFallbackContent() async {
        let errorReported = expectation(description: "Listing error reported")
        let controller = makeController(
            listingService: DemoApartmentListingService(error: TestError.expected),
            serviceErrorHandler: { _ in errorReported.fulfill() }
        )
        let submission = makeSubmission(type: "application")

        controller.loadViewIfNeeded()
        controller.showApartmentPopup(for: submission)
        await fulfillment(of: [errorReported], timeout: 1)

        let popup = tryUnwrap(controller.popupView)
        XCTAssertTrue(popup.applicationPopupBedrooms.isHidden)
        XCTAssertTrue(popup.applicationPhotoCarousel.isHidden)
        XCTAssertEqual(
            popup.applicationPopupStreetAddress.text,
            "You have been invited to Apply to 123 Maple Street, unit-3, Austin, TX 78701"
        )
    }

    func testReplacedPopupCannotReceiveStaleListingResult() async {
        let staleURL = URL(string: "https://example.com/stale.jpg")!
        let currentURL = URL(string: "https://example.com/current.jpg")!
        let listingService = ControlledListingService()
        let controller = makeController(listingService: listingService)
        let firstSubmission = makeSubmission(type: "application")
        let secondSubmission = makeSubmission(
            type: "prequalification",
            unitID: "unit-current"
        )

        controller.loadViewIfNeeded()
        controller.showApartmentPopup(for: firstSubmission)
        await listingService.waitUntilRequestCount(1)
        controller.showApartmentPopup(for: secondSubmission)
        await listingService.waitUntilRequestCount(2)

        await listingService.resolveRequest(
            at: 1,
            with: ApartmentListingDetails(
                bedroomCount: "3",
                bathroomCount: "2",
                monthlyRent: "3,000",
                photoURLs: [currentURL]
            )
        )
        let currentPopup = tryUnwrap(controller.popupView)
        await waitUntil { currentPopup.applicationPopupBedrooms.text == "3 Bedrooms" }

        await listingService.resolveRequest(
            at: 0,
            with: ApartmentListingDetails(
                bedroomCount: "99",
                bathroomCount: "99",
                monthlyRent: "99,999",
                photoURLs: [staleURL]
            )
        )
        await Task.yield()

        XCTAssertTrue(controller.popupView === currentPopup)
        XCTAssertEqual(currentPopup.applicationPopupBedrooms.text, "3 Bedrooms")
        XCTAssertEqual(selectedURLs(from: currentPopup.applicationPhotoCarousel), [currentURL])
    }

    func testMissingListingIdentifiersDoNotCallListingService() async {
        let listingService = ControlledListingService()
        let controller = makeController(listingService: listingService)
        let submission = makeSubmission(type: "application", ownerID: nil)

        controller.loadViewIfNeeded()
        controller.showApartmentPopup(for: submission)
        await Task.yield()

        let requestCount = await listingService.requestCount
        XCTAssertEqual(requestCount, 0)
        XCTAssertTrue(tryUnwrap(controller.popupView).applicationPhotoCarousel.isHidden)
    }

    func testApplicationStartCoordinatesStatusAndDestinationImmediately() async {
        let statusService = RecordingInviteStatusService()
        let controller = makeController(inviteStatusService: statusService)
        let popup = makePopup()
        let submission = makeSubmission(type: "application")
        let destination = ApplyHomeVC()
        var presentedViewControllers = [UIViewController]()
        controller.tenantCardSubmission = submission
        controller.makeApplyHomeViewController = { destination }
        controller.presentDestination = { presentedViewControllers.append($0) }

        controller.apartmentPopupViewDidRequestStart(popup)

        XCTAssertTrue(popup.isHidden)
        XCTAssertEqual(controller.hideTenantToDoAlertInvocationCount, 1)
        XCTAssertEqual(destination.tenantCardSubmission, submission)
        XCTAssertTrue(destination.homeVC === controller)
        XCTAssertEqual(destination.modalPresentationStyle, .fullScreen)
        XCTAssertTrue(presentedViewControllers.first === destination)

        await statusService.waitUntilUpdateCount(1)
        await assertSingleUpdate(on: statusService, status: .accepted, type: "application")
    }

    func testPrequalificationStartCoordinatesStatusAndDestination() async {
        let statusService = RecordingInviteStatusService()
        let controller = makeController(inviteStatusService: statusService)
        let popup = makePopup()
        let submission = makeSubmission(type: "prequalification")
        let destination = PrequalifyHomeVC()
        var presentedViewControllers = [UIViewController]()
        controller.tenantCardSubmission = submission
        controller.makePrequalifyHomeViewController = { destination }
        controller.presentDestination = { presentedViewControllers.append($0) }

        controller.apartmentPopupViewDidRequestStart(popup)

        XCTAssertTrue(popup.isHidden)
        XCTAssertEqual(destination.tenantCardSubmission, submission)
        XCTAssertEqual(destination.modalPresentationStyle, .fullScreen)
        XCTAssertTrue(presentedViewControllers.first === destination)

        await statusService.waitUntilUpdateCount(1)
        await assertSingleUpdate(on: statusService, status: .accepted, type: "prequalification")
    }

    func testIncompleteStartStillHidesUIWithoutUpdatingOrPresenting() async {
        let statusService = RecordingInviteStatusService()
        let controller = makeController(inviteStatusService: statusService)
        let popup = makePopup()
        let submission = makeSubmission(type: "application", ownerID: nil)
        var presentationCount = 0
        controller.tenantCardSubmission = submission
        controller.presentDestination = { _ in presentationCount += 1 }

        controller.apartmentPopupViewDidRequestStart(popup)
        await Task.yield()

        XCTAssertTrue(popup.isHidden)
        XCTAssertEqual(controller.hideTenantToDoAlertInvocationCount, 1)
        let updateCount = await statusService.updates.count
        XCTAssertEqual(updateCount, 0)
        XCTAssertEqual(presentationCount, 0)
    }

    func testUnsupportedCompleteStartUpdatesAcceptedWithoutPresenting() async {
        let statusService = RecordingInviteStatusService()
        let routeErrorReported = expectation(description: "Route error reported")
        let controller = makeController(
            inviteStatusService: statusService,
            serviceErrorHandler: { error in
                if let controllerError = error as? ApartmentPopupControllerError,
                   case .unsupportedSubmissionType = controllerError {
                    routeErrorReported.fulfill()
                }
            }
        )
        let popup = makePopup()
        var presentationCount = 0
        controller.tenantCardSubmission = makeSubmission(type: "unsupported")
        controller.presentDestination = { _ in presentationCount += 1 }

        controller.apartmentPopupViewDidRequestStart(popup)

        await fulfillment(of: [routeErrorReported], timeout: 1)
        await statusService.waitUntilUpdateCount(1)
        await assertSingleUpdate(on: statusService, status: .accepted, type: "unsupported")
        XCTAssertTrue(popup.isHidden)
        XCTAssertEqual(presentationCount, 0)
    }

    func testCompleteDismissUpdatesViewedAndHidesOnlyPopup() async {
        let statusService = RecordingInviteStatusService()
        let controller = makeController(inviteStatusService: statusService)
        let popup = makePopup()
        controller.tenantCardSubmission = makeSubmission(type: "application")

        controller.apartmentPopupViewDidRequestDismiss(popup)

        XCTAssertTrue(popup.isHidden)
        XCTAssertEqual(controller.hideTenantToDoAlertInvocationCount, 0)
        await statusService.waitUntilUpdateCount(1)
        await assertSingleUpdate(on: statusService, status: .viewed, type: "application")
    }

    func testIncompleteDismissHidesPopupWithoutUpdating() async {
        let statusService = RecordingInviteStatusService()
        let controller = makeController(inviteStatusService: statusService)
        let popup = makePopup()
        let submission = makeSubmission(type: "application", renterID: nil)
        controller.tenantCardSubmission = submission

        controller.apartmentPopupViewDidRequestDismiss(popup)
        await Task.yield()

        XCTAssertTrue(popup.isHidden)
        let updateCount = await statusService.updates.count
        XCTAssertEqual(updateCount, 0)
    }

    func testStatusFailureIsReportedWithoutUndoingNavigation() async {
        let statusService = RecordingInviteStatusService(error: TestError.expected)
        let errorReported = expectation(description: "Status error reported")
        let controller = makeController(
            inviteStatusService: statusService,
            serviceErrorHandler: { _ in errorReported.fulfill() }
        )
        let popup = makePopup()
        let destination = ApplyHomeVC()
        var presentedDestination: UIViewController?
        controller.tenantCardSubmission = makeSubmission(type: "application")
        controller.makeApplyHomeViewController = { destination }
        controller.presentDestination = { presentedDestination = $0 }

        controller.apartmentPopupViewDidRequestStart(popup)

        XCTAssertTrue(popup.isHidden)
        XCTAssertTrue(presentedDestination === destination)
        await fulfillment(of: [errorReported], timeout: 1)
        await assertSingleUpdate(on: statusService, status: .accepted, type: "application")
    }

    private var emptyListingDetails: ApartmentListingDetails {
        ApartmentListingDetails(
            bedroomCount: nil,
            bathroomCount: nil,
            monthlyRent: nil,
            photoURLs: []
        )
    }

    private func makeController(
        listingService: ApartmentListingLoading? = nil,
        inviteStatusService: RecordingInviteStatusService? = nil,
        serviceErrorHandler: @escaping (Error) -> Void = { _ in }
    ) -> DemoViewController {
        DemoViewController(
            listingService: listingService ?? DemoApartmentListingService(details: emptyListingDetails),
            inviteStatusService: inviteStatusService ?? RecordingInviteStatusService(),
            serviceErrorHandler: serviceErrorHandler
        )
    }

    private func makePopup() -> ApartmentPopupView {
        ApartmentPopupView(frame: CGRect(x: 0, y: 0, width: 414, height: 896))
    }

    private func makeSubmission(
        type: String,
        ownerID: String? = "owner-1",
        unitID: String? = "unit-3",
        renterID: String? = "renter-4"
    ) -> ApartmentPopupSubmission {
        ApartmentPopupSubmission(
            submissionType: type,
            ownerID: ownerID,
            propertyID: "property-2",
            unitID: unitID,
            renterID: renterID,
            address: "123 Maple Street",
            city: "Austin",
            state: "TX",
            zip: "78701"
        )
    }

    private func assertSingleUpdate(
        on service: RecordingInviteStatusService,
        status: InviteStatus,
        type: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let updates = await service.updates
        XCTAssertEqual(updates.count, 1, file: file, line: line)
        XCTAssertEqual(updates.first?.status, status, file: file, line: line)
        XCTAssertEqual(
            updates.first?.invite,
            InviteIdentifier(
                ownerID: "owner-1",
                propertyID: "property-2",
                unitID: "unit-3",
                renterID: "renter-4",
                submissionType: type
            ),
            file: file,
            line: line
        )
    }

    private func selectedURLs(from carousel: PhotoCarouselView) -> [URL] {
        let delegate = CarouselURLSelectionSpy()
        let collectionView: UICollectionView = tryUnwrap(carousel.firstDescendant())
        let itemCount = collectionView.dataSource?.collectionView(
            collectionView,
            numberOfItemsInSection: 0
        ) ?? 0
        carousel.delegate = delegate
        for index in 0..<itemCount {
            carousel.collectionView(collectionView, didSelectItemAt: IndexPath(item: index, section: 0))
        }
        return delegate.urls
    }

    private func waitUntil(
        file: StaticString = #filePath,
        line: UInt = #line,
        _ condition: @escaping @MainActor () async -> Bool
    ) async {
        for _ in 0..<100 {
            if await condition() { return }
            await Task.yield()
        }
        XCTFail("Condition was not satisfied", file: file, line: line)
    }

    private func tryUnwrap<T>(
        _ value: T?,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> T {
        guard let value else {
            XCTFail("Expected a \(T.self)", file: file, line: line)
            fatalError("Missing expected value")
        }
        return value
    }
}

private enum TestError: Error {
    case expected
}

private actor ControlledListingService: ApartmentListingLoading {
    private struct Request {
        let identifier: ApartmentListingIdentifier
        let continuation: CheckedContinuation<ApartmentListingDetails, Error>
    }

    private var requests = [Request]()
    private var completedRequests = 0
    private var waiters = [(count: Int, continuation: CheckedContinuation<Void, Never>)]()

    var requestCount: Int { requests.count }
    var completedRequestCount: Int { completedRequests }

    func loadListingDetails(
        for identifier: ApartmentListingIdentifier
    ) async throws -> ApartmentListingDetails {
        try await withCheckedThrowingContinuation { continuation in
            requests.append(Request(identifier: identifier, continuation: continuation))
            resumeSatisfiedWaiters()
        }
    }

    func waitUntilRequestCount(_ count: Int) async {
        guard requests.count < count else { return }
        await withCheckedContinuation { continuation in
            waiters.append((count, continuation))
        }
    }

    func resolveNext(with details: ApartmentListingDetails) {
        guard let index = requests.indices.first(where: { index in
            index >= completedRequests
        }) else { return }
        resolveRequest(at: index, with: details)
    }

    func resolveRequest(at index: Int, with details: ApartmentListingDetails) {
        requests[index].continuation.resume(returning: details)
        completedRequests += 1
    }

    private func resumeSatisfiedWaiters() {
        var pending = [(count: Int, continuation: CheckedContinuation<Void, Never>)]()
        for waiter in waiters {
            if requests.count >= waiter.count {
                waiter.continuation.resume()
            } else {
                pending.append(waiter)
            }
        }
        waiters = pending
    }
}

private final class ApartmentPopupDelegateSpy: ApartmentPopupViewDelegate {
    var startRequests = [ApartmentPopupView]()
    var dismissRequests = [ApartmentPopupView]()

    func apartmentPopupViewDidRequestStart(_ popupView: ApartmentPopupView) {
        startRequests.append(popupView)
    }

    func apartmentPopupViewDidRequestDismiss(_ popupView: ApartmentPopupView) {
        dismissRequests.append(popupView)
    }
}

private final class CarouselURLSelectionSpy: PhotoCarouselViewDelegate {
    var urls = [URL]()

    func photoCarouselView(
        _ carouselView: PhotoCarouselView,
        didSelect item: PhotoCarouselItem,
        at index: Int
    ) {
        if case .url(let url) = item {
            urls.append(url)
        }
    }
}

private extension UIView {
    func firstDescendant<T: UIView>(of type: T.Type = T.self) -> T? {
        if let match = self as? T {
            return match
        }
        for subview in subviews {
            if let match: T = subview.firstDescendant(of: type) {
                return match
            }
        }
        return nil
    }
}
