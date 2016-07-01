//
//  CloudRecordType.swift
//  ClaudiaSalon
//
//  Created by Keith Staines on 12/03/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

import Foundation
import CloudKit

// MARK:- ICloudRecordType enumeration
enum ICloudRecordType: String {
   
    case CRSalon = "iCloudSalon"
    case CRCustomer = "icloudCustomer"
    case CREmployee = "icloudEmployee"
    case CRService = "iCloudService"
    case CRServiceCategory = "icloudServiceCategory"
    case CRAppointment = "icloudAppointment"
    case CRSale = "icloudSale"
    case CRSaleItem = "icloudSaleItem"
    case CRAccount = "icloudAccount"
    
    init(bqExportable:BQExportable) {
        switch bqExportable {
        case is Salon: self = .CRSalon
        case is Customer: self = .CRSalon
        case is Employee: self = .CRSalon
        case is Service: self = .CRSalon
        case is ServiceCategory: self = .CRSalon
        case is Appointment: self = .CRSalon
        case is Sale: self = .CRSalon
        case is SaleItem: self = .CRSalon
        case is Account: self = .CRSalon
        default: fatalError("\(bqExportable.dynamicType) has not been mapped to an ICloudRecordType")
        }
    }
    
    static func typesAsArray() -> [ICloudRecordType] {
        let array = [CRSalon,CRCustomer,CREmployee,CRServiceCategory,CRService,CRAppointment,CRSale,CRSaleItem]
        return array
    }
    func coredataEntityName() -> String {
        return ICloudRecordType.coredataEntityNameForType(self)
    }
    func bqExportableType() -> BQExportable.Type {
        return ICloudRecordType.bqExportableType(self)
    }
    static func bqExportableType(cloudRecordType:ICloudRecordType) -> BQExportable.Type {
        switch cloudRecordType {
        case .CRAccount: return Account.self
        case .CRAppointment: return Appointment.self
        case .CRCustomer: return Customer.self
        case .CREmployee: return Employee.self
        case .CRSale: return Sale.self
        case .CRSaleItem: return SaleItem.self
        case .CRSalon: return Salon.self
        case .CRService: return Service.self
        case .CRServiceCategory: return ServiceCategory.self
        }
    }
    static func coredataEntityNameForType(icloudType:ICloudRecordType) -> String {
        switch icloudType {
        case .CRSalon: return "Salon"
        case .CRCustomer: return "Customer"
        case .CREmployee: return "Employee"
        case .CRServiceCategory: return "ServiceCategory"
        case .CRService: return "Service"
        case .CRAppointment: return "Appointment"
        case .CRSale: return "Sale"
        case .CRSaleItem: return "SaleItem"
        case .CRAccount: return "Account"
        }
    }
    func index() -> Int {
        return ICloudRecordType.indexForType(self)
    }
    static func indexForType(type:ICloudRecordType) -> Int {
        switch type {
        case .CRSalon: return 0
        case .CRCustomer: return 1
        case .CREmployee: return 2
        case .CRServiceCategory: return 3
        case .CRService: return 4
        case .CRAppointment: return 5
        case .CRSale: return 6
        case .CRSaleItem: return 7
        case .CRAccount: return 8
        }
    }
    static func typesAsDictionary() -> [String:ICloudRecordType] {
        return [
            CRSalon.rawValue: CRSalon,
            CRCustomer.rawValue: CRCustomer,
            CREmployee.rawValue: CREmployee,
            CRService.rawValue: CRService,
            CRServiceCategory.rawValue: CRServiceCategory,
            CRAppointment.rawValue: CRAppointment,
            CRSale.rawValue: CRSale,
            CRSaleItem.rawValue: CRSaleItem,
            CRAccount.rawValue: CRAccount
        ];
    }
    static func typeFromString(string:String) -> ICloudRecordType? {
        let d = self.typesAsDictionary()
        return d[string]
    }
    static func typeFromCloudRecordType(recordType:String) -> ICloudRecordType {
        switch recordType.lowercaseString {
        case "icloudsalon": return CRSalon
        case "icloudcustomer": return CRCustomer
        case "icloudemployee": return CREmployee
        case "icloudservice": return CRService
        case "icloudservicecategory": return CRServiceCategory
        case "icloudappointment": return CRAppointment
        case "icloudsale": return CRSale
        case "icloudsaleitem": return CRSaleItem
        case "icloudaccount": return CRAccount
        default: fatalError("Unknown CKRecord name \(recordType)")
        }
    }
}