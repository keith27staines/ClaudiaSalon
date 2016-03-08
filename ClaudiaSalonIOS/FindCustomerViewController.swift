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
    let moc = Coredata.sharedInstance.backgroundContext
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
        if customer.objectID == self.selectedCustomer!.objectID {
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
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: "cancel:")
        self.nameField.text = self.selectedCustomer?.fullName
        self.phoneField.text = self.selectedCustomer?.phone
        self.allCustomers = Customer.allObjectsWithMoc(self.moc) as! [Customer]
        self.nameField.addTarget(self, action:"applyFilters:", forControlEvents: UIControlEvents.EditingChanged)
        self.phoneField.addTarget(self, action:"applyFilters:", forControlEvents: UIControlEvents.EditingChanged)
        self.applyFilters(self)
    }
    
    func cancel(sender:AnyObject?) {
        self.selectedCustomer = self.originalSelectedCustomer
        self.navigationController?.popViewControllerAnimated(true)
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