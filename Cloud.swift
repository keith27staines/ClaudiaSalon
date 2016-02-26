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

public class Cloud {
    
    let salonCloudID = "A845885F-958A-4CE3-A729-42F08EA9238F"
    let publicDatabase: CKDatabase!
    
    init?() {

        let container = CKContainer(identifier: "iCloud.uk.co.ClaudiasSalon.ClaudiaSalon")
        publicDatabase = container.publicCloudDatabase
        guard Cloud.isSignedIn() else {
            return nil
        }
    }
    
    class func isSignedIn()->Bool {
        if let _ = NSFileManager.defaultManager().ubiquityIdentityToken {
            return true
        }
        else {
            return false
        }
    }
    
}