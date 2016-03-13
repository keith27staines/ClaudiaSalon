//
//  CloudRecordType.swift
//  ClaudiaSalon
//
//  Created by Keith Staines on 12/03/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

import Foundation
import CloudKit

enum CloudRecordType: String {
    
    case CRSalon = "iCloudSalon"
    case CRCustomer = "iCloudCustomer"
    case CREmployee = "iCloudEmployee"
    case CRService = "icloudService"
    case CRServiceCategory = "iCloudServiceCategory"
    case CRAppointment = "iCloudAppointment"
    case CRSale = "iCloudSale"
    case CRSaleItem = "iCloudSaleItem"
    
    static func typesAsArray() -> [CloudRecordType] {
        let array = [CRSalon,CRCustomer,CREmployee,CRServiceCategory,CRService,CRAppointment,CRSale,CRSaleItem]
        return array
    }
    func coredataEntityName() -> String{
        return CloudRecordType.coredataEntityNameForType(self)
    }
//    static func typeForRecordID(recordID:CKRecordID) -> CloudRecordType {
//        return typeFromCloudRecordType(recordID.re)
//    }
    static func coredataEntityNameForType(type:CloudRecordType) -> String {
        switch type {
        case .CRSalon: return "Salon"
        case .CRCustomer: return "Customer"
        case .CREmployee: return "Employee"
        case .CRServiceCategory: return "Service Category"
        case .CRService: return "Service"
        case .CRAppointment: return "Appointment"
        case .CRSale: return "Sale"
        case .CRSaleItem: return "SaleItem"
        }
    }
    func index() -> Int {
        return CloudRecordType.indexForType(self)
    }
    static func indexForType(type:CloudRecordType) -> Int {
        switch type {
        case .CRSalon: return 0
        case .CRCustomer: return 1
        case .CREmployee: return 2
        case .CRServiceCategory: return 3
        case .CRService: return 4
        case .CRAppointment: return 5
        case .CRSale: return 6
        case .CRSaleItem: return 7
        }
    }
    static func typesAsDictionary() -> [String:CloudRecordType] {
        return [
            CRSalon.rawValue: CRSalon,
            CRCustomer.rawValue: CRCustomer,
            CREmployee.rawValue: CREmployee,
            CRService.rawValue: CRService,
            CRServiceCategory.rawValue: CRServiceCategory,
            CRAppointment.rawValue: CRAppointment,
            CRSale.rawValue: CRSale,
            CRSaleItem.rawValue: CRSaleItem
        ];
    }
    static func typeFromString(string:String) -> CloudRecordType? {
        let d = self.typesAsDictionary()
        return d[string]
    }
    static func typeFromCloudRecordType(recordType:String) -> CloudRecordType {
        switch recordType.lowercaseString {
        case "icloudsalon": return CRSalon
        case "icloudcustomer": return CRCustomer
        case "icloudemployee": return CREmployee
        case "icloudservice": return CRService
        case "icloudservicecategory": return CRServiceCategory
        case "icloudappointment": return CRAppointment
        case "icloudsale": return CRSale
        case "icloudsaleitem": return CRSaleItem
        default: fatalError("Unknown CKRecord name \(recordType)")
        }
    }
}
