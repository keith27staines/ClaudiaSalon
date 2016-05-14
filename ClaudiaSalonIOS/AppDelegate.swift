//
//  AppDelegate.swift
//  ClaudiaSalonIOS
//
//  Created by Keith Staines on 21/02/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

import UIKit
import CoreData
import CloudKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate {
    
    static let cloudContainerID = "iCloud.uk.co.ClaudiasSalon.ClaudiaSalon"
    var window: UIWindow?
    private var didSuspendExports = false
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        self.setupToplevelController()
        self.registerUserDefaults()
        self.registerForRemoteNotifications(application)
        self .processBadgeNotification(nil)
        return true
    }    
    
    func registerForRemoteNotifications(application: UIApplication) {
        // Register for push notifications
        let notificationSettings = UIUserNotificationSettings(forTypes: [.Alert, .Badge], categories: nil)
        application.registerUserNotificationSettings(notificationSettings)
        application.registerForRemoteNotifications()
    }
    
    func registerForAppNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.processBadgeNotification(_:)), name: "BadgeCountReducedNotification", object: nil)
    }
    
    func processBadgeNotification(notification:NSNotification?) {
        var badgeCount = UIApplication.sharedApplication().applicationIconBadgeNumber
        if let userInfo = notification?.userInfo {
            if let processedBadges = userInfo["processed"] as? Int {
                badgeCount = badgeCount - processedBadges
            } else {
                badgeCount = 0
            }
            if badgeCount < 0 { badgeCount = 0 }
        } else {
            badgeCount = 0
        }
        self.setBadgeCount(badgeCount)
    }
    func setBadgeCount(badgeCount:Int) {
        let badgeResetOperation = CKModifyBadgeOperation(badgeValue: badgeCount)
        badgeResetOperation.modifyBadgeCompletionBlock = { (error) -> Void in
            if error != nil {
                print("Error resetting badge: \(error)")
            }
            else {
                UIApplication.sharedApplication().applicationIconBadgeNumber = badgeCount
            }
        }
        let container = CKContainer(identifier: AppDelegate.cloudContainerID)
        container.addOperation(badgeResetOperation)
    }

    
    func setupToplevelController() {
        // Set up top-level view controller
        let splitViewController = self.window!.rootViewController as! UISplitViewController
        let navigationController = splitViewController.viewControllers[splitViewController.viewControllers.count-1] as! UINavigationController
        navigationController.topViewController!.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem()
        splitViewController.delegate = self
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        if let coredata = Coredata.sharedInstance {
            if coredata.exportController.isSuspended() {
                coredata.exportController.suspendExportIterations()
                self.didSuspendExports = true
            } else {
                self.didSuspendExports = false
            }
            coredata.save()
        }
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        guard let coredata = Coredata.sharedInstance else {
            return
        }
        guard self.didSuspendExports == true else {
            return
        }
        coredata.exportController.resumeExportIterations()
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        if let coredata = Coredata.sharedInstance {
            coredata.importController.pollForMissedRemoteNotifications()
        }
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        if let coredata = Coredata.sharedInstance {
            coredata.save()
        }
    }

    // MARK: - Split view

    func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController:UIViewController, ontoPrimaryViewController primaryViewController:UIViewController) -> Bool {
        guard let secondaryAsNavController = secondaryViewController as? UINavigationController else { return false }
        guard let topAsDetailController = secondaryAsNavController.topViewController as? AppointmentDetailViewController else { return false }
        if topAsDetailController.detailItem == nil {
            // Return true to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
            return true
        }
        return false
    }
}

extension AppDelegate {
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        let cloudKitNotification = CKNotification(fromRemoteNotificationDictionary: userInfo as! [String : NSObject])
        guard cloudKitNotification.notificationType == .Query  else {
            return
        }
        guard let queryNotification = cloudKitNotification as? CKQueryNotification else {
            return
        }
        // TODO: Check this carefully. I think 'parentSalonReference' is actually just a string, not a CKReference
        guard let parentSalonReference = queryNotification.recordFields!["parentSalonReference"] as? CKReference else {
            return
        }
        guard parentSalonReference.recordID.recordName == Coredata.sharedInstance.iCloudSalonRecordName else {
            return
        }
        NSNotificationCenter.defaultCenter().postNotificationName("cloudKitNotification", object: self, userInfo: userInfo)
    }
}

extension AppDelegate {
    func registerUserDefaults() {
        var defaults = [String:AnyObject]()
        defaults["salonKeys"] = [String]()
        NSUserDefaults.standardUserDefaults().registerDefaults(defaults)
    }
    
    class func salonKeys() -> [String] {
        if let salonKeys = NSUserDefaults.standardUserDefaults().arrayForKey("salonKeys") as? [String] {
            return salonKeys
        } else {
            return [String]()
        }
    }
    
    class func addSalonKey(key:String) {
        var salonKeys = self.salonKeys()
        if salonKeys.contains(key) {
            return
        } else {
            salonKeys.append(key)
            NSUserDefaults.standardUserDefaults().setObject(salonKeys, forKey: "salonKeys")
        }
    }
    
    class func forgetSalon(recordName:String) {
        var salonKeys = self.salonKeys()
        if let index = salonKeys.indexOf(recordName) {
            salonKeys.removeAtIndex(index)
            NSUserDefaults.standardUserDefaults().setObject(salonKeys, forKey: "salonKeys")
            if recordName == self.defaultSalonKey() {
                self.setDefaultSalonKey(nil)
            }
        }
    }
    
    class func defaultSalonKey() -> String? {
        return NSUserDefaults.standardUserDefaults().objectForKey("defaultSalonKey") as? String
    }
    
    class func setDefaultSalonKey(key:String?) {
        NSUserDefaults.standardUserDefaults().setObject(key, forKey: "defaultSalonKey")
    }
    
}

