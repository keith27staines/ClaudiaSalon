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
    
    var selectedService:Service? {
        didSet {
            if selectedService == nil {
                self.currentCategory = nil
            } else {
                self.currentCategory = selectedService?.serviceCategory
            }
        }
    }
    var currentCategory:ServiceCategory?
    var serviceWasSelected:((selectedService:Service)->Void)?
    
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
        self.serviceController?.category = category
    }
    func serviceWasSelectedHandler(service:Service) {
        if let callback = self.serviceWasSelected {
            callback(selectedService: service)
        }
    }

}
