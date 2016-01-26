//
//  AMCBookingQueueManagerWindowController.swift
//  ClaudiaSalon
//
//  Created by Keith Staines on 20/01/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

import Cocoa

class AMCBookingQueueManagerWindowController: NSWindowController {

    let bookingViewController = AMCBookingQueueManagerViewController()
    var salonDocument: AMCSalonDocument!
    convenience init() {
        self.init(windowNibName:"AMCBookingQueueManagerWindowController")
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        bookingViewController.salonDocument = salonDocument
        self.contentViewController = bookingViewController;
    }
    
}
