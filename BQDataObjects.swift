//
//  BQDataObjects.swift
//  ClaudiaSalon
//
//  Created by Keith Staines on 21/01/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

import Foundation
import CloudKit

let appointmentExpiryTime = 33.0 * 3600.0 // 33 days in seconds

// MARK:- DiscountType enumeration
enum DiscountType : Int {
    case Percent = 0
    case Amount = 1
}
// MARK:- ICloudRecordType enumeration
enum ICloudRecordType: String {
    case Salon = "iCloudSalon"
    case Customer = "icloudCustomer"
    case ServiceCategory = "icloudServiceCategory"
    case Service = "iCloudService"
    case Employee = "icloudEmployee"
    case Sale = "icloudSale"
    case SaleItem = "icloudSaleItem"
    case Appointment = "icloudAppointment"
}



// MARK:- abstract base class ICloudRecord
public class ICloudRecord {
    var needsExortToCoredata = false
    var creationDate: NSDate?
    var recordID: CKRecordID?
    var recordType: String = ""
    var modifiedDate: NSDate?
    var updateStamp: String?
    var coredataID: String?
    var cloudSalonRef: CKReference?
    var isActive = true
    private init() {
        assertionFailure("Not supported. Init from a managed object, CRRecord or CKReference instead")
    }
    private init(managedObject: NSManagedObject, parentSalon: Salon?) {
        self.coredataID = managedObject.objectID.URIRepresentation().absoluteString
        if !managedObject.isKindOfClass(Salon) {
            guard let salon = parentSalon else {
                preconditionFailure("Parent salon is compulsory for any managed object that isn't itself of type Salon")
                return
            }
            let cloudSalon = ICloudSalon(coredataSalon: salon)
            self.cloudSalonRef = CKReference(recordID: cloudSalon.recordID!, action: CKReferenceAction.DeleteSelf)
        }
    }
    func makeFirstCloudKitRecord()->CKRecord {
        preconditionFailure("This method must be overridden and must not call super")
    }
    func fetchCoredataObject() {
        preconditionFailure("This method must be overridden and must not call super")
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

// MARK:- class ICloudSalon
public class ICloudSalon : ICloudRecord {
    var name: String?
    var addressLine1: String?
    var addressLine2: String?
    var postcode: String?
    override init(managedObject: NSManagedObject, parentSalon: Salon?) {
        preconditionFailure("Do not use this initializer")
    }
    init(coredataSalon: Salon) {
        super.init(managedObject: coredataSalon, parentSalon: nil)
        self.recordType = ICloudRecordType.Salon.rawValue
        self.unarchiveRecordFromMetadata(self.recordType, data: coredataSalon.bqMetadata)
        self.name = coredataSalon.salonName
        self.addressLine1 = coredataSalon.addressLine1
        self.addressLine2 = coredataSalon.addressLine2
        self.postcode = coredataSalon.postcode
    }
    func makeFirstCloudkitRecord(parentSalon:CKReference?)-> CKRecord {
        let record = CKRecord(recordType: self.recordType)
        record["isActive"] = true
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
    override init(managedObject: NSManagedObject, parentSalon: Salon?) {
        preconditionFailure("Do not use this initializer")
    }
    init(coredataCustomer: Customer, parentSalon: Salon?) {
        super.init(managedObject: coredataCustomer, parentSalon: parentSalon)
        self.recordType = ICloudRecordType.Customer.rawValue
        self.unarchiveRecordFromMetadata(self.recordType, data: coredataCustomer.bqMetadata)
        self.firstName = coredataCustomer.firstName
        self.lastName = coredataCustomer.lastName
        self.phone = coredataCustomer.phone
    }
    
    override func makeFirstCloudKitRecord() -> CKRecord {
        let record = CKRecord(recordType: self.recordType)
        record["cloudSalonRef"] = cloudSalonRef
        record["needsExportToCoredata"] = false
        record["coredataID"] = coredataID
        record["firstName"] = firstName
        record["lastName"] = lastName
        record["phone"] = phone
        record["isActive"] = true
        return record
    }
}
// MARK:- class ICloudEmployee
public class ICloudEmployee : ICloudRecord {
    var firstName: String?
    var lastName: String?
    override init(managedObject: NSManagedObject, parentSalon: Salon?) {
        preconditionFailure("Do not use this initializer")
    }
    init(coredataEmployee: Employee, parentSalon: Salon) {
        super.init(managedObject: coredataEmployee, parentSalon: parentSalon)
        self.recordType = ICloudRecordType.Employee.rawValue
        self.unarchiveRecordFromMetadata(self.recordType, data: coredataEmployee.bqMetadata)
        self.firstName = coredataEmployee.firstName
        self.lastName = coredataEmployee.lastName
        self.isActive = (coredataEmployee.isActive?.boolValue == true ? true : false)
    }
    
    override func makeFirstCloudKitRecord() -> CKRecord {
        let record = CKRecord(recordType: self.recordType)
        record["cloudSalonRef"] = cloudSalonRef
        record["needsExportToCoredata"] = false
        record["coredataID"] = coredataID
        record["firstName"] = firstName
        record["lastName"] = lastName
        record["isActive"] = true
        return record
    }
}
// MARK:- class ICloudServiceCategory
public class ICloudServiceCategory : ICloudRecord {
    var name: String?
    override init(managedObject: NSManagedObject, parentSalon: Salon?) {
        preconditionFailure("Do not use this initializer")
    }
    init(coredataServiceCategory: ServiceCategory, parentSalon: Salon?) {
        super.init(managedObject: coredataServiceCategory, parentSalon: parentSalon)
        self.recordType = ICloudRecordType.ServiceCategory.rawValue
        self.unarchiveRecordFromMetadata(self.recordType, data: coredataServiceCategory.bqMetadata)
        self.name = coredataServiceCategory.name
    }
    override func makeFirstCloudKitRecord() -> CKRecord {
        let record = CKRecord(recordType: self.recordType)
        record["cloudSalonRef"] = cloudSalonRef
        record["needsExportToCoredata"] = false
        record["coredataID"] = coredataID
        record["name"] = name
        record["isActive"] = true
        return record
    }
}
// MARK:- class ICloudService
public class ICloudService : ICloudRecord {
    var name: String?
    var minPrice: Double?
    var maxPrice: Double?
    var nominalPrice: Double?
    var serviceCategoryRef: CKReference?
    override init(managedObject: NSManagedObject, parentSalon: Salon?) {
        preconditionFailure("Do not use this initializer")
    }
    init(coredataService: Service, parentSalon: Salon?) {
        super.init(managedObject: coredataService, parentSalon: parentSalon)
        self.recordType = ICloudRecordType.Service.rawValue
        self.unarchiveRecordFromMetadata(self.recordType, data: coredataService.bqMetadata)
        self.name = coredataService.name
        self.minPrice = coredataService.minimumCharge?.doubleValue
        self.maxPrice = coredataService.maximumCharge?.doubleValue
        self.nominalPrice = coredataService.nominalCharge?.doubleValue
    }
    func makeFirstCloudKitRecord(parentSalon: CKReference, serviceCategoryRef: CKReference) -> CKRecord {
        let record = self.makeFirstCloudKitRecord()
        record["serviceCategoryRef"] = serviceCategoryRef
        return record
    }
    
    override func makeFirstCloudKitRecord() -> CKRecord {
        let record = CKRecord(recordType: self.recordType)
        record["cloudSalonRef"] = cloudSalonRef
        record["needsExportToCoredata"] = false
        record["coredataID"] = coredataID
        record["minPrice"] = minPrice
        record["maxPrice"] = maxPrice
        record["nominalPrice"] = nominalPrice
        record["isActive"] = true
        return record
    }
}

// MARK:- class ICloudAppointment
class ICloudAppointment:ICloudRecord {
    var customerReference: CKReference?
    var appointmentStartDate: NSDate?
    var appointmentEndDate: NSDate?
    var expectedDuration: Double?
    override init(managedObject: NSManagedObject, parentSalon: Salon?) {
        preconditionFailure("Do not use this initializer")
    }
    init(coredataAppointment: Appointment, parentSalon: Salon?) {
        super.init(managedObject: coredataAppointment, parentSalon: parentSalon)
        self.recordType = ICloudRecordType.Appointment.rawValue
        self.unarchiveRecordFromMetadata(self.recordType, data: coredataAppointment.bqMetadata)
        self.appointmentStartDate = coredataAppointment.appointmentDate
        self.appointmentEndDate = coredataAppointment.appointmentEndDate
        self.expectedDuration = coredataAppointment.expectedTimeRequired().doubleValue
        let coredataCustomer = coredataAppointment.customer!
        let cloudCustomer = ICloudCustomer(managedObject: coredataCustomer, parentSalon: parentSalon)
        self.customerReference = CKReference(recordID: cloudCustomer.recordID!, action: CKReferenceAction.None)
    }
    
    func makeFirstCloudKitRecord(parentCustomer: CKRecord) -> CKRecord {
        precondition(parentCustomer.recordType == ICloudRecordType.Customer.rawValue, "parentCustomer is not of record type Customer")
        let record = self.makeFirstCloudKitRecord()
        record["customerReference"] = CKReference(record: parentCustomer, action: CKReferenceAction.DeleteSelf)
        return record
    }
    
    override func makeFirstCloudKitRecord() -> CKRecord {
        let record = CKRecord(recordType: self.recordType)
        record["cloudSalonRef"] = cloudSalonRef
        record["needsExportToCoredata"] = false
        record["coredataID"] = coredataID
        record["appointmentStartDate"] = appointmentStartDate
        record["appointmentEndDate"] = appointmentEndDate
        record["isActive"] = true
        return record
    }
    
    class func operationToDetermineExpiredAppointments(salonReference:CKReference) -> CKOperation {
        let earliestNonExpired = NSDate().dateByAddingTimeInterval(-appointmentExpiryTime)
        let expiredPredicate = NSPredicate(format: "appointmentDate < %@ and cloudSalonRef == ", earliestNonExpired,salonReference)
        let expiredQuery = CKQuery(recordType: ICloudRecordType.Appointment.rawValue, predicate: expiredPredicate)
        let expiredOperation = CKQueryOperation(query: expiredQuery)
        expiredOperation.desiredKeys = ["recordID"]
        return expiredOperation
    }
}
// MARK:- class ICloudSale
class ICloudSale:ICloudRecord {
    var customerReference: CKReference?
    var appointmentReference: CKReference?
    var discountVersion : Int?
    var discountType : Int?
    var discountValue : Int?
    override init(managedObject: NSManagedObject, parentSalon: Salon?) {
        preconditionFailure("Do not use this initializer")
    }
    init(coredataSale: Sale, parentSalon: Salon?) {
        super.init(managedObject: coredataSale, parentSalon: parentSalon)
        self.recordType = ICloudRecordType.Sale.rawValue
        self.unarchiveRecordFromMetadata(self.recordType, data: coredataSale.bqMetadata)
    }
    
    override func makeFirstCloudKitRecord() -> CKRecord {
        let record = CKRecord(recordType: self.recordType)
        record["cloudSalonRef"] = cloudSalonRef
        record["needsExportToCoredata"] = false
        record["coredataID"] = coredataID
        record["isActive"] = true
        return record
    }
}
// MARK:- Helper functions
func archiveMetadataForCKRecord(record: CKRecord) -> NSMutableData {
    let archivedData = NSMutableData()
    let archiver = NSKeyedArchiver(forWritingWithMutableData: archivedData)
    archiver.requiresSecureCoding = true
    record.encodeSystemFieldsWithCoder(archiver)
    archiver.finishEncoding()
    return archivedData
}

// MARK:- Managed object extensions
extension Appointment {
    class func unexpiredAppointments(managedObjectContext:NSManagedObjectContext) -> [Appointment] {
        let today = NSDate()
        let earliest = today.dateByAddingTimeInterval(-appointmentExpiryTime)
        let appointments = Appointment.appointmentsAfterDate(earliest, withMoc: managedObjectContext) as! [Appointment]
        return appointments.sort({ (appointment1, appointment2) -> Bool in
            let date1 = appointment1.appointmentDate!
            let date2 = appointment2.appointmentDate!
            return (date1.isLessThan(date2))
        })
    }
}
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


