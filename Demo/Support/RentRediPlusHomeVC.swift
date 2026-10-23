import UIKit

enum TenantToDoAlertType {
    case applicationInvite
}

class RentRediPlusHomeVC: UIViewController {
    var applicationPopup = UIView()
    var tenantCardSubmission: DemoTenantCardSubmission?
    var hasExistingInviteApplication = false
    let ref = MockDatabaseReference()

    func hideTenantToDoAlert() {}
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
