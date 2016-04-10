//
//  MenuTableViewController.swift
//  ClaudiaSalon
//
//  Created by Keith Staines on 09/04/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

import UIKit

class MenuTableViewController: UITableViewController {
    override func viewDidLoad() {
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: #selector(MenuTableViewController.done(_:)))
    }
    
    func done(sender:AnyObject?) {
        self.parentViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
}
