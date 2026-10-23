import Foundation

#if canImport(SwiftyJSON)
import SwiftyJSON

// Transitional Stage 5 extraction boundary for the existing listing-loading path.
extension ApartmentPopupView {
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
}
#endif
