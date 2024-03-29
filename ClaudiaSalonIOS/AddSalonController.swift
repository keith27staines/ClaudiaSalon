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
    
    @IBOutlet weak var salonDetailsStack: UIStackView!
    @IBOutlet weak var cancelButton: UIButton!
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
    var allowCancel = false
    var salonRecordName:String?
    var trialRecordName:String?
    var salonName: String? = "New Salon"
    var activeTextField: UITextField? = nil
    var keyboardDisplacement:CGFloat = 0
    
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
    
    override func viewDidLoad() {
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(AddSalonController.handleTap(_:)))
        self.view.addGestureRecognizer(tapRecognizer)
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.hideSalonDetails(true)
    }
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.addKeyboardObservers()
        self.clearSalonDetails()
        self.clearUserInputs()
        self.enableFindDetailsButtonIfAppropriate()
        self.cancelButton.hidden = !self.allowCancel
        self.hideSalonDetails(true)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.removeKeyboardObservers()
    }
    
    func hideSalonDetails(hidden:Bool) {
        self.salonDetailsStack.hidden = hidden
        self.addThisSalonButton.hidden = hidden
    }
    
    func dismissController() {
        self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
        self.completion?(sender: self)
    }
    
    func handleTap(sender:UITapGestureRecognizer) {
        if sender.state == .Ended {
            self.dismissKeyboard()
        }
    }
    
    func dismissKeyboard(control: UIControl? = nil) {
        if activeTextField != nil {
            activeTextField?.resignFirstResponder()
        }
    }
    
    func performFetchSalon() {
        self.salonRecordName = nil
        let trialRecordName = self.salonIDField.text ?? ""
        guard trialRecordName.characters.count > 16 else {
            self.displayError("Invalid Salon ID",message: "The Salon ID must have at least 16 characters. Please correct it and try again.",targetView: self.salonIDField)
            return
        }
        self.salonRecordName = self.salonIDField.text
        if AppDelegate.salonKeys().contains(trialRecordName) {
            self.displayError("Salon Already Added",message: "A Salon with this ID has already been added. Please try a different ID.",targetView: self.salonIDField)
            return
        }
        let containerID = Coredata.cloudContainerID
        let container = CKContainer(identifier: containerID)
        let cloudDB = container.publicCloudDatabase
        let recordID = CKRecordID(recordName: trialRecordName)
        cloudDB.fetchRecordWithID(recordID) { record, error in
            NSOperationQueue.mainQueue().addOperationWithBlock() {
                guard let record = record else {
                    let error = error!
                    let errorCode = CKErrorCode(rawValue: error.code)!
                    switch errorCode {
                    case .UnknownItem:
                        self.displayError("Salon not found",message: "Please re-enter the salon ID and try again",targetView: self.salonIDField)
                    case .NetworkFailure, .NetworkUnavailable:
                        self.displayError("Unable to retrieve details", message: "The network is unavailable. Please try later when you have a good internet connection", targetView: self.findSalonDetailsButton)
                    case .NotAuthenticated:
                        self.displayError("Salon not found",message: "Please ensure you are signed in to iCloud",targetView: self.salonIDField)
                    default:
                        self.displayError("Unexpected error",message: "The salon could not be found. The error was: \(error)",targetView: self.salonIDField)
                    }
                    return
                }
                self.salonRecordName = trialRecordName
                self.populateSalonDetails(record)
            }
        }
    }
    
    func displayError(title:String,message:String,targetView:UIView) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .ActionSheet)
        alert.popoverPresentationController?.sourceView = targetView
        alert.popoverPresentationController?.sourceRect = targetView.bounds
        let alertAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
        alert.addAction(alertAction)
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
        self.hideSalonDetails(true)
    }
    
    func populateSalonDetails(record:CKRecord) {
        self.salonName = record["name"] as? String ?? "New Salon"
        self.salonNameLabel.text = self.salonName
        self.addressLine1Label.text = record["addressLine1"] as? String
        self.addressLine2Label.text = record["addressLine2"] as? String
        self.addressLine3Label.text = record["postcode"] as? String
        self.managerLabel.text = "Claudia Erickson" //record["Unknown manager"] as? String
        self.addThisSalonButton.enabled = true
        self.hideSalonDetails(false)
        self.findSalonDetailsButton.enabled = true
    }
    
    func enableFindDetailsButtonIfAppropriate() {
//        var enableButton = true
//        if !self.isValidEmail() { enableButton = false }
//        if self.passwordField.text?.characters.count < 5 { enableButton = false }
//        if self.salonIDField.text?.characters.count < 16 { enableButton = false }
//        self.findSalonDetailsButton.enabled = enableButton
        self.findSalonDetailsButton.enabled = true
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
        self.enableFindDetailsButtonIfAppropriate()
        return true
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        activeTextField = textField
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        activeTextField = nil
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.dismissKeyboard(textField)
        return true
    }

}

// Extension for keyboard observers
extension AddSalonController {
    func addKeyboardObservers() {
        let nc = NSNotificationCenter.defaultCenter()
        nc.addObserverForName(UIKeyboardDidShowNotification, object: nil, queue: nil) { notification in
            guard let activeTextField = self.activeTextField else {
                return
            }
            guard let userInfo = notification.userInfo else {
                fatalError("The UIKeyboardDidShowNotification was missing")
            }
            guard let frameValueObject = userInfo[UIKeyboardFrameBeginUserInfoKey] as? NSValue else {
                fatalError("Unable to retrieve the keyboard frame from userInfo")
            }
            let unrotatedKeyboardFrame = frameValueObject.CGRectValue()
            let keyboardFrame = self.view.convertRect(unrotatedKeyboardFrame, toView: self.view)
            let keyboardHeight = keyboardFrame.size.height
            let visibleHeight = CGRectGetMaxY(self.view.frame) - keyboardHeight - 8
            let textBottom = CGRectGetMaxY(self.view.convertRect(activeTextField.frame, toView: self.view))
            if textBottom > visibleHeight {
                self.keyboardDisplacement = textBottom - visibleHeight
                UIView.animateWithDuration(0.3) {
                    self.view.frame.origin.y -= self.keyboardDisplacement
                    self.view.frame.size.height += self.keyboardDisplacement
                }
            }
        }
        nc.addObserverForName(UIKeyboardDidHideNotification, object: nil, queue: nil) { notification in
            if self.keyboardDisplacement > 0 {
                UIView.animateWithDuration(0.3) {
                    self.view.frame.origin.y = 0 //
                    self.view.frame.size.height -= self.keyboardDisplacement
                }
            }
        }
    }
    
    func removeKeyboardObservers() {
        let nc = NSNotificationCenter.defaultCenter()
        nc.removeObserver(self, name: UIKeyboardDidShowNotification, object: nil)
        nc.removeObserver(self, name: UIKeyboardDidHideNotification, object: nil)
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


