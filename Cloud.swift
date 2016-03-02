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
    
    let salonCloudID = "CB57BD99-2696-4F34-80D5-F9EFDAF7D39E"
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