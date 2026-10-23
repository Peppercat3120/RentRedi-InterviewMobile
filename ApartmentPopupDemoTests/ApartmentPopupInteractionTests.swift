import XCTest
import UIKit
@testable import ApartmentPopupDemo

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

    func testApplicationStartCoordinatesStatusAndDestination() {
        let controller = DemoViewController()
        let popup = makePopup()
        let submission = makeCompleteSubmission(type: "application")
        let destination = ApplyHomeVC()
        var presentedViewControllers = [UIViewController]()
        controller.tenantCardSubmission = submission
        controller.makeApplyHomeViewController = { destination }
        controller.presentDestination = { presentedViewControllers.append($0) }

        controller.apartmentPopupViewDidRequestStart(popup)

        XCTAssertTrue(popup.isHidden)
        XCTAssertEqual(controller.hideTenantToDoAlertInvocationCount, 1)
        assertSingleWrite(on: controller, status: "accepted", type: "application")
        XCTAssertTrue(destination.tenantCardSubmission === submission)
        XCTAssertTrue(destination.homeVC === controller)
        XCTAssertEqual(destination.modalPresentationStyle, .fullScreen)
        XCTAssertEqual(presentedViewControllers.count, 1)
        XCTAssertTrue(presentedViewControllers.first === destination)
    }

    func testPrequalificationStartCoordinatesStatusAndDestination() {
        let controller = DemoViewController()
        let popup = makePopup()
        let submission = makeCompleteSubmission(type: "prequalification")
        let destination = PrequalifyHomeVC()
        var presentedViewControllers = [UIViewController]()
        controller.tenantCardSubmission = submission
        controller.makePrequalifyHomeViewController = { destination }
        controller.presentDestination = { presentedViewControllers.append($0) }

        controller.apartmentPopupViewDidRequestStart(popup)

        XCTAssertTrue(popup.isHidden)
        XCTAssertEqual(controller.hideTenantToDoAlertInvocationCount, 1)
        assertSingleWrite(on: controller, status: "accepted", type: "prequalification")
        XCTAssertTrue(destination.tenantCardSubmission === submission)
        XCTAssertEqual(destination.modalPresentationStyle, .fullScreen)
        XCTAssertEqual(presentedViewControllers.count, 1)
        XCTAssertTrue(presentedViewControllers.first === destination)
    }

    func testIncompleteStartStillHidesUIWithoutWritingOrPresenting() {
        let controller = DemoViewController()
        let popup = makePopup()
        let submission = makeCompleteSubmission(type: "application")
        submission.ownerID = nil
        var presentationCount = 0
        controller.tenantCardSubmission = submission
        controller.presentDestination = { _ in presentationCount += 1 }

        controller.apartmentPopupViewDidRequestStart(popup)

        XCTAssertTrue(popup.isHidden)
        XCTAssertEqual(controller.hideTenantToDoAlertInvocationCount, 1)
        XCTAssertTrue(controller.ref.writes.isEmpty)
        XCTAssertEqual(presentationCount, 0)
    }

    func testUnsupportedCompleteStartWritesAcceptedWithoutPresenting() {
        let controller = DemoViewController()
        let popup = makePopup()
        var presentationCount = 0
        controller.tenantCardSubmission = makeCompleteSubmission(type: "unsupported")
        controller.presentDestination = { _ in presentationCount += 1 }

        controller.apartmentPopupViewDidRequestStart(popup)

        XCTAssertTrue(popup.isHidden)
        XCTAssertEqual(controller.hideTenantToDoAlertInvocationCount, 1)
        assertSingleWrite(on: controller, status: "accepted", type: "unsupported")
        XCTAssertEqual(presentationCount, 0)
    }

    func testCompleteDismissWritesViewedAndHidesOnlyPopup() {
        let controller = DemoViewController()
        let popup = makePopup()
        controller.tenantCardSubmission = makeCompleteSubmission(type: "application")

        controller.apartmentPopupViewDidRequestDismiss(popup)

        XCTAssertTrue(popup.isHidden)
        XCTAssertEqual(controller.hideTenantToDoAlertInvocationCount, 0)
        assertSingleWrite(on: controller, status: "viewed", type: "application")
    }

    func testIncompleteDismissHidesPopupWithoutWriting() {
        let controller = DemoViewController()
        let popup = makePopup()
        let submission = makeCompleteSubmission(type: "application")
        submission.renterID = nil
        controller.tenantCardSubmission = submission

        controller.apartmentPopupViewDidRequestDismiss(popup)

        XCTAssertTrue(popup.isHidden)
        XCTAssertEqual(controller.hideTenantToDoAlertInvocationCount, 0)
        XCTAssertTrue(controller.ref.writes.isEmpty)
    }

    private func makePopup() -> ApartmentPopupView {
        ApartmentPopupView(frame: CGRect(x: 0, y: 0, width: 414, height: 896))
    }

    private func makeCompleteSubmission(type: String) -> DemoTenantCardSubmission {
        let submission = DemoTenantCardSubmission(
            address: "123 Maple Street",
            unitID: "unit-3",
            city: "Austin",
            state: "TX",
            zip: "78701"
        )
        submission.submissionType = type
        submission.ownerID = "owner-1"
        submission.propertyID = "property-2"
        submission.renterID = "renter-4"
        return submission
    }

    private func assertSingleWrite(
        on controller: DemoViewController,
        status: String,
        type: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(controller.ref.writes.count, 1, file: file, line: line)
        XCTAssertEqual(
            controller.ref.writes.first?.path,
            "inviteTenant/owner-1property-2unit-3renter-4_\(type)/inviteStatus",
            file: file,
            line: line
        )
        XCTAssertEqual(controller.ref.writes.first?.value as? String, status, file: file, line: line)
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
