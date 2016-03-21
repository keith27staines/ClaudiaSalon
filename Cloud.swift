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
    
    let salonCloudID = "FEC6DB02-A620-410B-92EC-F6952A8A4E2CE"
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