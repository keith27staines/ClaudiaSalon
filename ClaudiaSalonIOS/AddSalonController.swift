//
//  AddSalonController.swift
//  ClaudiaSalon
//
//  Created by Keith Staines on 15/04/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

import UIKit
import CloudKit

class AddSalonController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var emailAddressField: UITextField!
    
    @IBOutlet weak var passwordField: UITextField!
    
    @IBOutlet weak var salonIDField: UITextField!
    
    @IBOutlet weak var salonNameLabel: UILabel!
    
    @IBOutlet weak var addressLine1Label: UILabel!
    
    @IBOutlet weak var addressLine2Label: UILabel!
    
    @IBOutlet weak var addressLine3Label: UILabel!
    
    @IBOutlet weak var managerLabel: UILabel!
    
    @IBOutlet weak var findSalonDetailsButton: UIButton!
    
    @IBOutlet weak var addThisSalonButton: UIButton!
    
    var completion:((sender:AddSalonController)->Void)?
    
    var salonRecordName:String?
    var salonName: String? = "New Salon"
    
    @IBAction func cancelButtonTapped(sender: AnyObject) {
        self.salonRecordName = nil
        self.salonName = nil
        self.dismissController()
    }
    
    @IBAction func findDetailsTapped(sender: AnyObject) {
        self.performFetchSalon()
    }
    
    @IBAction func addThisTapped(sender: AnyObject) {
        self.dismissController()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.clearSalonDetails()
        self.clearUserInputs()
        self.enableFindDetailsButtonIfAppropriate()
    }
    
    func dismissController() {
        self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
        self.completion?(sender: self)
    }
    
    func performFetchSalon() {
        self.salonRecordName = self.salonIDField.text
        let containerID = Coredata.cloudContainerID
        let container = CKContainer(identifier: containerID)
        let cloudDB = container.publicCloudDatabase
        let recordID = CKRecordID(recordName: self.salonRecordName!)
        cloudDB.fetchRecordWithID(recordID) { record, error in
            NSOperationQueue.mainQueue().addOperationWithBlock() {
                guard let record = record else {
                    let error = error!
                    let errorCode = CKErrorCode(rawValue: error.code)!
                    switch errorCode {
                    case .UnknownItem:
                        self.displayError("Salon not found",message: "Please re-enter the salon ID and try again",targetView: self.salonIDField)
                        self.findSalonDetailsButton.enabled = false
                    case .NetworkFailure, .NetworkUnavailable:
                        self.displayError("Unable to retrieve details", message: "The network is unavailable. Please try later when you have a good internet connection", targetView: self.findSalonDetailsButton)
                    case .NotAuthenticated:
                        self.displayError("Salon not found",message: "Please ensure you are signed in to iCloud",targetView: self.salonIDField)
                    default:
                        self.displayError("Unexpected error",message: "The salon could not be found. The error was: \(error)",targetView: self.salonIDField)
                    }
                    return
                }
                self.populateSalonDetails(record)
            }
        }
    }
    
    func displayError(title:String,message:String,targetView:UIView) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .ActionSheet)
        alert.popoverPresentationController?.sourceView = targetView
        alert.popoverPresentationController?.sourceRect = targetView.bounds
        self.presentViewController(alert, animated: true) {}
    }
    
    func clearUserInputs() {
        self.emailAddressField.text = ""
        self.passwordField.text = ""
        self.salonIDField.text = ""
    }
    
    func clearSalonDetails() {
        self.salonNameLabel.text = " "
        self.addressLine1Label.text = " "
        self.addressLine2Label.text = " "
        self.addressLine3Label.text = " "
        self.managerLabel.text = " "
        self.addThisSalonButton.enabled = false
    }
    
    func populateSalonDetails(record:CKRecord) {
        self.salonName = record["name"] as? String ?? "New Salon"
        self.salonNameLabel.text = self.salonName
        self.addressLine1Label.text = record["addressLine1"] as? String
        self.addressLine2Label.text = record["addressLine2"] as? String
        self.addressLine3Label.text = record["postcode"] as? String
        self.managerLabel.text = "Claudia Erickson" //record["Unknown manager"] as? String
        self.addThisSalonButton.enabled = true
        self.findSalonDetailsButton.enabled = false
    }
    
    func enableFindDetailsButtonIfAppropriate() {
        var enableButton = true
        if !self.isValidEmail() { enableButton = false }
        if self.passwordField.text?.characters.count < 5 { enableButton = false }
        if self.salonIDField.text?.characters.count < 16 { enableButton = false }
        self.findSalonDetailsButton.enabled = enableButton
    }
    
    func isValidEmail() -> Bool {
        guard let emailString = self.emailAddressField.text else {
            return false
        }
        return emailString.isValidEmail()
    }
}


// UITextFieldDelegate
extension AddSalonController {
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        self.clearSalonDetails()
        self.enableFindDetailsButtonIfAppropriate()
        return true
    }
    
    func textFieldShouldClear(textField: UITextField) -> Bool {
        self.findSalonDetailsButton.enabled = false
        return true
    }

}

extension String {
    func isValidEmail() -> Bool {
        do {
            let regex = try NSRegularExpression(pattern: "^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$", options: .CaseInsensitive)
            return regex.firstMatchInString(self, options: NSMatchingOptions(rawValue: 0), range: NSMakeRange(0, self.characters.count)) != nil
        } catch {
            return false
        }
    }
}


