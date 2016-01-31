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
    var coredataID: String?
    var parentSalonReference: CKReference?
    var isActive = true
    private init() {
        assertionFailure("Not supported. Init from a managed object, CRRecord or CKReference instead")
    }
    private init(recordType:String, managedObject: NSManagedObject, parentSalon: Salon?) {
        self.coredataID = managedObject.objectID.URIRepresentation().absoluteString
        self.recordType = recordType;
        let metadata = self.metadataFromManagedObject(managedObject)
        unarchiveFromMetadata(metadata)
        if recordType != ICloudRecordType.Salon.rawValue {
            guard let salon = parentSalon else {
                preconditionFailure("Parent salon is compulsory for any managed object that isn't itself of type Salon")
            }
            let cloudSalon = ICloudSalon(coredataSalon: salon)
            self.parentSalonReference = CKReference(recordID: cloudSalon.recordID!, action: CKReferenceAction.DeleteSelf)
        }
    }
    
    /** metadataFromManagedObject hides a nasty cast that wouldn't
        be necessary at all if we could only work out how to polymorphically 
        extract bqMetadata from these classes. Tried to add an appropriate 
        protocol to these classes but was defeated by compiler errors maybe 
        associated with dynamically added properties that are required for NSManagedObject subclasses 
     */
    private func metadataFromManagedObject(managedObject:NSManagedObject) -> NSData? {
        let className = managedObject.className
        switch className {
        case Salon.className():
            return (managedObject as! Salon).bqMetadata
        case Employee.className():
            return (managedObject as! Employee).bqMetadata
        case Customer.className():
            return (managedObject as! Customer).bqMetadata
        case ServiceCategory.className():
            return (managedObject as! ServiceCategory).bqMetadata
        case Service.className():
            return (managedObject as! Service).bqMetadata
        case Appointment.className():
            return (managedObject as! Appointment).bqMetadata
        case Sale.className():
            return (managedObject as! Sale).bqMetadata
        case SaleItem.className():
            return (managedObject as! SaleItem).bqMetadata
        default:
            preconditionFailure("Cannot extract BQ metadata from class \(className)")
        }
    }
    func makeFirstCloudKitRecord()->CKRecord {
        preconditionFailure("This method must be overridden and must not call super")
    }
    private func makeFirstCloudKitRecordWithType(recordType:String)-> CKRecord {
        let record = CKRecord(recordType: self.recordType)
        record["parentSalonReference"] = parentSalonReference
        record["needsExportToCoredata"] = false
        record["coredataID"] = coredataID
        record["isActive"] = true
        return record
    }
    func fetchCoredataObject() {
        preconditionFailure("This method must be overridden and must not call super")
    }
    private func unarchiveFromMetadata(metadata: NSData?) {
        if let metadata = metadata {
            let coder = NSKeyedUnarchiver(forReadingWithData: metadata)
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
        }
    }
}
// MARK:- class ICloudSalon
public class ICloudSalon : ICloudRecord {
    var name: String?
    var addressLine1: String?
    var addressLine2: String?
    var postcode: String?
    init(coredataSalon: Salon) {
        super.init(recordType: ICloudRecordType.Salon.rawValue, managedObject: coredataSalon, parentSalon: nil)
        self.name = coredataSalon.salonName
        self.addressLine1 = coredataSalon.addressLine1
        self.addressLine2 = coredataSalon.addressLine2
        self.postcode = coredataSalon.postcode
    }
    func makeFirstCloudkitRecord(parentSalon:CKReference?)-> CKRecord {
        let record = makeFirstCloudKitRecordWithType(self.recordType)
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
    init(coredataCustomer: Customer, parentSalon: Salon?) {
        super.init(recordType:ICloudRecordType.Customer.rawValue,managedObject: coredataCustomer, parentSalon: parentSalon)
        self.firstName = coredataCustomer.firstName
        self.lastName = coredataCustomer.lastName
        self.phone = coredataCustomer.phone
    }
    override func makeFirstCloudKitRecord() -> CKRecord {
        let record = makeFirstCloudKitRecordWithType(self.recordType)
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
    init(coredataEmployee: Employee, parentSalon: Salon) {
        super.init(recordType:ICloudRecordType.Employee.rawValue, managedObject: coredataEmployee, parentSalon: parentSalon)
        self.firstName = coredataEmployee.firstName
        self.lastName = coredataEmployee.lastName
        self.isActive = (coredataEmployee.isActive?.boolValue == true ? true : false)
    }
    override func makeFirstCloudKitRecord() -> CKRecord {
        let record = makeFirstCloudKitRecordWithType(self.recordType)
        record["firstName"] = firstName
        record["lastName"] = lastName
        return record
    }
}
// MARK:- class ICloudServiceCategory
public class ICloudServiceCategory : ICloudRecord {
    var name: String?
    init(coredataServiceCategory: ServiceCategory, parentSalon: Salon?) {
        super.init(recordType:ICloudRecordType.ServiceCategory.rawValue,managedObject: coredataServiceCategory, parentSalon: parentSalon)
        self.name = coredataServiceCategory.name
    }
    override func makeFirstCloudKitRecord() -> CKRecord {
        let record = makeFirstCloudKitRecordWithType(self.recordType)
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

    init(coredataService: Service, parentSalon: Salon?) {
        super.init(recordType:ICloudRecordType.Service.rawValue,managedObject: coredataService, parentSalon: parentSalon)
        self.name = coredataService.name
        self.minPrice = coredataService.minimumCharge?.doubleValue
        self.maxPrice = coredataService.maximumCharge?.doubleValue
        self.nominalPrice = coredataService.nominalCharge?.doubleValue
        // Assign this service's parent category
        let coredataServiceCategory = coredataService.serviceCategory!
        let cloudServiceCategory = ICloudServiceCategory(coredataServiceCategory: coredataServiceCategory, parentSalon: parentSalon)
        self.parentCategoryReference = CKReference(recordID: cloudServiceCategory.recordID!, action: CKReferenceAction.DeleteSelf)
    }    
    override func makeFirstCloudKitRecord() -> CKRecord {
        let record = makeFirstCloudKitRecordWithType(self.recordType)
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
    init(coredataAppointment: Appointment, parentSalon: Salon?) {
        super.init(recordType:ICloudRecordType.Appointment.rawValue,managedObject: coredataAppointment, parentSalon: parentSalon)
        self.appointmentStartDate = coredataAppointment.appointmentDate
        self.appointmentEndDate = coredataAppointment.appointmentEndDate
        self.expectedDuration = coredataAppointment.expectedTimeRequired().doubleValue
        // Assign this Appointment's parent customer
        let coredataCustomer = coredataAppointment.customer!
        let cloudCustomer = ICloudCustomer(coredataCustomer: coredataCustomer, parentSalon: parentSalon)
        self.parentCustomerReference = CKReference(recordID: cloudCustomer.recordID!, action: CKReferenceAction.DeleteSelf)
    }
    override func makeFirstCloudKitRecord() -> CKRecord {
        let record = makeFirstCloudKitRecordWithType(self.recordType)
        record["appointmentStartDate"] = appointmentStartDate
        record["appointmentEndDate"] = appointmentEndDate
        record["parentCustomerReference"] = parentCustomerReference
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
    var discountVersion : Int?
    var discountType : Int?
    var discountValue :Int? = 0
    var actualCharge :Double? = 0.0
    var nominalCharge :Double? = 0.0
    init(coredataSale: Sale, parentSalon: Salon?) {
        super.init(recordType: ICloudRecordType.Sale.rawValue,managedObject: coredataSale, parentSalon: parentSalon)
        self.discountVersion = coredataSale.discountVersion?.integerValue
        self.discountType = coredataSale.discountType?.integerValue
        self.discountValue = coredataSale.discountValue?.integerValue
        self.actualCharge = coredataSale.actualCharge?.doubleValue
        self.nominalCharge = coredataSale.nominalCharge?.doubleValue
        
        // Assign this Sale's parent customer
        let coredataCustomer = coredataSale.customer!
        let cloudCustomer = ICloudCustomer(coredataCustomer: coredataCustomer, parentSalon: parentSalon)
        self.parentCustomerReference = CKReference(recordID: cloudCustomer.recordID!, action: CKReferenceAction.DeleteSelf)
        
        // Assign this Sale's parent appointment
        let coredataAppointment = coredataSale.fromAppointment!
        let cloudAppointment = ICloudAppointment(coredataAppointment: coredataAppointment, parentSalon: parentSalon)
        self.parentAppointmentReference = CKReference(recordID: cloudAppointment.recordID!, action: CKReferenceAction.DeleteSelf)
    }
    override func makeFirstCloudKitRecord() -> CKRecord {
        let record = makeFirstCloudKitRecordWithType(self.recordType)
        record["parentCustomerReference"] = parentCustomerReference
        record["parentAppointmentReference"] = parentAppointmentReference
        record["discountVersion"] = discountVersion
        record["discountType"] = discountType
        record["discountValue"] = discountValue
        return record
    }
}
// MARK:- class ICloudSale
class ICloudSaleItem: ICloudRecord {
    var parentSaleReference: CKReference?
    var serviceReference: CKReference?
    var discountVersion : Int?
    var discountType : Int?
    var discountValue : Int?
    var actualCharge: Double?
    var nominalCharge: Double?
    init(coredataSaleItem: SaleItem, parentSalon: Salon?) {
        super.init(recordType: ICloudRecordType.Sale.rawValue,managedObject: coredataSaleItem, parentSalon: parentSalon)
        self.discountVersion = coredataSaleItem.discountVersion?.integerValue
        self.discountType = coredataSaleItem.discountType?.integerValue
        self.discountValue = coredataSaleItem.discountValue?.integerValue
        self.actualCharge = coredataSaleItem.actualCharge?.doubleValue
        self.nominalCharge = coredataSaleItem.nominalCharge?.doubleValue
        // Assign this SaleItem's parent appointment
        let coredataSale = coredataSaleItem.sale!
        let cloudSale = ICloudSale(coredataSale: coredataSale, parentSalon: parentSalon)
        self.parentSaleReference = CKReference(recordID: cloudSale.recordID!, action: CKReferenceAction.DeleteSelf)
        // Assign this SaleItem's associated service
        let coredataService = coredataSaleItem.service!
        let cloudService = ICloudService(coredataService: coredataService, parentSalon: parentSalon)
        self.serviceReference = CKReference(recordID: cloudService.recordID!, action: CKReferenceAction.None)
    }
    override func makeFirstCloudKitRecord() -> CKRecord {
        let record = makeFirstCloudKitRecordWithType(self.recordType)
        record["parentSaleReference"] = parentSaleReference
        record["serviceReference"] = serviceReference
        record["discountVersion"] = discountVersion
        record["discountType"] = discountType
        record["discountValue"] = discountValue
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
// MARK:- NSManagedObject extensions
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
