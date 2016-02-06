//
//  BQQueueProcessorViewController.swift
//  ClaudiaSalon
//
//  Created by Keith Staines on 21/01/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

import Cocoa

class BQQueueProcessorViewController: NSViewController {
    
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
        let moc = self.salonDocument.managedObjectContext!
        let salon = self.salonDocument.salon
        coredataExportController = BQCoredataExportController(managedObjectContext: moc, salon: salon, startImmediately: false)
    }
    
}
