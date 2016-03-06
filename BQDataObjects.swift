//
//  BQDataObjects.swift
//  ClaudiaSalon
//
//  Created by Keith Staines on 21/01/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

import Foundation
import CloudKit

let appointmentExpiryTime = 33.0 * 24 * 3600.0 // 33 days in seconds
let BQRecordTypeUnknown = "RecordTypeUnknown"

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
    var recordType: String = BQRecordTypeUnknown
    var modifiedDate: NSDate?
    var updateStamp: String?
    var parentSalonReference: CKReference?
    var isActive = true
    
    private init() {
        assertionFailure("Not supported. Init from a managed object, CRRecord or CKReference instead")
    }
    
    private init(recordType:String, managedObject: NSManagedObject, parentSalonID: NSManagedObjectID?) {
        let moc = managedObject.managedObjectContext!
        moc.performBlockAndWait() {
            let bqObject = managedObject as! BQExportable
            self.recordType = recordType;
            let metadata = bqObject.bqMetadata
            self.unarchiveCloudRecordMetadataFromdata(metadata, coredataObject: managedObject)
            
            if recordType != ICloudRecordType.Salon.rawValue {
                guard let parentSalon = managedObject.managedObjectContext!.objectWithID(parentSalonID!) as? Salon else {
                    preconditionFailure("Parent salon is compulsory for any managed object that isn't itself of type Salon")
                }
                guard let parentSalonID = parentSalonID else {
                    let cloudSalon = ICloudSalon(coredataSalon: parentSalon)
                    self.parentSalonReference = CKReference(recordID: cloudSalon.recordID!, action: CKReferenceAction.DeleteSelf)
                    return
                }
                let salon = moc.objectWithID(parentSalonID) as! Salon
                let cloudID = salon.bqCloudID!
                let recordID = CKRecordID(recordName: cloudID)
                self.parentSalonReference = CKReference(recordID: recordID, action: CKReferenceAction.DeleteSelf)
            }
        }
    }
    
    private func makeCloudKitRecord()-> CKRecord {
        let record:CKRecord
        if let recordID = self.recordID {
            record = CKRecord(recordType: self.recordType, recordID: recordID)
        } else {
            record = CKRecord(recordType: self.recordType)
        }
        record["parentSalonReference"] = parentSalonReference
        record["needsExportToCoredata"] = false
        record["isActive"] = true
        return record
    }
    func fetchCoredataObject() {
        preconditionFailure("This method must be overridden and must not call super")
    }
    
    private func unarchiveCloudRecordMetadataFromdata(data: NSData?,coredataObject:NSManagedObject) {
        if let data = data {
            let coder = NSKeyedUnarchiver(forReadingWithData: data)
            guard let ckRecord = CKRecord(coder: coder) else {
                preconditionFailure("The CKRecord metadata could not be decoded")
            }
            if ckRecord.recordType != self.recordType {
                preconditionFailure("The CKRecord metadata was decoded but the type does not match the specified type")
            }
            self.recordID = ckRecord.recordID
        } else {
            // No metadata, so create from scratch
            let recordName = NSUUID().UUIDString
            self.recordID = CKRecordID(recordName: recordName)
            let ckRec = CKRecord(recordType: self.recordType, recordID: self.recordID!)
            let metadata = NSMutableData()
            let archiver = NSKeyedArchiver(forWritingWithMutableData: metadata)
            ckRec.encodeSystemFieldsWithCoder(archiver)
            archiver.finishEncoding()
            let moc = coredataObject.managedObjectContext!
            moc.performBlockAndWait() {
                let bqObject = coredataObject as! BQExportable
                bqObject.bqMetadata = metadata
                bqObject.bqCloudID = recordName
                try! moc.save()
            }
        }
    }
}

// MARK:- class ICloudSalon
public class ICloudSalon : ICloudRecord {
    var name: String?
    var addressLine1: String?
    var addressLine2: String?
    var postcode: String?
    var anonymousCustomerReference:CKReference?
    
    init(coredataSalon: Salon) {
        
        super.init(recordType: ICloudRecordType.Salon.rawValue, managedObject: coredataSalon, parentSalonID: nil)
        
        coredataSalon.managedObjectContext!.performBlockAndWait() {
            self.name = coredataSalon.salonName
            self.addressLine1 = coredataSalon.addressLine1
            self.addressLine2 = coredataSalon.addressLine2
            self.postcode = coredataSalon.postcode
            if let anonymousCustomer = coredataSalon.anonymousCustomer {
                let iCloudCustomer = ICloudCustomer(coredataCustomer: anonymousCustomer, parentSalonID: coredataSalon.objectID)
                let anonymousRecordID = iCloudCustomer.makeCloudKitRecord().recordID
                self.anonymousCustomerReference = CKReference(recordID: anonymousRecordID, action: CKReferenceAction.None)
            }
            
        }
    }
    override func makeCloudKitRecord() -> CKRecord {
        let record = super.makeCloudKitRecord()
        record["name"] = name
        record["addressLine1"] = addressLine1
        record["addressLine2"] = addressLine2
        record["postcode"] = postcode
        record["anonymousCustomerReference"] = anonymousCustomerReference
        return record
    }
}
// MARK:- class ICloudCustomer
public class ICloudCustomer : ICloudRecord {
    var firstName: String?
    var lastName: String?
    var phone: String?
    init(coredataCustomer: Customer, parentSalonID: NSManagedObjectID) {

        super.init(recordType:ICloudRecordType.Customer.rawValue,managedObject: coredataCustomer, parentSalonID: parentSalonID)

        coredataCustomer.managedObjectContext!.performBlockAndWait() {
            self.firstName = coredataCustomer.firstName
            self.lastName = coredataCustomer.lastName
            self.phone = coredataCustomer.phone
        }
    }
    override func makeCloudKitRecord() -> CKRecord {
        let record = super.makeCloudKitRecord()
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
    init(coredataEmployee: Employee, parentSalonID: NSManagedObjectID) {
        
        super.init(recordType:ICloudRecordType.Employee.rawValue, managedObject: coredataEmployee, parentSalonID: parentSalonID)
        
        coredataEmployee.managedObjectContext!.performBlockAndWait() {
            self.firstName = coredataEmployee.firstName
            self.lastName = coredataEmployee.lastName
            self.isActive = (coredataEmployee.isActive?.boolValue == true ? true : false)
        }
    }
    override func makeCloudKitRecord() -> CKRecord {
        let record = super.makeCloudKitRecord()
        record["firstName"] = firstName
        record["lastName"] = lastName
        return record
    }
}
// MARK:- class ICloudServiceCategory
public class ICloudServiceCategory : ICloudRecord {
    var name: String?
    init(coredataServiceCategory: ServiceCategory, parentSalonID: NSManagedObjectID) {
        
        super.init(recordType:ICloudRecordType.ServiceCategory.rawValue,managedObject: coredataServiceCategory, parentSalonID: parentSalonID)
        
        coredataServiceCategory.managedObjectContext!.performBlockAndWait() {
            self.name = coredataServiceCategory.name
        }
    }
    override func makeCloudKitRecord() -> CKRecord {
        let record = super.makeCloudKitRecord()
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
    var parentCategoryReference: CKReference?

    init(coredataService: Service, parentSalonID: NSManagedObjectID) {
        
        super.init(recordType:ICloudRecordType.Service.rawValue,managedObject: coredataService, parentSalonID: parentSalonID)
        
        coredataService.managedObjectContext!.performBlockAndWait() {
            self.name = coredataService.name
            self.minPrice = coredataService.minimumCharge?.doubleValue
            self.maxPrice = coredataService.maximumCharge?.doubleValue
            self.nominalPrice = coredataService.nominalCharge?.doubleValue
            
            // Assign this service's associated category
            if let coredataServiceCategory = coredataService.serviceCategory {
                let cloudServiceCategory = ICloudServiceCategory(coredataServiceCategory: coredataServiceCategory, parentSalonID:parentSalonID)
                self.parentCategoryReference = CKReference(recordID: cloudServiceCategory.recordID!, action: CKReferenceAction.None)
            }
        }
    }
    override func makeCloudKitRecord() -> CKRecord {
        let record = super.makeCloudKitRecord()
        record["name"] = name
        record["minPrice"] = minPrice
        record["maxPrice"] = maxPrice
        record["nominalPrice"] = nominalPrice
        record["parentCategoryReference"] = parentCategoryReference
        return record
    }
}

// MARK:- class ICloudAppointment
class ICloudAppointment:ICloudRecord {
    var parentCustomerReference: CKReference?
    var appointmentStartDate: NSDate?
    var appointmentEndDate: NSDate?
    var expectedDuration: Double?
    var cancellationType = 0
    var cancelled = false
    var completed = false
    init(coredataAppointment: Appointment, parentSalonID: NSManagedObjectID) {
        
        super.init(recordType:ICloudRecordType.Appointment.rawValue,managedObject: coredataAppointment, parentSalonID: parentSalonID)
        
        coredataAppointment.managedObjectContext!.performBlockAndWait() {
            self.appointmentStartDate = coredataAppointment.appointmentDate
            self.appointmentEndDate = coredataAppointment.appointmentEndDate
            self.expectedDuration = coredataAppointment.expectedTimeRequired().doubleValue
            self.cancelled = coredataAppointment.cancelled?.boolValue ?? false
            self.completed = coredataAppointment.completed?.boolValue ?? false
            self.cancellationType = coredataAppointment.cancellationType?.integerValue ?? 0
            
            // Assign this Appointment's parent customer
            let coredataCustomer = coredataAppointment.customer!
            let cloudCustomer = ICloudCustomer(coredataCustomer: coredataCustomer, parentSalonID: parentSalonID)
            self.parentCustomerReference = CKReference(recordID: cloudCustomer.recordID!, action: CKReferenceAction.DeleteSelf)
        }
        
    }
    override func makeCloudKitRecord() -> CKRecord {
        let record = super.makeCloudKitRecord()
        record["appointmentStartDate"] = appointmentStartDate
        record["appointmentEndDate"] = appointmentEndDate
        record["parentCustomerReference"] = parentCustomerReference
        record["cancelled"] = cancelled
        record["cancellationType"] = cancellationType
        record["completed"] = completed
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
    var parentCustomerReference: CKReference?
    var parentAppointmentReference: CKReference?
    var actualCharge :Double? = 0.0
    var nominalCharge :Double? = 0.0
    var discountVersion : Int?
    var discountType : Int?
    var discountValue :Int? = 0
    var discountAmount: Double? = 0.0
    var hidden: Bool? = false
    var isQuote: Bool? = false
    var voided:Bool? = false
    init(coredataSale: Sale, parentSalonID: NSManagedObjectID) {
        
        super.init(recordType: ICloudRecordType.Sale.rawValue,managedObject: coredataSale, parentSalonID: parentSalonID)
        
        coredataSale.managedObjectContext!.performBlockAndWait() {
            self.actualCharge = coredataSale.actualCharge?.doubleValue
            self.nominalCharge = coredataSale.nominalCharge?.doubleValue
            self.discountVersion = coredataSale.discountVersion?.integerValue
            self.discountType = coredataSale.discountType?.integerValue
            self.discountValue = coredataSale.discountValue?.integerValue
            self.discountAmount = coredataSale.discountAmount?.doubleValue
            self.isQuote = coredataSale.isQuote?.boolValue
            self.hidden = coredataSale.hidden?.boolValue
            self.voided = coredataSale.voided?.boolValue
            
            // Assign this Sale's parent customer
            if let coredataCustomer = coredataSale.customer {
                let cloudCustomer = ICloudCustomer(coredataCustomer: coredataCustomer, parentSalonID: parentSalonID)
                self.parentCustomerReference = CKReference(recordID: cloudCustomer.recordID!, action: CKReferenceAction.None)
            }
            
            // Assign this Sale's parent appointment
            if let coredataAppointment = coredataSale.fromAppointment {
                let cloudAppointment = ICloudAppointment(coredataAppointment: coredataAppointment, parentSalonID: parentSalonID)
                self.parentAppointmentReference = CKReference(recordID: cloudAppointment.recordID!, action: CKReferenceAction.DeleteSelf)
            }
        }
    }
    override func makeCloudKitRecord() -> CKRecord {
        let record = super.makeCloudKitRecord()
        record["parentCustomerReference"] = parentCustomerReference
        record["parentAppointmentReference"] = parentAppointmentReference
        record["actualCharge"] = actualCharge
        record["nominalCharge"] = nominalCharge
        record["discountVersion"] = discountVersion
        record["discountType"] = discountType
        record["discountValue"] = discountValue
        record["discountAmount"] = discountAmount
        record["isQuote"] = isQuote
        record["hidden"] = hidden
        record["voided"] = voided
        return record
    }
}
// MARK:- class ICloudSaleItem
class ICloudSaleItem: ICloudRecord {
    var parentSaleReference: CKReference?
    var serviceReference: CKReference?
    var employeeReference: CKReference?
    var discountVersion : Int?
    var discountType : Int?
    var discountValue : Int?
    var actualCharge: Double?
    var nominalCharge: Double?
    var maximumCharge:Double?
    var minimumCharge:Double?
    
    init(coredataSaleItem: SaleItem, parentSalonID: NSManagedObjectID) {
        
        super.init(recordType: ICloudRecordType.SaleItem.rawValue, managedObject: coredataSaleItem, parentSalonID: parentSalonID)
        
        coredataSaleItem.managedObjectContext!.performBlockAndWait() {
            self.discountVersion = coredataSaleItem.discountVersion?.integerValue
            self.discountType = coredataSaleItem.discountType?.integerValue
            self.discountValue = coredataSaleItem.discountValue?.integerValue
            self.actualCharge = coredataSaleItem.actualCharge?.doubleValue
            self.nominalCharge = coredataSaleItem.nominalCharge?.doubleValue
            self.maximumCharge = coredataSaleItem.maximumCharge?.doubleValue
            self.minimumCharge = coredataSaleItem.minimumCharge?.doubleValue
            
            // Assign this SaleItem's parent sale
            if let coredataSale = coredataSaleItem.sale {
                let cloudSale = ICloudSale(coredataSale: coredataSale, parentSalonID: parentSalonID)
                self.parentSaleReference = CKReference(recordID: cloudSale.recordID!, action: CKReferenceAction.DeleteSelf)
            } else {
                self.parentSaleReference = nil
            }
            // Assign this SaleItem's associated service
            if let coredataService = coredataSaleItem.service {
                let cloudService = ICloudService(coredataService: coredataService, parentSalonID: parentSalonID)
                self.serviceReference = CKReference(recordID: cloudService.recordID!, action: CKReferenceAction.None)
            } else {
                self.serviceReference = nil
            }
            // Assign this SalItem's associated employee
            if let coredataEmployee = coredataSaleItem.performedBy {
                let cloudService = ICloudEmployee(coredataEmployee: coredataEmployee, parentSalonID: parentSalonID)
                self.employeeReference = CKReference(recordID: cloudService.recordID!, action: CKReferenceAction.None)
            } else {
                self.employeeReference = nil
            }
        }
    }
    override func makeCloudKitRecord() -> CKRecord {
        let record = super.makeCloudKitRecord()
        record["parentSaleReference"] = parentSaleReference
        record["serviceReference"] = serviceReference
        record["discountVersion"] = discountVersion
        record["discountType"] = discountType
        record["discountValue"] = discountValue
        record["actualCharge"] = actualCharge
        record["nominalCharge"] = nominalCharge
        record["maximumCharge"] = maximumCharge
        record["minimumCharge"] = minimumCharge
        record["employeeReference"] = employeeReference
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
