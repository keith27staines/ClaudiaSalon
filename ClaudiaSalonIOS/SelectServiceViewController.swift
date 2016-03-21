//
//  SelectServiceViewController.swift
//  ClaudiaSalon
//
//  Created by Keith Staines on 17/03/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

import UIKit

class SelectServiceViewController : UIViewController {
    
    
    var categoryController:ServiceCategoryTableViewController?
    var serviceController:ServiceTableViewController?
    var serviceWasSelected:((selectedService:Service)->Void)?
    var originalService:Service?
    var initialCategoryListDistanceFromFloor:CGFloat = 99999
    
    @IBOutlet weak var categoryContainerHeightConstraint: NSLayoutConstraint!
    
    
    @IBOutlet weak var categoryContainerBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var upCategoryButton: UIButton!
    
    @IBOutlet weak var parentLabel: UILabel!
    
    @IBOutlet weak var servicesInCategoryLabel: UILabel!
    
    @IBOutlet weak var categoryListContainerView: UIView!
    
    @IBOutlet weak var serviceListContainerView: UIView!
    
    @IBAction func upCategoryButtonClicked(sender: AnyObject) {
        let moc = Coredata.sharedInstance.backgroundContext
        moc.performBlockAndWait() {
            if let upCategory = self.currentCategory?.parent {
                self.categoryWasSelected(upCategory)
            }
        }
    }
    var selectedService:Service? {
        didSet {
        }
    }
    var currentCategory:ServiceCategory? {
        didSet {
            if let category = self.currentCategory {
                self.categoryWasSelected(category)
            }
            self.updateParentCategory()
        }
    }
    
    func updateParentCategory() {
        guard let _ = self.parentLabel else {
            return // Connections not set up yet
        }
        let moc = Coredata.sharedInstance.backgroundContext
        var name:String?
        moc.performBlockAndWait() {
            if let category = self.currentCategory {
                name = category.name
            }
        }
        self.parentLabel.text = name
    }
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.parentLabel.text = self.currentCategory?.name
    }
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if initialCategoryListDistanceFromFloor == 99999 {
            initialCategoryListDistanceFromFloor = self.view.frame.height  - self.categoryController!.view.frame.height - self.categoryController!.view.frame.origin.y
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "EmbeddedCategories" {
            let vc = segue.destinationViewController as! ServiceCategoryTableViewController
            vc.currentCategory = self.currentCategory
            vc.categoryWasSelected = self.categoryWasSelected
            self.categoryController = vc
            return
        }
        if segue.identifier == "EmbeddedServices" {
            let vc = segue.destinationViewController as! ServiceTableViewController
            vc.category = self.currentCategory
            vc.selectedService = self.selectedService
            vc.serviceWasSelected = self.serviceWasSelected
            self.serviceController = vc
            return
        }
    }
    func categoryWasSelected(category:ServiceCategory) {
        if category == self.currentCategory {
            return
        }
        self.currentCategory = category
        var showServiceCategories:Bool?
        var showServices:Bool?
        Coredata.sharedInstance.backgroundContext.performBlockAndWait() {
            if category != self.categoryController?.currentCategory {
                self.categoryController?.currentCategory = category
            }
            self.serviceController?.category = category
            showServiceCategories = (self.categoryController!.subCategoriesCount > 0) ? true : false
            showServices = (self.serviceController!.servicesCount > 0) ? true : false
        }
        NSOperationQueue.mainQueue().addOperationWithBlock() {
            self.categoryController?.reloadData()
            self.serviceController?.reloadData()
            if showServices! {
                if showServiceCategories! {
                    self.categoryContainerBottomConstraint.constant = self.view.frame.height / 2.0
                } else {
                    self.categoryContainerBottomConstraint.constant = self.view.frame.height * 9.0 / 10.0
                }
            } else {
                self.categoryContainerBottomConstraint.constant = 8
            }
        }
    }
    func serviceWasSelectedHandler(service:Service) {
        if let callback = self.serviceWasSelected {
            callback(selectedService: service)
        }
    }

}
