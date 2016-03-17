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
            self.categoryController = vc
            return
        }
        if segue.identifier == "EmbeddedServices" {
            let vc = segue.destinationViewController as! ServiceTableViewController
            vc.selectedService = self.selectedService
            vc.serviceWasSelected = self.serviceWasSelected
            return
        }
    }

    func serviceWasSelectedHandler(service:Service) {
        if let callback = self.serviceWasSelected {
            callback(selectedService: service)
        }
    }

}
