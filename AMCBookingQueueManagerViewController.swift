//
//  AMCBookingQueueManagerViewController.swift
//  ClaudiaSalon
//
//  Created by Keith Staines on 20/01/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

import Cocoa

class AMCBookingQueueManagerViewController: NSViewController, NSTabViewDelegate {
    weak var salonDocument: AMCSalonDocument!
    @IBOutlet weak var navigationTabBar: NSTabView!

    @IBOutlet var dataExtractViewController: BQDataExtractViewController!
    
    @IBOutlet var queueProcessorViewController: BQQueueProcessorViewController!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationTabBar.selectFirstTabViewItem(self)
        self.dataExtractViewController.salonDocument = salonDocument
        self.navigationTabBar.selectedTabViewItem?.view = self.dataExtractViewController.view
    }

    func tabView(tabView: NSTabView, shouldSelectTabViewItem tabViewItem: NSTabViewItem?) -> Bool {
        return true
    }

    func tabView(tabView: NSTabView, didSelectTabViewItem tabViewItem: NSTabViewItem?) {
        guard let tabViewItem = tabViewItem else {
            return
        }
        let identifier = tabViewItem.identifier as! String
        switch identifier {
        case "DataExtract":
            self.dataExtractViewController.salonDocument = salonDocument
            tabViewItem.view = self.dataExtractViewController.view
        case "QueueProcessor":
            self.queueProcessorViewController.salonDocument = salonDocument
            tabViewItem.view = self.queueProcessorViewController.view
        default:
            assert(false, "Navigation tab identifier could not be matched")
            tabViewItem.view = nil
        }
    }
}