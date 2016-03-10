//
//  ImportViewController.swift
//  ClaudiaSalon
//
//  Created by Keith Staines on 10/03/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

import UIKit


class ImportViewController : UIViewController {
    var progressViewController: ImportTableViewController?
    
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    
    @IBAction func cancelTapped(sender: AnyObject) {
        self.progressViewController?.cancelImport()
    }
    
    @IBOutlet weak var startButton: UIBarButtonItem!
    
    @IBAction func startTapped(sender: AnyObject) {
        self.progressViewController?.startImport()
    }
    
    @IBOutlet weak var stopButton: UIBarButtonItem!
    
    @IBAction func stopTapped(sender: AnyObject) {
        self.progressViewController?.pauseImport()
    }
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "GotoImportProgress" {
            self.progressViewController = segue.destinationViewController as? ImportTableViewController
            
            return
        }
    }
    
}
