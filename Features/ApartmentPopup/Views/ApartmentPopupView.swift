import Foundation
import UIKit

@MainActor
protocol ApartmentPopupViewDelegate: AnyObject {
    func apartmentPopupViewDidRequestStart(_ popupView: ApartmentPopupView)
    func apartmentPopupViewDidRequestDismiss(_ popupView: ApartmentPopupView)
}

class ApartmentPopupView: UIView {

    weak var delegate: ApartmentPopupViewDelegate?

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
        delegate?.apartmentPopupViewDidRequestStart(self)
    }
    @IBAction func dismissApplicationTapped(_ sender: Any) {
        delegate?.apartmentPopupViewDidRequestDismiss(self)
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
        case .photos(let items):
            applicationInviteImage.isHidden = true
            applicationPhotoCarousel.isHidden = false
            applicationPhotoCarousel.setContent(.items(items), initialPage: 0)
        case .defaultInvite:
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

}
