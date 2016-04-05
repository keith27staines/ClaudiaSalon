//
//  BQCoredataImportController.swift
//  ClaudiaSalon
//
//  Created by Keith Staines on 23/02/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

import Foundation
import CloudKit
import CoreData

protocol AppointmentBuilder {
    var error: NSError? { get }
    var appointment: Appointment? { get }
}

extension BQExportable {
    func doesNeedUpdateFromCloud(cloudRecord:CKRecord) -> Bool {
        guard let metadata = self.bqMetadata else {
            return true // We have never been initialised with any data from the cloud
        }
        let decoder = NSKeyedUnarchiver(forReadingWithData: metadata)
        guard let _ = CKRecord(coder: decoder) else {
            print("Unable to decode the cloud record from the supplied metadata")
            return true
        }
        guard let lastUpdatedDate = self.lastUpdatedDate else {
            return true
        }
        if cloudRecord.modificationDate!.isGreaterThan(lastUpdatedDate) {
            return true
        }
        return false  // We don't need to update ourself as we are more recent
    }
    func updateFromCloudRecordIfNeeded(record:CKRecord) {
        if self.doesNeedUpdateFromCloud(record) {
            self.updateFromCloudRecord(record)
        }
    }
}
extension CKRecord {
    func metadataFromRecord() -> NSData {
        let data = NSMutableData()
        let coder = NSKeyedArchiver(forWritingWithMutableData: data)
        self.encodeSystemFieldsWithCoder(coder)
        coder.finishEncoding()
        return data
    }
}

extension Sale {
    class func makeFromCloudRecord(record:CKRecord, moc:NSManagedObjectContext) -> Sale {
        var sale: Sale!
        moc.performBlockAndWait() {
            precondition(record.recordType == "icloudSale", "Unable to create a customer from this record \(record)")
            sale = Sale.newObjectWithMoc(moc)
            sale.isQuote = true
            sale.hidden = true
            sale.updateFromCloudRecord(record)
        }
        return sale
    }
    class func fetchForCloudID(cloudID:String, moc:NSManagedObjectContext ) -> Sale? {
        let fetchRequest = NSFetchRequest(entityName: "Sale")
        let predicate = NSPredicate(format: "bqCloudID = %@", cloudID)
        fetchRequest.predicate = predicate
        var customers = [AnyObject]()
        moc.performBlockAndWait() {
            customers = try! moc.executeFetchRequest(fetchRequest)
        }
        return customers.first as! Sale?
    }
    func updateFromCloudRecord(record:CKRecord) {
        guard record.recordType == "icloudSale" else {
            assertionFailure("sale cannot be updated from recordType \(record.recordType)")
            return
        }
        self.managedObjectContext?.performBlockAndWait() {
            self.setBQDataFromRecord(record)
            self.bqNeedsCoreDataExport = NSNumber(bool: false)
            self.actualCharge = record["actualCharge"] as? NSNumber
            self.nominalCharge = record["nominalCharge"] as? NSNumber
            self.discountAmount = record["discountAmount"] as? NSNumber
            self.discountType = record["discountType"] as? NSNumber
            self.discountValue = record["discountValue"] as? NSNumber
            self.discountVersion = record["discountVersion"] as? NSNumber
            self.hidden = record["hidden"] as? NSNumber
            self.isQuote = record["isQuote"] as? NSNumber
            self.voided = record["voided"] as? NSNumber
        }
    }
}
extension SaleItem {
    class func makeFromCloudRecord(record:CKRecord, moc:NSManagedObjectContext) -> SaleItem {
        var saleItem: SaleItem!
        moc.performBlockAndWait() {
            precondition(record.recordType == "icloudSaleItem", "Unable to create a SaleItem from this record \(record)")
            saleItem = SaleItem.newObjectWithMoc(moc)
            saleItem.updateFromCloudRecord(record)
        }
        return saleItem
    }
    class func fetchForCloudID(cloudID:String, moc:NSManagedObjectContext ) -> SaleItem? {
        let fetchRequest = NSFetchRequest(entityName: "SaleItem")
        let predicate = NSPredicate(format: "bqCloudID = %@", cloudID)
        fetchRequest.predicate = predicate
        var saleItems = [AnyObject]()
        moc.performBlockAndWait() {
            saleItems = try! moc.executeFetchRequest(fetchRequest)
        }
        return saleItems.first as! SaleItem?
    }
    func updateFromCloudRecord(record:CKRecord) {
        guard record.recordType == "icloudSaleItem" else {
            assertionFailure("saleItem cannot be updated from recordType \(record.recordType)")
            return
        }
        self.managedObjectContext?.performBlockAndWait() {
            self.setBQDataFromRecord(record)
            self.bqNeedsCoreDataExport = NSNumber(bool: false)
            self.actualCharge = record["actualCharge"] as? NSNumber
            self.nominalCharge = record["nominalCharge"] as? NSNumber
            self.discountType = record["discountType"] as? NSNumber
            self.discountValue = record["discountValue"] as? NSNumber
            self.discountVersion = record["discountVersion"] as? NSNumber
            self.maximumCharge = record["maximumCharge"] as? NSNumber
            self.minimumCharge = record["minimumCharge"] as? NSNumber
            self.nominalCharge = record["nominalCharge"] as? NSNumber
            self.isActive = record["isActive"] as? Bool
        }
    }
}

extension Salon {
    class func makeFromCloudRecord(record:CKRecord, moc:NSManagedObjectContext) -> Salon {
        var salon: Salon!
        moc.performBlockAndWait() {
            precondition(record.recordType == "iCloudSalon", "Unable to create a salon from this record \(record)")
            salon = Salon(moc: moc)
            salon.updateFromCloudRecord(record)
        }
        return salon
    }
    class func fetchForCloudID(cloudID:String, moc:NSManagedObjectContext ) -> Salon? {
        let fetchRequest = NSFetchRequest(entityName: "Salon")
        let predicate = NSPredicate(format: "bqCloudID = %@", cloudID)
        fetchRequest.predicate = predicate
        var salons = [AnyObject]()
        moc.performBlockAndWait() {
            salons = try! moc.executeFetchRequest(fetchRequest)
        }
        return salons.first as! Salon?
    }
    func updateFromCloudRecord(record:CKRecord) {
        guard record.recordType == "iCloudSalon" else {
            assertionFailure("Salon cannot be updated from recordType \(record.recordType)")
            return
        }
        self.managedObjectContext?.performBlockAndWait() {
            self.setBQDataFromRecord(record)
            self.bqNeedsCoreDataExport = NSNumber(bool: false)
            self.salonName = record["name"] as? String
            self.postcode = record["postcode"] as? String
            self.phone = record["phone"] as? String
            self.addressLine1 = record["addressLine1"] as? String
            self.addressLine2 = record["addressLine2"] as? String
        }
    }
}

extension Customer {
    class func makeFromCloudRecord(record:CKRecord, moc:NSManagedObjectContext) -> Customer {
        var customer: Customer!
        moc.performBlockAndWait() {
            precondition(record.recordType == "icloudCustomer", "Unable to create a customer from this record \(record)")
            customer = Customer.newObjectWithMoc(moc)
            customer.updateFromCloudRecord(record)
        }
        return customer
    }
    class func fetchForCloudID(cloudID:String, moc:NSManagedObjectContext ) -> Customer? {
        let fetchRequest = NSFetchRequest(entityName: "Customer")
        let predicate = NSPredicate(format: "bqCloudID = %@", cloudID)
        fetchRequest.predicate = predicate
        var customers = [AnyObject]()
        moc.performBlockAndWait() {
            customers = try! moc.executeFetchRequest(fetchRequest)
        }
        return customers.first as! Customer?
    }
    func updateFromCloudRecord(record:CKRecord) {
        guard record.recordType == "icloudCustomer" else {
            assertionFailure("customer cannot be updated from recordType \(record.recordType)")
            return
        }
        self.managedObjectContext?.performBlockAndWait() {
            self.setBQDataFromRecord(record)
            self.bqNeedsCoreDataExport = NSNumber(bool: false)
            self.bqNeedsCloudImport = NSNumber(bool: false)
            self.firstName = record["firstName"] as? String
            self.lastName = record["lastName"] as? String
            self.phone = record["phone"] as? String
        }
    }
}
extension ServiceCategory {
    class func makeFromCloudRecord(record:CKRecord, moc:NSManagedObjectContext) -> ServiceCategory {
        var serviceCategory: ServiceCategory!
        moc.performBlockAndWait() {
            precondition(record.recordType == "iCloudServiceCategory", "Unable to create a Service Category from this record \(record)")
            serviceCategory = ServiceCategory.newObjectWithMoc(moc)
            serviceCategory.updateFromCloudRecord(record)
        }
        return serviceCategory
    }
    class func fetchForCloudID(cloudID:String, moc:NSManagedObjectContext ) -> ServiceCategory? {
        let fetchRequest = NSFetchRequest(entityName: "ServiceCategory")
        let predicate = NSPredicate(format: "bqCloudID = %@", cloudID)
        fetchRequest.predicate = predicate
        var serviceCategories = [AnyObject]()
        moc.performBlockAndWait() {
            serviceCategories = try! moc.executeFetchRequest(fetchRequest)
        }
        return serviceCategories.first as! ServiceCategory?
    }
    func updateFromCloudRecord(record:CKRecord) {
        guard record.recordType == "icloudServiceCategory" else {
            assertionFailure("Service Category cannot be updated from recordType \(record.recordType)")
            return
        }
        self.managedObjectContext?.performBlockAndWait() {
            self.setBQDataFromRecord(record)
            self.bqNeedsCoreDataExport = NSNumber(bool: false)
            self.name = record["name"] as? String
        }
    }
}
extension Service {
    class func makeFromCloudRecord(record:CKRecord, moc:NSManagedObjectContext) -> Service {
        var service: Service!
        moc.performBlockAndWait() {
            precondition(record.recordType == "iCloudService", "Unable to create a Service from this record \(record)")
            service = Service.newObjectWithMoc(moc)
            service.updateFromCloudRecord(record)
        }
        return service
    }
    class func fetchForCloudID(cloudID:String, moc:NSManagedObjectContext ) -> Service? {
        let fetchRequest = NSFetchRequest(entityName: "Service")
        let predicate = NSPredicate(format: "bqCloudID = %@", cloudID)
        fetchRequest.predicate = predicate
        var services = [AnyObject]()
        moc.performBlockAndWait() {
            services = try! moc.executeFetchRequest(fetchRequest)
        }
        return services.first as! Service?
    }
    func updateFromCloudRecord(record:CKRecord) {
        guard record.recordType == "iCloudService" else {
            assertionFailure("Service cannot be updated from recordType \(record.recordType)")
            return
        }
        self.managedObjectContext?.performBlockAndWait() {
            self.setBQDataFromRecord(record)
            self.bqNeedsCoreDataExport = NSNumber(bool: false)
            self.name = record["name"] as? String
            self.maximumCharge = record["maxPrice"] as? NSNumber
            self.minimumCharge = record["minPrice"] as? NSNumber
            self.nominalCharge = record["nominalPrice"] as? NSNumber
        }
    }
}
extension Employee {
    class func makeFromCloudRecord(record:CKRecord, moc:NSManagedObjectContext) -> Employee {
        var employee: Employee!
        moc.performBlockAndWait() {
            precondition(record.recordType == "icloudEmployee", "Unable to create an Employee from this record \(record)")
            employee = Employee.newObjectWithMoc(moc)
            employee.updateFromCloudRecord(record)
        }
        return employee
    }
    class func fetchForCloudID(cloudID:String, moc:NSManagedObjectContext ) -> Employee? {
        let fetchRequest = NSFetchRequest(entityName: "Employee")
        let predicate = NSPredicate(format: "bqCloudID = %@", cloudID)
        fetchRequest.predicate = predicate
        var employees = [AnyObject]()
        moc.performBlockAndWait() {
            employees = try! moc.executeFetchRequest(fetchRequest)
        }
        return employees.first as! Employee?
    }
    func updateFromCloudRecord(record:CKRecord) {
        guard record.recordType == "icloudEmployee" else {
            assertionFailure("Employee cannot be updated from recordType \(record.recordType)")
            return
        }
        self.managedObjectContext?.performBlockAndWait() {
            self.setBQDataFromRecord(record)
            self.bqNeedsCoreDataExport = NSNumber(bool: false)
            self.firstName = record["firstName"] as? String
            self.lastName = record["lastName"] as? String
            self.phone = record["phone"] as? String
            self.email = record["email"] as? String
            self.isActive = record["isActive"] as? Bool
        }
    }
}

extension Appointment {
    class func fetchForCloudID(cloudID:String, moc:NSManagedObjectContext) -> Appointment? {
        let fetchRequest = NSFetchRequest(entityName: "Appointment")
        let predicate = NSPredicate(format: "bqCloudID = %@", cloudID)
        fetchRequest.predicate = predicate
        var appointments = [AnyObject]()
        moc.performBlockAndWait() {
            appointments = try! moc.executeFetchRequest(fetchRequest)
        }
        return appointments.first as! Appointment?
    }
    class func makeFromCloudRecord(record:CKRecord, moc:NSManagedObjectContext) -> Appointment {
        var appointment:Appointment!
        moc.performBlockAndWait { () -> Void in
            precondition(record.recordType == "icloudAppointment", "Unable to create an appointment from this record \(record)")
            appointment = Appointment.newObjectWithMoc(moc)
            appointment.updateFromCloudRecord(record)
        }
        return appointment
    }
    func updateFromCloudRecord(record:CKRecord) {
        guard record.recordType == "icloudAppointment" else {
            assertionFailure("appointment cannot be updated from recordType \(record.recordType)")
            return
        }
        let startDate = record["appointmentStartDate"] as! NSDate
        let endDate = record["appointmentEndDate"] as! NSDate
        let bookedDuration = endDate.timeIntervalSinceDate(startDate)
        let cancelled = record["cancelled"]  as! Bool
        let completed = record["completed"] as! Bool
        self.managedObjectContext?.performBlockAndWait() {
            self.setBQDataFromRecord(record)
            self.bqNeedsCoreDataExport = NSNumber(bool: false)
            self.appointmentDate = startDate
            self.bookedDuration = NSNumber(double: bookedDuration)
            self.cancelled = NSNumber(bool: cancelled)
            self.completed = NSNumber(bool:completed)
        }
    }
}


