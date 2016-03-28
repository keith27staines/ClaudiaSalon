//
//  BQQueueProcessorViewController.swift
//  ClaudiaSalon
//
//  Created by Keith Staines on 21/01/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

import Cocoa
import CloudKit

class BQQueueProcessorViewController: NSViewController {
    // Yah
    var salonDocument: AMCSalonDocument!
    var coredataExportController : BQCoredataExportController!

    // MARK:- Actions
    @IBAction func runMaintenanceButtonClicked(sender: NSButton) {
        switch sender.state {
        case NSOffState:
            self.coredataExportController.cancel()
        case NSOnState:
            self.coredataExportController.startExportIterations()
        default:
            break
        }
    }

    // MARK:- NSViewController overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        //coredataExportController = BQCoredataExportController(salonDocument: self.salonDocument, startImmediately: false)
        let parentMoc = self.salonDocument.managedObjectContext!
        let containerIdentifier = CKContainer.defaultContainer().containerIdentifier!
        coredataExportController = BQCoredataExportController(parentMoc: parentMoc, iCloudContainerIdentifier: containerIdentifier, startImmediately: false)
    }
    
}
