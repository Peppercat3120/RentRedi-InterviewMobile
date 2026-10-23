import UIKit

final class DemoViewController: RentRediPlusHomeVC {
    private var popupView: ApartmentPopupView?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        showMockApartment()
    }

    private func showMockApartment() {
        let submission = TenantCardSubmission(
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

        popup.updateViews()
        popup.applicationPopupBedrooms.text = "2 Bedrooms"
        popup.applicationPopupBathrooms.text = " • 2 Bathrooms"
        popup.applicationPopupRentAmount.text = "$2,450/month"
        popup.applicationPhotosUrls = DemoImageFactory.makeImageURLs()
        popup.showAndUpdateApplicationUnitAndPropertyPhotos()
    }
}
