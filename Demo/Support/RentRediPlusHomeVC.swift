import UIKit

enum TenantToDoAlertType {
    case applicationInvite
}

class RentRediPlusHomeVC: UIViewController {
    var applicationPopup = UIView()
    var tenantCardSubmission: ApartmentPopupSubmission?
    var hasExistingInviteApplication = false
    private(set) var hideTenantToDoAlertInvocationCount = 0

    func hideTenantToDoAlert() {
        hideTenantToDoAlertInvocationCount += 1
    }
    func setupTenantToDoAlert() {}

    func applyPrequalifyVerb(noun: String) -> String {
        noun == "prequalification" ? "Prequalify" : "Apply"
    }

    func updateToDoAlert(
        title: String,
        description: String,
        type: TenantToDoAlertType
    ) {}
}
