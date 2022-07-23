import Foundation
import Alamofire
import SwiftyJSON

class ApartmentPopupView: UIView, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    private let apartmentPhotoReuseIdentifier = "apartmentPhotoCell"
    weak var delegate: RentRediPlusHomeVC?
    var applicationPhotosUrls = [URL]()
    var tenantCardSubmission: TenantCardSubmission?

    @IBOutlet weak var applicationPopupTitle: UILabel!
    @IBOutlet weak var applicationPopupBedrooms: UILabel!
    @IBOutlet weak var applicationPopupBathrooms: UILabel!
    @IBOutlet weak var applicationPopupStreetAddress: UILabel!
    @IBOutlet weak var applicationPopupRentAmount: UILabel!
    @IBOutlet weak var applicationPopupRegion: UILabel!
    @IBOutlet weak var applicationPopupPhotos: UICollectionView!
    @IBOutlet weak var applicationInviteImage: UIImageView!
    @IBOutlet weak var applicationPopupPageNumber: UILabel!
    @IBOutlet weak var applicationPhotoDots: UIPageControl!
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
        //set the collection delegate and datasource of the photos to self(update collection view when Apartment Popup view data updates)
        applicationPopupPhotos.delegate = self
        applicationPopupPhotos.dataSource = self
        applicationPopupPhotos.register(ApplicationApartmentPhotoCell.self, forCellWithReuseIdentifier: apartmentPhotoReuseIdentifier)
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
        self.addSubview(view)
    }
    //load view from nib named ApartmentPopupView
    func loadViewFromNib() -> UIView? {
        let nib = UINib(nibName: nibName, bundle: nil)
        return nib.instantiate(withOwner: self, options: nil).first as? UIView
    }
    //function for handling when user has scrolled in the scrollview, update the UI to let user know what photo they are on
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        //if the scrollview is application popup photos (no other scrollview is available)
        if scrollView == applicationPopupPhotos {
            //get page number of cell in view
            let pageNumber = Int((applicationPopupPhotos.contentOffset.x / applicationPopupPhotos.frame.width).rounded(.toNearestOrAwayFromZero))
            applicationPhotoDots.currentPage = pageNumber
            // set page number
            applicationPopupPageNumber.text = "\(pageNumber + 1) of \(applicationPhotosUrls.count)"

        }
    }
    // Set size of collection view items
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        //if the collection view is application popup photos (no other collection view is available)
        if collectionView == applicationPopupPhotos {
            // Set up CollectionView
            let width = collectionView.frame.width
            let height = collectionView.frame.height
            //Set size of collection view item to size of collectionView to take entire space
            return CGSize(width: width, height: height)
        }
        //Set default size
        return CGSize(width: 0, height: 0)
    }
    // Determine how many sections there are in collectionView, in this case 1
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        //application popup photos has 1 section
        return 1
    }
    // Determine how many items there are in collectionView
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //if the collection view is application popup photos (no other collection view is available)
        if collectionView == applicationPopupPhotos {
            //set the number of items equal to the number of photos
            applicationPhotoDots.numberOfPages = applicationPhotosUrls.count
            return applicationPhotosUrls.count
        }
        return 0
    }
    // Determine what kind of cell is in collection view
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        //if the collection view is application popup photos (no other collection view is available)
        if collectionView == applicationPopupPhotos {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: apartmentPhotoReuseIdentifier, for: indexPath) as! ApplicationApartmentPhotoCell

            let url = applicationPhotosUrls[indexPath.row]
            //if there is a photo that can be decoded from the data of the url
            let data = try? Data(contentsOf: url)
            //set imageview photo to corresponding apartment photo
            if let imageData = data {
                cell.apartmentPhoto.image = UIImage(data: imageData)
                //move the cell the the front of user's screen
                cell.bringSubviewToFront(cell.apartmentPhoto)
            }

            // Configure the cell
            return cell
        }
        //return application apartment photo cell
        return collectionView.dequeueReusableCell(withReuseIdentifier: apartmentPhotoReuseIdentifier, for: indexPath) as! ApplicationApartmentPhotoCell
    }

    //When a collection view item is clicked
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //do nothing because we dont need anything to be done when an apartment photo is clicked
        return
    }


    func updateViews() {
        //show popup asking if user wants to apply
        //update title
        applicationPopupTitle.text = "Invite to \(tenantCardSubmission?.verb.capitalizeFirstLetter() ?? "Apply")"
        //update the street address
        applicationPopupStreetAddress.text = "\(tenantCardSubmission?.address ?? "Error, Not Available"), Unit \(tenantCardSubmission?.unitID ?? "")"
        //update the region
        applicationPopupRegion.text = "\(tenantCardSubmission?.city ?? ""), \(tenantCardSubmission?.state ?? "") \(tenantCardSubmission?.zip ?? "")"
        //let delegate know there is an invite application so it can handle what UI does
        delegate?.hasExistingInviteApplication = true
        //set the title of the start button in application popup
        startApplicationButton.setTitle(delegate?.applyPrequalifyVerb(noun: tenantCardSubmission?.submissionType ?? "").capitalizeFirstLetter(), for: .normal)
            delegate?.setupTenantToDoAlert()
        //update the alert message
        delegate?.updateToDoAlert(title: "You have been invited to \(tenantCardSubmission?.verb.capitalizeFirstLetter() ?? "Apply")) to \(tenantCardSubmission?.fullAddress ?? "").", description: "Tap to start, or go to '\(tenantCardSubmission?.submissionType ?? "")'", type: .applicationInvite)
    }

    func fetchListingDetails(ownerID: String, propertyID: String, unitID: String) {
        //fetch photos, numbers of bedrooms/bathrooms and rent for unit
        fetchListingPhotos(ownerID: ownerID, propertyID: propertyID, unitID: unitID)
        fetchListingBedrooms(ownerID: ownerID, propertyID: propertyID, unitID: unitID)
        fetchListingBathrooms(ownerID: ownerID, propertyID: propertyID, unitID: unitID)
        fetchListingMonthlyRent(ownerID: ownerID, propertyID: propertyID, unitID: unitID)
    }

    func fetchListingBathrooms(ownerID: String, propertyID: String, unitID: String) {
        //read from firebase the number of bedrooms for listing
        DatabaseFunctions().readOnceFromFirebaseAndReturnString(pathToValue: "allUsers/ownerProfiles/\(ownerID)/profile/properties/\(propertyID)/units/\(unitID)/unitDetails/numberOfBathrooms") { (numberOfBathrooms) in
            // set bathroom UI on main thread
            DispatchQueue.main.async {
                //if number of bathrooms was retrieved from firebase
                if numberOfBathrooms != "" {
                    // show bathrooms text because data was found for listing
                    self.applicationPopupBathrooms.isHidden = false
                    //write number of bathrooms
                    self.applicationPopupBathrooms.text = " • \(numberOfBathrooms) Bathrooms"
                // else hide bathrooms text because no data was found
                } else {
                    self.applicationPopupBathrooms.isHidden = true
                }
            }
        }
    }

    func fetchListingBedrooms(ownerID: String, propertyID: String, unitID: String) {
        //read from firebase the number of bathrooms for listing
        DatabaseFunctions().readOnceFromFirebaseAndReturnString(pathToValue: "allUsers/ownerProfiles/\(ownerID)/profile/properties/\(propertyID)/units/\(unitID)/unitDetails/numberOfBedrooms") { (numberOfBedrooms) in
            // set bedroom UI on main thread
            DispatchQueue.main.async {
                //if number of bedrooms was retrieved from firebase
                if numberOfBedrooms != "" {
                    // show bedrooms text
                    self.applicationPopupBedrooms.isHidden = false
                    //write number of bedrooms
                    self.applicationPopupBedrooms.text = "\(numberOfBedrooms) Bedrooms"
                // else hide bedrooms text because no data was found
                } else {
                    self.applicationPopupBedrooms.isHidden = true
                }
            }
        }
    }

    func fetchListingMonthlyRent(ownerID: String, propertyID: String, unitID: String) {
        //read from firebase the rent for listing
        DatabaseFunctions().readOnceFromFirebaseAndReturnString(pathToValue: "allUsers/ownerProfiles/\(ownerID)/profile/properties/\(propertyID)/units/\(unitID)/unitDetails/listingMonthlyRent") { (monthlyRent) in
            DispatchQueue.main.async {
                //if a rent amount was returned
                if monthlyRent != "" {
                    //show rent text
                    self.applicationPopupRentAmount.isHidden = false
                    //set rent
                    self.applicationPopupRentAmount.text = "$\(monthlyRent)/month"
                // else the rent was not defined, so hide the rent
                } else {
                    //hide rent
                    self.applicationPopupRentAmount.isHidden = true
                }
            }
        }
    }

    func fetchListingPhotos(ownerID: String, propertyID: String, unitID: String) {
        //reset photos
        applicationPhotosUrls = []
        //read from firebase the photos for listing
        DatabaseFunctions().readOnceFromFirebaseAndReturnJSON(pathToValue: "allUsers/ownerProfiles/\(ownerID)/profile/properties/\(propertyID)/units/\(unitID)/unitDetails/photos") { (apartmentPhotos) in
            //if photo urls were found
            if (apartmentPhotos != [:]) {
                // set photo urls
                for (_,value):(String, JSON) in apartmentPhotos {
                    let downloadURL = value["downloadURL"].stringValue
                    if let downloadURL = URL(string: downloadURL) {
                        //add url to array
                        self.applicationPhotosUrls.append(downloadURL)
                    }
                }
                self.showAndUpdateApplicationUnitAndPropertyPhotos()
            //else no listing photos found, show default photo
            } else if apartmentPhotos.isEmpty && self.applicationPhotosUrls.isEmpty {
                self.showDefaultApplicationInvite()
            }
        }
        //fetch property photos
        self.fetchPropertyPhotos(ownerID: ownerID, propertyID: propertyID)
    }

    func fetchPropertyPhotos(ownerID: String, propertyID: String) {
        //read from firebase the property photos for listing
        DatabaseFunctions().readOnceFromFirebaseAndReturnJSON(pathToValue: "allUsers/ownerProfiles/\(ownerID)/profile/properties/\(propertyID)/propertyDetails/photos") { (propertyPhotos) in
            if (propertyPhotos != [:]) {
                // set photo urls
                for (_,value):(String, JSON) in propertyPhotos {
                    let downloadURL = value["downloadURL"].stringValue
                    if let downloadURL = URL(string: downloadURL) {
                        self.applicationPhotosUrls.append(downloadURL)
                    }
                }
                self.showAndUpdateApplicationUnitAndPropertyPhotos()
            //no listing or property photos were found, show default photo
            } else if propertyPhotos.isEmpty && self.applicationPhotosUrls.isEmpty {
                self.showDefaultApplicationInvite()
            }
        }
    }

    func showAndUpdateApplicationUnitAndPropertyPhotos() {
        //if application photo urls is not empty
        if !self.applicationPhotosUrls.isEmpty {
            //Run on main thread
            DispatchQueue.main.async {
                // show apartment photos collection view, dots and reload data
                self.applicationPhotoDots.isHidden = false
                self.applicationPopupPhotos.isHidden = false
                self.applicationPopupRegion.isHidden = false
                //show photos in main thread by reloading data
                self.applicationPopupPhotos.reloadData()
                //set page number to 1
                self.applicationPopupPageNumber.text = "1 of \(self.applicationPhotosUrls.count)"
            }
        }
    }

    func showDefaultApplicationInvite() {
        // set default photos
        DispatchQueue.main.async {
            //show default image
            self.applicationInviteImage.isHidden = false
            //hide photo dots and unit/property photos
            self.applicationPhotoDots.isHidden = true
            self.applicationPopupPhotos.isHidden = true
            //hide page number since we are showing default image
            self.applicationPopupPageNumber.isHidden = true
            //set default message
            self.applicationPopupStreetAddress.text = "You have been invited to \(self.tenantCardSubmission?.verb.capitalizeFirstLetter() ?? "Apply") to \(self.tenantCardSubmission?.fullAddress ?? "an unknown address")"
            //hide region (since region/state is already included in the `fullAddress` in the `applicationPopupStreetAddress.text`)
            self.applicationPopupRegion.isHidden = true
        }
    }
}
