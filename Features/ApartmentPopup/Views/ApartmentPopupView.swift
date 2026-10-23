import Foundation
import UIKit
// Original dependency import (not available in the standalone demo): import Alamofire
// Original dependency import (not available in the standalone demo): import SwiftyJSON

class ApartmentPopupView: UIView {

    weak var delegate: RentRediPlusHomeVC?
    var applicationPhotosUrls = [URL]()
    var tenantCardSubmission: DemoTenantCardSubmission?

    @IBOutlet weak var applicationPopupTitle: UILabel!
    @IBOutlet weak var applicationPopupBedrooms: UILabel!
    @IBOutlet weak var applicationPopupBathrooms: UILabel!
    @IBOutlet weak var applicationPopupStreetAddress: UILabel!
    @IBOutlet weak var applicationPopupRentAmount: UILabel!
    @IBOutlet weak var applicationPopupRegion: UILabel!
    @IBOutlet weak var applicationPhotoCarousel: PhotoCarouselView!
    @IBOutlet weak var applicationInviteImage: UIImageView!
    @IBOutlet weak var startApplicationButton: roundedButton!
    @IBAction func startApplicationTapped(_ sender: Any) {
        //hide popups
        delegate?.applicationPopup.isHidden = true
        delegate?.hideTenantToDoAlert()
        //if tenant card is created
        if let tenantCardSubmission = self.delegate?.tenantCardSubmission, let submissionType = tenantCardSubmission.submissionType, let ownerID = tenantCardSubmission.ownerID, let propertyID = tenantCardSubmission.propertyID, let unitID = tenantCardSubmission.unitID, let renterID = tenantCardSubmission.renterID {
                //set status as accepted
            self.delegate?.ref.child("inviteTenant").child("\(ownerID)\(propertyID)\(unitID)\(renterID)_\(submissionType)").child("inviteStatus").setValue("accepted")

            //continue existing invite application
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            //depending on the submission type of the tenant card submission
            switch tenantCardSubmission.submissionType {
            //if the tenant card submission type is an application
            case "application":
                let vc = storyboard.instantiateViewController(withIdentifier: "applyHomeScreen") as! ApplyHomeVC
                vc.modalPresentationStyle = .fullScreen
                vc.tenantCardSubmission = tenantCardSubmission
                vc.homeVC = self.delegate
                //have the delegate(homeVC) present apply home screen
                self.delegate?.present(vc, animated: true, completion: nil)
            //if the tenant card submission type is an prequalification
            case "prequalification":
                let vc = storyboard.instantiateViewController(withIdentifier: "prequalifyHomeScreen") as! PrequalifyHomeVC
                vc.modalPresentationStyle = .fullScreen
                vc.tenantCardSubmission = tenantCardSubmission
                //have the delegate(homeVC) present prequalify home screen
                self.delegate?.present(vc, animated: true, completion: nil)
            //else it is an unknow type
            default:
                //there was no submission type, log the error
                DatabaseFunctions().log(message: "Error: No submission type found")
                return
            }
        }
    }
    @IBAction func dismissApplicationTapped(_ sender: Any) {
        // if the variables necessary for updating the inviteStatus are present, then set the status as viewed
        if let tenantCardSubmission = self.delegate?.tenantCardSubmission, let submissionType = tenantCardSubmission.submissionType, let ownerID = tenantCardSubmission.ownerID, let propertyID = tenantCardSubmission.propertyID, let unitID = tenantCardSubmission.unitID, let renterID = tenantCardSubmission.renterID {
                //set status as viewed
            self.delegate?.ref.child("inviteTenant").child("\(ownerID)\(propertyID)\(unitID)\(renterID)_\(submissionType)").child("inviteStatus").setValue("viewed")
        }
        //hide the application popup
        delegate?.applicationPopup.isHidden = true
    }

    let nibName = "ApartmentPopupView"

    //functions for initializing this nib

    //required init function
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    //override the default initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        //run custom initializer
        commonInit()
    }

    //custom initializer
    func commonInit() {
        guard let view = loadViewFromNib() else { return }
        view.frame = self.bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.addSubview(view)
    }
    //load view from nib named ApartmentPopupView
    func loadViewFromNib() -> UIView? {
        let nib = UINib(nibName: nibName, bundle: nil)
        return nib.instantiate(withOwner: self, options: nil).first as? UIView
    }

    func configure(with content: ApartmentPopupContent) {
        applicationPopupTitle.text = content.title
        setOptionalText(content.bedroomText, on: applicationPopupBedrooms)
        setOptionalText(content.bathroomText, on: applicationPopupBathrooms)
        applicationPopupStreetAddress.text = content.addressText
        applicationPopupStreetAddress.isHidden = false
        setOptionalText(content.regionText, on: applicationPopupRegion)
        setOptionalText(content.rentText, on: applicationPopupRentAmount)
        startApplicationButton.setTitle(content.primaryActionTitle, for: .normal)

        switch content.media {
        case .photos(let items) where !items.isEmpty:
            applicationInviteImage.isHidden = true
            applicationPhotoCarousel.isHidden = false
            applicationPhotoCarousel.setContent(.items(items), initialPage: 0)
        case .photos, .defaultInvite:
            applicationPhotoCarousel.setContent(.empty)
            applicationPhotoCarousel.isHidden = true
            applicationInviteImage.isHidden = false
            applicationPopupRegion.isHidden = true
        }
    }

    private func setOptionalText(_ text: String?, on label: UILabel) {
        label.text = text
        label.isHidden = text == nil
    }

    func showAndUpdateApplicationUnitAndPropertyPhotos() {
        //if application photo urls is not empty
        if !self.applicationPhotosUrls.isEmpty {
            //Run on main thread
            DispatchQueue.main.async {
                // show apartment photos and update the carousel
                self.applicationInviteImage.isHidden = true
                self.applicationPhotoCarousel.isHidden = false
                self.applicationPopupRegion.isHidden = false
                let items = self.applicationPhotosUrls.map(PhotoCarouselItem.url)
                self.applicationPhotoCarousel.setContent(.items(items), initialPage: 0)
            }
        }
    }

    func showDefaultApplicationInvite() {
        // set default photos
        DispatchQueue.main.async {
            //show default image
            self.applicationInviteImage.isHidden = false
            //hide and clear unit/property photos
            self.applicationPhotoCarousel.setContent(.empty)
            self.applicationPhotoCarousel.isHidden = true
            //set default message
            self.applicationPopupStreetAddress.text = "You have been invited to \(self.tenantCardSubmission?.verb.capitalizeFirstLetter() ?? "Apply") to \(self.tenantCardSubmission?.fullAddress ?? "an unknown address")"
            //hide region (since region/state is already included in the `fullAddress` in the `applicationPopupStreetAddress.text`)
            self.applicationPopupRegion.isHidden = true
        }
    }
}
