//
//  BQDataObjects.swift
//  ClaudiaSalon
//
//  Created by Keith Staines on 21/01/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

import Foundation
import CloudKit

func archiveMetadataForCKRecord(record: CKRecord) -> NSMutableData {
    let archivedData = NSMutableData()
    let archiver = NSKeyedArchiver(forWritingWithMutableData: archivedData)
    archiver.requiresSecureCoding = true
    record.encodeSystemFieldsWithCoder(archiver)
    archiver.finishEncoding()
    return archivedData
}


enum ICloudRecordType: String {
    case Salon = "iCloudSalon"
    case Customer = "icloudCustomer"
    case ServiceCategory = "icloudServiceCategory"
    case Service = "iCloudService"
    case Employee = "icloudEmployee"
    case SaleItem = "icloudSaleItem"
    case Appointment = "icloudAppointment"
}

public class ICloudRecord {
    var needsExortToCoredata = false
    var creationDate: NSDate?
    var recordID: CKRecordID?
    var recordType: String = ""
    var modifiedDate: NSDate?
    var updateStamp: String?
    var coredataID: String?
    var cloudSalonRef: CKReference?
    init() {
        
    }
    init(managedObject: NSManagedObject) {
        self.coredataID = managedObject.objectID.URIRepresentation().absoluteString
    }
    func makeFirstCloudKitRecord(parentSalon:CKReference?)->CKRecord {
        preconditionFailure("This method must be overridden")
    }
    func fetchCoredataObject() {
        preconditionFailure("This method must be overridden")
    }
    func unarchiveRecordFromMetadata(recordType: String, data: NSData?) {
        if let metadata = data {
            let coder = NSKeyedUnarchiver(forReadingWithData: metadata)
            self.recordID = CKRecord(coder: coder)?.recordID
            assert(self.recordType == recordType, "Record types don't match")
        } else {
            let recordName = NSUUID().UUIDString
            self.recordType = recordType
            self.recordID = CKRecordID(recordName: recordName)
        }
    }
}

public class ICloudSalon : ICloudRecord {
    var name: String?
    var addressLine1: String?
    var addressLine2: String?
    var postcode: String?
    override init(managedObject: NSManagedObject) {
        super.init(managedObject: managedObject)
        self.recordType = ICloudRecordType.Salon.rawValue
        let coredataSalon = managedObject as! Salon
        self.unarchiveRecordFromMetadata(self.recordType, data: coredataSalon.bqMetadata)
        self.name = coredataSalon.salonName
        self.addressLine1 = coredataSalon.addressLine1
        self.addressLine2 = coredataSalon.addressLine2
        self.postcode = coredataSalon.postcode
    }
    func makeFirstCloudkitRecord(parentSalon:CKReference?)-> CKRecord {
        let record = CKRecord(recordType: self.recordType)
        record["cloudSalonRef"] = nil
        record["needsExportToCoredata"] = false
        record["coredataID"] = coredataID
        record["name"] = name
        record["addressLine1"] = addressLine1
        record["addressLine2"] = addressLine2
        record["postcode"] = postcode
        return record
    }
}
// MARK:- class ICloudCustomer
public class ICloudCustomer : ICloudRecord {
    var firstName: String?
    var lastName: String?
    var phone: String?

    override init(managedObject: NSManagedObject) {
        super.init(managedObject: managedObject)
        self.recordType = ICloudRecordType.Customer.rawValue
        let coredataCustomer = managedObject as! Customer
        self.unarchiveRecordFromMetadata(self.recordType, data: coredataCustomer.bqMetadata)
        self.firstName = coredataCustomer.firstName
        self.lastName = coredataCustomer.lastName
        self.phone = coredataCustomer.phone
    }
    
    override func makeFirstCloudKitRecord(parentSalon: CKReference?) -> CKRecord {
        let record = CKRecord(recordType: self.recordType)
        record["cloudSalonRef"] = parentSalon
        record["needsExportToCoredata"] = false
        record["coredataID"] = coredataID
        record["firstName"] = firstName
        record["lastName"] = lastName
        record["phone"] = phone
        return record
    }
}
// MARK:- class ICloudEmployee
public class ICloudEmployee : ICloudRecord {
    var firstName: String?
    var lastName: String?

    override init(managedObject: NSManagedObject) {
        super.init(managedObject: managedObject)
        self.recordType = ICloudRecordType.Employee.rawValue
        let coredataEmployee = managedObject as! Employee
        self.unarchiveRecordFromMetadata(self.recordType, data: coredataEmployee.bqMetadata)
        self.firstName = coredataEmployee.firstName
        self.lastName = coredataEmployee.lastName
    }
    
    override func makeFirstCloudKitRecord(parentSalon: CKReference?) -> CKRecord {
        let record = CKRecord(recordType: self.recordType)
        record["cloudSalonRef"] = parentSalon
        record["needsExportToCoredata"] = false
        record["coredataID"] = coredataID
        record["firstName"] = firstName
        record["lastName"] = lastName
        return record
    }
}
// MARK:- class ICloudServiceCategory
public class ICloudServiceCategory : ICloudRecord {
    var name: String?
    override init(managedObject: NSManagedObject) {
        super.init(managedObject: managedObject)
        self.recordType = ICloudRecordType.ServiceCategory.rawValue
        let coredataServiceCategory = managedObject as! ServiceCategory
        self.unarchiveRecordFromMetadata(self.recordType, data: coredataServiceCategory.bqMetadata)
        self.name = coredataServiceCategory.name
    }
    override func makeFirstCloudKitRecord(parentSalon: CKReference?) -> CKRecord {
        let record = CKRecord(recordType: self.recordType)
        record["cloudSalonRef"] = parentSalon
        record["needsExportToCoredata"] = false
        record["coredataID"] = coredataID
        record["name"] = name
        return record
    }
}
// MARK:- class ICloudService
public class ICloudService : ICloudRecord {
    var name: String?
    var minPrice: Double?
    var maxPrice: Double?
    var nominalPrice: Double?
    var parentCategory: CKReference?
    
    override init(managedObject: NSManagedObject) {
        super.init(managedObject: managedObject)
        self.recordType = ICloudRecordType.Service.rawValue
        let coredataService = managedObject as! Service
        self.unarchiveRecordFromMetadata(self.recordType, data: coredataService.bqMetadata)
        self.name = coredataService.name
        self.minPrice = coredataService.minimumCharge?.doubleValue
        self.maxPrice = coredataService.maximumCharge?.doubleValue
        self.nominalPrice = coredataService.nominalCharge?.doubleValue
    }
    override func makeFirstCloudKitRecord(parentSalon: CKReference?) -> CKRecord {
        let record = CKRecord(recordType: self.recordType)
        record["cloudSalonRef"] = parentSalon
        record["needsExportToCoredata"] = false
        record["coredataID"] = coredataID
        record["minPrice"] = minPrice
        record["maxPrice"] = maxPrice
        record["nominalPrice"] = nominalPrice
        return record
    }
}

// MARK:- Managed object extensions
extension Customer {
    class func customersOrderedByFirstName(managedObjectContext:NSManagedObjectContext) -> [Customer] {
        let customers = Customer.allObjectsWithMoc(managedObjectContext) as! [Customer]
        let sortedCustomers = customers.sort { (customer1:Customer, customer2:Customer) -> Bool in
            return (customer1.fullName!.lowercaseString < customer2.fullName!.lowercaseString)
        }
        return sortedCustomers
    }
}
extension Employee {
    
    class func employeesOrderedByFirstName(managedObjectContext:NSManagedObjectContext) -> [Employee] {
        let employees = Employee.allObjectsWithMoc(managedObjectContext) as! [Employee]
        let sortedEmployees = employees.sort { (employee1, employee2) -> Bool in
            return (employee1.fullName().lowercaseString < employee2.fullName().lowercaseString)
        }
        return sortedEmployees
    }
}
extension Service {
    class func servicesOrderedByName(managedObjectContext: NSManagedObjectContext) -> [Service] {
        let services = Service.allObjectsWithMoc(managedObjectContext) as! [Service]
        let sortedServices = services.sort { (service1, service2) -> Bool in
            return (service1.name!.lowercaseString < service2.name!.lowercaseString)
        }
        return sortedServices
    }
}
extension ServiceCategory {
    class func serviceCategoriesOrderedByName(managedObjectContext: NSManagedObjectContext) -> [ServiceCategory] {
        let serviceCategories = ServiceCategory.allObjectsWithMoc(managedObjectContext) as! [ServiceCategory]
        let sortedServiceCategories = serviceCategories.sort { (serviceCategory1, serviceCategory2) -> Bool in
            return (serviceCategory1.name!.lowercaseString < serviceCategory2.name!.lowercaseString)
        }
        return sortedServiceCategories
    }
}


