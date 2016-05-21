//
//  BQCoredataObjectExtensions.swift
//  ClaudiaSalon
//
//  Created by Keith Staines on 05/02/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

import Foundation
import CoreData
import CloudKit

@objc
protocol BQExportable: class {
    var bqNeedsCoreDataExport: NSNumber? { get set }
    var bqNeedsCloudImport: NSNumber? { get set }
    var bqHasClientChanges: NSNumber? { get set }
    var bqMetadata: NSData? { get set }
    var bqCloudID: String? { get set }
    var lastUpdatedDate: NSDate? { get set }
    var managedObjectContext:NSManagedObjectContext? { get }
    func updateFromCloudRecord(record:CKRecord)
    func cascadeHasChangesUpdwards()
    static func fetchBQExportable(cloudID: String, moc: NSManagedObjectContext) -> BQExportable?
    static func newExportableWithMoc(moc:NSManagedObjectContext) -> BQExportable
}

extension BQExportable {
    func setBQDataFromRecord(record:CKRecord) {
        self.managedObjectContext!.performBlockAndWait() {
            self.bqCloudID = record.recordID.recordName
            self.bqMetadata = record.metadataFromRecord()
            self.lastUpdatedDate = record.modificationDate
        }
    }
    func cloudRecordFromMetadata() -> CKRecord? {
        guard let metadata = self.bqMetadata else {
            return nil
        }
        let coder = NSKeyedUnarchiver(forReadingWithData: metadata)
        guard let ckRecord = CKRecord(coder: coder) else {
            return nil
        }
        return ckRecord
    }
}

// MARK:- Salon
extension Salon : BQExportable {
    class func newExportableWithMoc(moc: NSManagedObjectContext) -> BQExportable {
        return Salon(moc: moc)
    }
    class func fetchBQExportable(cloudID: String, moc: NSManagedObjectContext) -> BQExportable? {
        return Salon.fetchForCloudID(cloudID, moc: moc)
    }
    func cascadeHasChangesUpdwards() {
        // We are already a top level object so there is nothing to do
    }
}

// MARK:- Appointment
extension Appointment : BQExportable {
    class func newExportableWithMoc(moc: NSManagedObjectContext) -> BQExportable {
        return Appointment.newObjectWithMoc(moc)
    }
    class func fetchBQExportable(cloudID: String, moc: NSManagedObjectContext) -> BQExportable? {
        return Appointment.fetchForCloudID(cloudID, moc: moc)
    }
    func cascadeHasChangesUpdwards() {
        self.bqHasClientChanges = true
        // We are already a top level object so there is nothing else do
    }
}
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
    class func appointmentsMarkedForExport(managedObjectContext:NSManagedObjectContext) -> Set<Appointment> {
        let predicate = NSPredicate(format: "bqNeedsCoreDataExport = %@", true)
        let fetchRequest = NSFetchRequest(entityName:"Appointment")
        fetchRequest.predicate = predicate
        do {
            let fetchedResults = try managedObjectContext.executeFetchRequest(fetchRequest)
            return Set(fetchedResults as! [Appointment])
        } catch {
            assertionFailure("Unable to fetch objects marked for export")
            return Set<Appointment>()
        }
    }
}
// MARK:- Customer
extension Customer : BQExportable {
    class func newExportableWithMoc(moc: NSManagedObjectContext) -> BQExportable {
        return Customer.newObjectWithMoc(moc)
    }
    class func fetchBQExportable(cloudID: String, moc: NSManagedObjectContext) -> BQExportable? {
        return Customer.fetchForCloudID(cloudID, moc: moc)
    }
    
    func cascadeHasChangesUpdwards() {
        self.bqHasClientChanges = true
        // We are already a top level object so there is nothing else do
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
    class func customersMarkedForExport(managedObjectContext:NSManagedObjectContext) -> Set<Customer> {
        let predicate = NSPredicate(format: "bqNeedsCoreDataExport = %@", true)
        let fetchRequest = NSFetchRequest(entityName:"Customer")
        fetchRequest.predicate = predicate
        do {
            let fetchedResults = try managedObjectContext.executeFetchRequest(fetchRequest)
            return Set(fetchedResults as! [Customer])
        } catch {
            assertionFailure("Unable to fetch objects marked for export")
            return Set<Customer>()
        }
    }
}
// MARK:- Employee
extension Employee : BQExportable {
    class func newExportableWithMoc(moc: NSManagedObjectContext) -> BQExportable {
        return Employee.newObjectWithMoc(moc)
    }
    class func fetchBQExportable(cloudID: String, moc: NSManagedObjectContext) -> BQExportable? {
        return Employee.fetchForCloudID(cloudID, moc: moc)
    }
    func cascadeHasChangesUpdwards() {
        self.bqHasClientChanges = true
        // We are already a top level object so there is nothing else do
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
    class func employeesMarkedForExport(managedObjectContext:NSManagedObjectContext) -> Set<Employee> {
        let predicate = NSPredicate(format: "bqNeedsCoreDataExport = %@", true)
        let fetchRequest = NSFetchRequest(entityName:"Employee")
        fetchRequest.predicate = predicate
        do {
            let fetchedResults = try managedObjectContext.executeFetchRequest(fetchRequest)
            return Set(fetchedResults as! [Employee])
        } catch {
            assertionFailure("Unable to fetch objects marked for export")
            return Set<Employee>()
        }
    }
}
// MARK:- Service
extension Service : BQExportable {
    class func newExportableWithMoc(moc: NSManagedObjectContext) -> BQExportable {
        return Service.newObjectWithMoc(moc)
    }
    class func fetchBQExportable(cloudID: String, moc: NSManagedObjectContext) -> BQExportable? {
        return Service.fetchForCloudID(cloudID, moc: moc)
    }
    func cascadeHasChangesUpdwards() {
        self.bqHasClientChanges = true
        // We are already a top level object so there is nothing else do
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
    class func servicesMarkedForExport(managedObjectContext:NSManagedObjectContext) -> Set<Service> {
        let predicate = NSPredicate(format: "bqNeedsCoreDataExport = %@", true)
        let fetchRequest = NSFetchRequest(entityName:"Service")
        fetchRequest.predicate = predicate
        do {
            let fetchedResults = try managedObjectContext.executeFetchRequest(fetchRequest)
            return Set(fetchedResults as! [Service])
        } catch {
            assertionFailure("Unable to fetch objects marked for export")
            return Set<Service>()
        }
    }
}
// MARK:- ServiceCategory
extension ServiceCategory : BQExportable {
    class func newExportableWithMoc(moc: NSManagedObjectContext) -> BQExportable {
        return ServiceCategory.newObjectWithMoc(moc)
    }
    class func fetchBQExportable(cloudID: String, moc: NSManagedObjectContext) -> BQExportable? {
        return ServiceCategory.fetchForCloudID(cloudID, moc: moc)
    }
    func cascadeHasChangesUpdwards() {
        self.bqHasClientChanges = true
        // We are already a top level object so there is nothing else do
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
    class func serviceCategoriesMarkedForExport(managedObjectContext:NSManagedObjectContext) -> Set<ServiceCategory> {
        let predicate = NSPredicate(format: "bqNeedsCoreDataExport = %@", true)
        let fetchRequest = NSFetchRequest(entityName:"ServiceCategory")
        fetchRequest.predicate = predicate
        do {
            let fetchedResults = try managedObjectContext.executeFetchRequest(fetchRequest)
            return Set(fetchedResults as! [ServiceCategory])
        } catch {
            assertionFailure("Unable to fetch objects marked for export")
            return Set<ServiceCategory>()
        }
    }
}
// MARK:- SaleItem
extension SaleItem : BQExportable {
    class func newExportableWithMoc(moc: NSManagedObjectContext) -> BQExportable {
        return SaleItem.newObjectWithMoc(moc)
    }
    class func fetchBQExportable(cloudID: String, moc: NSManagedObjectContext) -> BQExportable? {
        return SaleItem.fetchForCloudID(cloudID, moc: moc)
    }
    func cascadeHasChangesUpdwards() {
        self.bqHasClientChanges = true
        self.sale?.cascadeHasChangesUpdwards()
    }
}
extension SaleItem {
    class func saleItemsMarkedForExport(managedObjectContext:NSManagedObjectContext) -> Set<SaleItem> {
        let predicate = NSPredicate(format: "bqNeedsCoreDataExport = %@", true)
        let fetchRequest = NSFetchRequest(entityName:"SaleItem")
        fetchRequest.predicate = predicate
        do {
            let fetchedResults = try managedObjectContext.executeFetchRequest(fetchRequest)
            return Set(fetchedResults as! [SaleItem])
        } catch {
            assertionFailure("Unable to fetch objects marked for export")
            return Set<SaleItem>()
        }
    }
}
// MARK:- Sale
extension Sale : BQExportable {
    class func newExportableWithMoc(moc: NSManagedObjectContext) -> BQExportable {
        return Sale.newObjectWithMoc(moc)
    }
    class func fetchBQExportable(cloudID: String, moc: NSManagedObjectContext) -> BQExportable? {
        return SaleItem.fetchForCloudID(cloudID, moc: moc)
    }
    func cascadeHasChangesUpdwards() {
        self.bqHasClientChanges = true
        self.fromAppointment?.cascadeHasChangesUpdwards()
    }
}
extension Sale {
    class func salesMarkedForExport(managedObjectContext:NSManagedObjectContext) -> Set<Sale> {
        let predicate = NSPredicate(format: "bqNeedsCoreDataExport = %@", true)
        let fetchRequest = NSFetchRequest(entityName:"Sale")
        fetchRequest.predicate = predicate
        do {
            let fetchedResults = try managedObjectContext.executeFetchRequest(fetchRequest)
            return Set(fetchedResults as! [Sale])
        } catch {
            assertionFailure("Unable to fetch objects marked for export")
            return Set<Sale>()
        }
    }
}

// MARK:- NSManagedObject extension
extension NSManagedObject {
    class func cloudkitRecordFromMetadata(metadata:NSData?)->CKRecord? {
        guard let metadata = metadata else {
            return nil
        }
        let unarchiver = NSKeyedUnarchiver(forReadingWithData: metadata)
        return CKRecord(coder: unarchiver)
    }
    func cloudkitRecordFromEmbeddedMetadata()->CKRecord? {
        if let bqObject = self as? BQExportable {
            return NSManagedObject.cloudkitRecordFromMetadata(bqObject.bqMetadata)
        }
        return nil;
    }
}


