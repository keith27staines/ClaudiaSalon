//
//  Cloud.swift
//  ClaudiaSalon
//
//  Created by Keith Staines on 26/02/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

import Foundation
import CloudKit

enum CloudError: ErrorType {
    case NotSignedIn
}

public class ICloud {
    
    class func isSignedIn()->Bool {
        if let _ = NSFileManager.defaultManager().ubiquityIdentityToken {
            return true
        }
        else {
            return false
        }
    }
    
//    [[CKContainer defaultContainer] accountStatusWithCompletionHandler:^(CKAccountStatus accountStatus, NSError *error) {
//    if (accountStatus == CKAccountStatusNoAccount) {
//    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Sign in to iCloud"
//    message:@"Sign in to your iCloud account to write records. On the Home screen, launch Settings, tap iCloud, and enter your Apple ID. Turn iCloud Drive on. If you don't have an iCloud account, tap Create a new Apple ID."
//    preferredStyle:UIAlertControllerStyleAlert];
//    [alert addAction:[UIAlertAction actionWithTitle:@"Okay"
//    style:UIAlertActionStyleCancel
//    handler:nil]];
//    [self presentViewController:alert animated:YES completion:nil];
//    }
//    else {
//    // Insert your just-in-time schema code here
//    }
//    }];
//    
}