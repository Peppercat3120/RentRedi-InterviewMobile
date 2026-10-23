import Foundation
import UIKit
import Firebase
import SwiftyJSON

public class TenantCardSubmission {
    var tenantCardSubmissionIDForRenter: String? // tenantCardSubmissionID under the renter's branch
    var unitCode: String?
    var ownerID: String?
    var propertyID: String?
    var transUnionApplicationID: Int?
    var transUnionScreeningRequestID: Int?
    var transUnionScreeningRequestRenterID: Int?
    var leaseStartDate : TimeInterval = 0
    var leaseEndDate : TimeInterval = 0
    var monthlyRent : String = ""
    var address: String?
    var unitID: String?
    var city: String?
    var state: String?
    var zip: String?
    var applicationFee : String = ""
    var guarantorApplicationFee : String = ""
    var timestamp = Double()
    var status: String?
    var submissionType: String?
    var renterID: String?
    var linkedApplicationID: String?
    var linkedPrequalificationID: String?
    var tenantCardSubmissionIDForLandlord: String? // tenantCardSubmissionID under the landlord's branch
    var expanded: Bool
    var tenantScreeningComplete: Bool
    var renterEmail: String?
    var fullAddress: String {
        return "\(address ?? ""), \(unitID ?? ""), \(city ?? ""), \(state  ?? ""), \(zip ?? "")"
    }

    var verb: String {
        switch submissionType {
            case "application": return "apply"
            case "prequalification": return "prequalify"
            default: return "apply"
        }
    }

    var branch : [String: AnyObject]?

    // reference to firebase database
    let ref = Database.database().reference()

    init?(snapshot: DataSnapshot) {
        self.branch = snapshot.value as? [String: AnyObject]
        self.transUnionApplicationID = branch?["applicationID"] as? Int
        self.transUnionScreeningRequestID = branch?["transUnionScreeningRequestID"] as? Int
        self.transUnionScreeningRequestRenterID = branch?["transUnionScreeningRequestRenterID"] as? Int
        self.renterEmail = branch?["renterEmail"] as? String
        self.unitCode = branch?["unitCode"] as? String
        self.ownerID = branch?["ownerID"] as? String
        self.propertyID = branch?["propertyID"] as? String
        self.unitID = branch?["unitID"] as? String
        self.renterID = branch?["renterID"] as? String
        self.tenantCardSubmissionIDForRenter = snapshot.key
        self.tenantCardSubmissionIDForLandlord = branch?["tenantCardSubmissionID"] as? String
        self.city = branch?["city"] as? String ?? ""
        self.state = branch?["state"] as? String ?? ""
        self.zip = branch?["zip"] as? String ?? ""
        self.timestamp = branch?["timestamp"] as? Double ?? 0
        self.status = branch?["status"] as? String? ?? "Draft"
        self.submissionType = branch?["submissionType"] as? String
        self.expanded = false
        self.tenantScreeningComplete = branch?["tenantScreeningComplete"] as? Bool ?? false
        self.monthlyRent = branch?["monthlyRent"] as? String ?? ""
        self.leaseStartDate = branch?["leaseStartDate"] as? Double ?? 0
        self.leaseEndDate = branch?["leaseEndDate"] as? Double ?? 0
        self.applicationFee = branch?["applicationFee"] as? String ?? ""
        self.guarantorApplicationFee = branch?["guarantorApplicationFee"] as? String ?? ""
        self.address = branch?["address"] as? String ?? "Tap to load"
        self.city = branch?["city"] as? String ?? "Tap to load"
        self.zip = branch?["zip"] as? String ?? "Tap to load"
        self.state = branch?["state"] as? String ?? "Tap to load"
        self.transUnionApplicationID = branch?["transUnionApplicationID"] as? Int ?? nil
        self.renterEmail = branch?["renterEmail"] as? String ?? nil
        self.linkedPrequalificationID = branch?["linkedPrequalificationID"] as? String ?? nil
        self.linkedApplicationID = branch?["linkedApplicationID"] as? String ?? nil

    }

    func setCompleteAddress() {
        setAddress(for: "address", branch: branch) { (address) in
            self.address = address
        }
        setAddress(for: "city", branch: branch) { (city) in
            self.city = city
        }
        setAddress(for: "state", branch: branch) { (state) in
            self.state = state
        }
        setAddress(for: "zip", branch: branch) { (zip) in
            self.zip = zip
        }
    }

    func setAddress(for key: String, branch: [String: AnyObject]?, completion: @escaping (String) -> ()) {
        // if address is found, set the address
        if let value = branch?[key] as? String {
            completion(value)
        } else {
            // unwrap the ownerID and propertyID
            if let ownerID = branch?["ownerID"] as? String, let propertyID = branch?["propertyID"] as? String, let userID = Auth.auth().currentUser?.uid, let tenantCardSubmissionIDForRenter = tenantCardSubmissionIDForRenter {
                // if key is zip, call zipCode to landlord branch
                var landlordKey = key
                if (landlordKey == "zip") {
                    landlordKey = "zipCode"
                }
                // fetch the address
                ref.child("allUsers").child("ownerProfiles").child(ownerID).child("profile").child("properties").child(propertyID).child("propertyDetails").child(landlordKey).observeSingleEvent(of: .value) { (addressSnapshot) in
                    DatabaseFunctions().log(message: addressSnapshot)
                    // if the address was found, set the adress
                    if let value = addressSnapshot.value as? String {
                        // set the address (if not found, set "Error")
                        // set the address to firebase
                        self.ref.child("allUsers").child("renterProfiles").child(userID).child("tenantCardSubmissions").child(tenantCardSubmissionIDForRenter).child(key).setValue(value)
                        completion(value)
                        // else set "Error" (address not found)
                    } else {
                        completion("Error: Address not found")
                    }
                }
                // else, if unable to unwrap ownerID and propertyID, then set "Errror"
            } else {
                completion("Error: Owner and Property ID not found")
            }
        }
    }

    init(tenantCardSubmissionIDForRenter: String?, unitCode: String?, ownerID: String?, propertyID: String?, unitID: String?, renterID: String?, tenantCardSubmissionID: String?, address: String?, city: String?, state: String?, zip: String?, status: String?, submissionType: String?, monthlyRent: String?, leaseStartDate: TimeInterval, leaseEndDate: TimeInterval, applicationFee: String, guarantorApplicationFee: String, timestamp: Double, transUnionApplicationID: Int?, transUnionScreeningRequestID: Int?, transUnionScreeningRequestRenterID: Int?, renterEmail: String?, tenantScreeningComplete: Bool, linkedApplicationID: String?, linkedPrequalificationID: String?) {
        self.tenantCardSubmissionIDForRenter = tenantCardSubmissionIDForRenter
        self.unitCode = unitCode
        self.ownerID = ownerID
        self.propertyID = propertyID
        self.unitID = unitID
        self.renterID = renterID
        self.address = address
        self.city = city
        self.state = state
        self.zip = zip
        self.status = status ?? "draft"
        self.submissionType = submissionType
        self.expanded = false
        self.tenantScreeningComplete = tenantScreeningComplete
        self.tenantCardSubmissionIDForLandlord = tenantCardSubmissionID
        self.monthlyRent = monthlyRent ?? ""
        self.leaseStartDate = leaseStartDate
        self.leaseEndDate = leaseEndDate
        self.applicationFee = applicationFee
        self.guarantorApplicationFee = guarantorApplicationFee
        self.timestamp = timestamp
        self.transUnionApplicationID = transUnionApplicationID
        self.transUnionScreeningRequestID = transUnionScreeningRequestID
        self.transUnionScreeningRequestRenterID = transUnionScreeningRequestRenterID
        self.renterEmail = renterEmail
        self.linkedApplicationID = linkedApplicationID
        self.linkedPrequalificationID = linkedPrequalificationID
    }

    func getJSON() -> JSON {

        var json = JSON([
            "unitCode": unitCode as Any,
            "ownerID": ownerID,
            "propertyID": propertyID,
            "leaseStartDate": leaseStartDate,
            "leaseEndDate": leaseEndDate,
            "monthlyRent": monthlyRent,
            "address": address,
            "unitID": unitID,
            "city": city,
            "state": state,
            "zip": zip,
            "renterID": renterID,
            "tenantScreeningComplete": tenantScreeningComplete,
            "applicationFee": applicationFee,
            "guarantorApplicationFee": guarantorApplicationFee,
            "timestamp": timestamp,
            "status": status,
            "submissionType": submissionType,
            "transUnionApplicationID": transUnionApplicationID,
            "renterEmail": renterEmail,
            "tenantCardSubmissionID": tenantCardSubmissionIDForRenter
        ])

        if let linkedApplicationID = linkedApplicationID {
            json["linkedApplicationID"].string = linkedApplicationID
        }

        if let linkedPrequalificationID = linkedPrequalificationID {
            json["linkedPrequalificationID"].string = linkedPrequalificationID
        }

        return json
    }
}

protocol TenantCardSubmissionReciever {
    func recieve(tenantCardSubmission: TenantCardSubmission)
}
