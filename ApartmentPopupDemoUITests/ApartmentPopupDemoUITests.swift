import XCTest

final class ApartmentPopupDemoUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testBothDemoRoutesExposeSwipeableCarousels() {
        XCTAssertTrue(element("demoMenuScreen").waitForExistence(timeout: 5))

        app.buttons["openMaintenanceDemoButton"].tap()
        XCTAssertTrue(element("maintenanceRequestScreen").waitForExistence(timeout: 5))
        let maintenanceCarousel = element("maintenancePhotoCarousel")
        XCTAssertTrue(maintenanceCarousel.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["1 of 3"].waitForExistence(timeout: 5))
        maintenanceCarousel.swipeLeft()
        XCTAssertTrue(app.staticTexts["2 of 3"].waitForExistence(timeout: 5))

        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(element("demoMenuScreen").waitForExistence(timeout: 5))

        app.buttons["openApartmentDemoButton"].tap()
        XCTAssertTrue(element("apartmentPopup").waitForExistence(timeout: 5))
        let apartmentCarousel = element("apartmentPhotoCarousel")
        XCTAssertTrue(apartmentCarousel.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["1 of 3"].waitForExistence(timeout: 5))
        apartmentCarousel.swipeLeft()
        XCTAssertTrue(app.staticTexts["2 of 3"].waitForExistence(timeout: 5))
    }

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }
}
