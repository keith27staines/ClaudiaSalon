//
//  FindCustomerViewController.swift
//  ClaudiaSalon
//
//  Created by Keith Staines on 07/03/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

import UIKit

class FindCustomerViewController: UIViewController {
    
    var selectedCustomer:Customer? {
        didSet {
            if self.originalSelectedCustomer == nil {
                self.originalSelectedCustomer = selectedCustomer
            }
        }
    }
    private var originalSelectedCustomer:Customer?
    
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var phoneField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    var allCustomers = [Customer]()
    var filteredCustomers = [Customer]()

    var selectedIndexPath:NSIndexPath?
    var completion:((vc:UIViewController)->Void)?
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        if let completion = completion {
            completion(vc: self)
        }
    }
    func configureCell(cell:FindCustomerCell, indexPath:NSIndexPath) {
        let row = indexPath.row
        let customer = self.filteredCustomers[row]
        cell.customer = customer
        guard let selectedCustomerID = self.selectedCustomer?.objectID else {
            cell.chosen = false
            return
        }
        if customer.objectID == selectedCustomerID {
            cell.chosen  = true
            self.selectedIndexPath = indexPath
        } else {
            cell.chosen = false
        }
    }
    
    @IBAction func clearSearchFields(sender:AnyObject?) {
        nameField.text = ""
        phoneField.text = ""
        self.applyFilters(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.nameField.text = self.selectedCustomer?.fullName
        self.phoneField.text = self.selectedCustomer?.phone
        self.nameField.delegate = self
        self.phoneField.delegate = self
        let moc = Coredata.sharedInstance.managedObjectContext
        self.allCustomers = Customer.allObjectsWithMoc(moc) as! [Customer]
        self.nameField.addTarget(self, action:#selector(FindCustomerViewController.applyFilters(_:)), forControlEvents: UIControlEvents.EditingChanged)
        self.phoneField.addTarget(self, action:#selector(FindCustomerViewController.applyFilters(_:)), forControlEvents: UIControlEvents.EditingChanged)
        self.applyFilters(self)
    }
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    @IBAction func selectAnonymousCustomer() {
        let moc = Coredata.sharedInstance.managedObjectContext
        let salon = Salon(moc: moc)
        let anonymous = salon.anonymousCustomer!
        self.selectedCustomer = anonymous
        self.nameField.text = anonymous.fullName
        self.phoneField.text = anonymous.phone
        self.applyFilters(self)
    }
    
    @IBAction func cancel(sender:AnyObject?) {
        self.selectedCustomer = self.originalSelectedCustomer
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func addCustomer(sender: AnyObject) {
        guard let fullName = self.nameField.text, let phone = self.phoneField.text else {
            return
        }
        guard self.filteredCustomers.count == 0 else {
            let alert = UIAlertController(title: "Customer already exists", message: "A customer called \(fullName) with phone number \(phone) already exists.", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
            return
        }
        guard fullName.characters.count > 3 else {
            let alert = UIAlertController(title: "Insufficient Information", message: "The new customer's name is too short", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
            return
        }
        guard phone.characters.count > 9 else {
            let alert = UIAlertController(title: "Insufficient Information", message: "The new customer's phone number is too short", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
            return
        }
        let moc = Coredata.sharedInstance.managedObjectContext
        let customer = Customer.newObjectWithMoc(moc)
        let names = fullName.componentsSeparatedByString(" ")
        customer.firstName = names[0]
        var lastName = ""
        for i in 1..<names.count {
            lastName += names[i]
        }
        customer.lastName = lastName
        customer.phone = phone
        self.allCustomers.append(customer)
        customer.bqNeedsCoreDataExport = true
        try! customer.managedObjectContext?.save()
        self.applyFilters(self)
    }

    func applyFilters(sender:AnyObject?) {
        let name = (self.nameField.text ?? "").capitalizedString
        let phone = (self.phoneField.text ?? "").capitalizedString
        self.filteredCustomers = self.allCustomers.filter() { customer in
            let customerName = customer.fullName!.capitalizedString
            let customerPhone = customer.phone ?? ""
            var match = true
            if name.characters.count > 2 {
                if !customerName.containsString(name) {
                    match = false
                }
            }
            if phone.characters.count > 2 {
                if !customerPhone.containsString(phone) {
                    match = false
                }
            }
            return match
        }
        self.filteredCustomers.sortInPlace { (customer1, customer2) -> Bool in
            return customer1.fullName!.capitalizedString < customer2.fullName!.capitalizedString
        }
        self.tableView.reloadData()
    }
}

extension FindCustomerViewController: UITextFieldDelegate {
    
}

extension FindCustomerViewController: UITableViewDelegate {
    
}

extension FindCustomerViewController: UITableViewDataSource {
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.filteredCustomers.count
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell")! as! FindCustomerCell
        self.configureCell(cell,indexPath: indexPath)
        return cell
    }
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.selectedCustomer = self.filteredCustomers[indexPath.row]
        self.nameField.text = self.selectedCustomer?.fullName
        self.phoneField.text = self.selectedCustomer?.phone
        if let previousSelectedIndexPath = self.selectedIndexPath {
            if let previousChosenCell  = self.tableView.cellForRowAtIndexPath(previousSelectedIndexPath) as? FindCustomerCell {
                self.configureCell(previousChosenCell, indexPath: previousSelectedIndexPath)
            }
        }
        if let cell = self.tableView.cellForRowAtIndexPath(indexPath) as? FindCustomerCell {
            self.configureCell(cell, indexPath: indexPath)
            self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
    }
}