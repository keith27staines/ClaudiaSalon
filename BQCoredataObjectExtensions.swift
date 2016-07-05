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
    var bqHasClientChanges: NSNumber? { get set }
    var bqMetadata: NSData? { get set }
    var bqCloudID: String? { get set }
    var lastUpdatedDate: NSDate? { get set }
    
    var managedObjectContext:NSManagedObjectContext? { get }
    func updateFromCloudRecord(record:CKRecord)
    func cascadeHasChangesUpdwards()
    var objectID: NSManagedObjectID { get }
    static func createObjectInMoc(moc:NSManagedObjectContext) -> NSManagedObject
    //func prepareForInitialExport()
    //static func makeExportRecords() -> [CKRecord]
}

extension BQExportable {
    static func createBQExportableWithMoc(moc:NSManagedObjectContext) -> BQExportable {
        return self.createObjectInMoc(moc) as! BQExportable
    }
    func prepareForInitialExport() {
        self.bqNeedsCoreDataExport = true
        self.bqHasClientChanges = false
        self.bqMetadata = nil
    }
    static func makeExportRecords(bqExportables:[BQExportable], salonID: NSManagedObjectID) -> [CKRecord] {
        var icloudRecords = [CKRecord]()

        for bqExportable in bqExportables {
            let icloudRecord = ICloudRecord.makeICloudRecord(bqExportable, parentSalonID: salonID)
            let ckRecord = icloudRecord.makeCloudKitRecord()
            icloudRecords.append(ckRecord)
        }
        return icloudRecords
    }

    static func fetchBQExportable(cloudID: String, moc: NSManagedObjectContext) -> BQExportable? {
        let icloudRecordType = ICloudRecordType(bqExportableType: self)
        let fetchRequest = NSFetchRequest(entityName: icloudRecordType.coredataEntityName())
        let predicate = NSPredicate(format: "bqCloudID = %@", cloudID)
        fetchRequest.predicate = predicate
        var bqExportables = [BQExportable]()
        moc.performBlockAndWait() {
            bqExportables = try! moc.executeFetchRequest(fetchRequest) as! [BQExportable]
        }
        return bqExportables.first
    }
    
    static func fetchOrCreateBQExportable(cloudID: String, moc: NSManagedObjectContext) -> BQExportable {
        if let bqExportable = self.fetchBQExportable(cloudID, moc: moc) {
            return bqExportable
        } else {
            return self.createObjectInMoc(moc) as! BQExportable
        }
    }

    func doesNeedUpdateFromCloud(cloudRecord:CKRecord) -> Bool {
        return true
    }
    func updateFromCloudRecordIfNeeded(record:CKRecord) {
        if self.doesNeedUpdateFromCloud(record) {
            self.updateFromCloudRecord(record)
        }
    }
    func recordChangeTag() -> String? {
        guard let cloudRecord = self.cloudRecordFromMetadata() else { return nil }
        return cloudRecord.recordChangeTag
    }
    func setBQDataFromRecord(record:CKRecord) {
        self.managedObjectContext!.performBlockAndWait() {
            self.bqCloudID = record.recordID.recordName
            self.bqMetadata = record.metadataFromRecord()
            self.lastUpdatedDate = record.modificationDate
            self.bqNeedsCoreDataExport = NSNumber(bool: false)
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

// MARK:- Account
extension Account : BQExportable {

    class func fetchBQExportable(cloudID: String, moc:NSManagedObjectContext) -> BQExportable? {
        return Account.fetchBQExportable(cloudID, moc: moc)
    }
    func cascadeHasChangesUpdwards() {
        self.bqHasClientChanges = true
        // We are already a top level object so there is nothing else do
    }
    
    func updateFromCloudRecord(record:CKRecord) {
        guard record.recordType == "icloudAccount" else {
            assertionFailure("Account cannot be updated from recordType \(record.recordType)")
            return
        }
        
        self.managedObjectContext?.performBlockAndWait() {
            self.setBQDataFromRecord(record)
            
            self.accountNumber = record["accountNumber"] as? String
            self.bankName = record["bankName"] as? String
            self.sortCode = record["sortCode"] as? String
            self.isActive = record["isActive"] as? Bool
        }
    }
}
// MARK:- AccountReconciliation : BQExportable
extension AccountReconciliation : BQExportable {
    func updateFromCloudRecord(record: CKRecord) {
        
    }
    class func createBQExportableWithMoc(moc: NSManagedObjectContext) -> BQExportable {
        return AccountReconciliation.createObjectInMoc(moc) as! BQExportable
    }
    func cascadeHasChangesUpdwards() {
        self.bqHasClientChanges = true
        // We are already a top level object so there is nothing else do
    }
}
// MARK: PaymentCategory : BQExportable
extension PaymentCategory : BQExportable {
    func updateFromCloudRecord(record: CKRecord) {
        
    }
    class func createBQExportableWithMoc(moc: NSManagedObjectContext) -> BQExportable {
        return AccountReconciliation.createObjectInMoc(moc) as! BQExportable
    }
    func cascadeHasChangesUpdwards() {
        self.bqHasClientChanges = true
        // We are already a top level object so there is nothing else do
    }
}
// MARK:- Payment : BQExportable 
extension Payment : BQExportable {
    func updateFromCloudRecord(record: CKRecord) {
        
    }
    class func createBQExportableWithMoc(moc: NSManagedObjectContext) -> BQExportable {
        return AccountReconciliation.createObjectInMoc(moc) as! BQExportable
    }
    func cascadeHasChangesUpdwards() {
        self.bqHasClientChanges = true
        // We are already a top level object so there is nothing else do
    }
}

// MARK:- Salon
extension Salon : BQExportable {
    class func createBQExportableWithMoc(moc: NSManagedObjectContext) -> BQExportable {
        return Salon.createObjectInMoc(moc) as! BQExportable
    }
    class func fetchBQExportable(cloudID: String, moc: NSManagedObjectContext) -> BQExportable? {
        return Salon.fetchForCloudID(cloudID, moc: moc)
    }
    func cascadeHasChangesUpdwards() {
        self.bqHasClientChanges = true
        // We are already a top level object so there is nothing else do
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
            self.salonName = record["name"] as? String
            self.postcode = record["postcode"] as? String
            self.phone = record["phone"] as? String
            self.addressLine1 = record["addressLine1"] as? String
            self.addressLine2 = record["addressLine2"] as? String
        }
    }
}

// MARK:- Appointment
extension Appointment : BQExportable {
    class func createBQExportableWithMoc(moc: NSManagedObjectContext) -> BQExportable {
        return Appointment.createObjectInMoc(moc) as! BQExportable
    }
    class func fetchBQExportable(cloudID: String, moc: NSManagedObjectContext) -> BQExportable? {
        return Appointment.fetchForCloudID(cloudID, moc: moc)
    }
    func cascadeHasChangesUpdwards() {
        self.bqHasClientChanges = true
        // We are already a top level object so there is nothing else do
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
            self.appointmentDate = startDate
            self.bookedDuration = NSNumber(double: bookedDuration)
            self.cancelled = NSNumber(bool: cancelled)
            self.completed = NSNumber(bool:completed)
        }
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
            appointment = Appointment.createObjectInMoc(moc) as! Appointment
            appointment.updateFromCloudRecord(record)
        }
        return appointment
    }
}

// MARK:- Customer
extension Customer : BQExportable {
    class func createBQExportableWithMoc(moc: NSManagedObjectContext) -> BQExportable {
        return Customer.createObjectInMoc(moc) as! BQExportable
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
extension Customer {
    class func makeFromCloudRecord(record:CKRecord, moc:NSManagedObjectContext) -> Customer {
        var customer: Customer!
        moc.performBlockAndWait() {
            precondition(record.recordType == "icloudCustomer", "Unable to create a customer from this record \(record)")
            customer = Customer.createObjectInMoc(moc) as! Customer
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

            self.firstName = record["firstName"] as? String
            self.lastName = record["lastName"] as? String
            self.phone = record["phone"] as? String
        }
    }
}
// MARK:- Employee
extension Employee : BQExportable {
    class func createBQExportableWithMoc(moc: NSManagedObjectContext) -> BQExportable {
        return Employee.createObjectInMoc(moc) as! BQExportable
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
extension Employee {
    class func makeFromCloudRecord(record:CKRecord, moc:NSManagedObjectContext) -> Employee {
        var employee: Employee!
        moc.performBlockAndWait() {
            precondition(record.recordType == "icloudEmployee", "Unable to create an Employee from this record \(record)")
            employee = Employee.createObjectInMoc(moc) as! Employee
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
        
            self.firstName = record["firstName"] as? String
            self.lastName = record["lastName"] as? String
            self.phone = record["phone"] as? String
            self.email = record["email"] as? String
            self.password = record["password"] as? String
            self.isActive = record["isActive"] as? Bool
        }
    }
}
// MARK:- Service
extension Service : BQExportable {
    class func createBQExportableWithMoc(moc: NSManagedObjectContext) -> BQExportable {
        return Service.createObjectInMoc(moc) as! BQExportable
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
    class func makeFromCloudRecord(record:CKRecord, moc:NSManagedObjectContext) -> Service {
        var service: Service!
        moc.performBlockAndWait() {
            precondition(record.recordType == "iCloudService", "Unable to create a Service from this record \(record)")
            service = Service.createObjectInMoc(moc) as! Service
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
            
            self.name = record["name"] as? String
            self.maximumCharge = record["maxPrice"] as? NSNumber
            self.minimumCharge = record["minPrice"] as? NSNumber
            self.nominalCharge = record["nominalPrice"] as? NSNumber
        }
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
    class func createBQExportableWithMoc(moc: NSManagedObjectContext) -> BQExportable {
        return ServiceCategory.createObjectInMoc(moc) as! BQExportable
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
extension ServiceCategory {
    class func makeFromCloudRecord(record:CKRecord, moc:NSManagedObjectContext) -> ServiceCategory {
        var serviceCategory: ServiceCategory!
        moc.performBlockAndWait() {
            precondition(record.recordType == "iCloudServiceCategory", "Unable to create a Service Category from this record \(record)")
            serviceCategory = ServiceCategory.createObjectInMoc(moc) as! ServiceCategory
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
            
            self.name = record["name"] as? String
        }
    }
}
// MARK:- SaleItem
extension SaleItem : BQExportable {
    class func createBQExportableWithMoc(moc: NSManagedObjectContext) -> BQExportable {
        return SaleItem.createObjectInMoc(moc) as! BQExportable
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
extension SaleItem {
    class func makeFromCloudRecord(record:CKRecord, moc:NSManagedObjectContext) -> SaleItem {
        var saleItem: SaleItem!
        moc.performBlockAndWait() {
            precondition(record.recordType == "icloudSaleItem", "Unable to create a SaleItem from this record \(record)")
            saleItem = SaleItem.createObjectInMoc(moc) as! SaleItem
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

// MARK:- Sale : BQExportable extension
extension Sale : BQExportable {
    class func createBQExportableWithMoc(moc: NSManagedObjectContext) -> BQExportable {
        return Sale.createObjectInMoc(moc) as! BQExportable
    }
    class func fetchBQExportable(cloudID: String, moc: NSManagedObjectContext) -> BQExportable? {
        return Sale.fetchForCloudID(cloudID, moc: moc)
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
// MARK:- Sale extensions
extension Sale {
    class func makeFromCloudRecord(record:CKRecord, moc:NSManagedObjectContext) -> Sale {
        var sale: Sale!
        moc.performBlockAndWait() {
            precondition(record.recordType == "icloudSale", "Unable to create a customer from this record \(record)")
            sale = Sale.createObjectInMoc(moc) as! Sale
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


