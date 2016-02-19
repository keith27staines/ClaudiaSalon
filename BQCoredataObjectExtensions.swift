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

// MARK:- NSManagedObject extension
extension NSManagedObject {
    func markAsExported() {
        switch self.className {
        case "Salon":
            let salon = self as! Salon
            salon.bqNeedsCoreDataExport = NSNumber(bool: false)
            break
        case "Customer":
            let customer = self as! Customer
            customer.bqNeedsCoreDataExport = NSNumber(bool: false)
            break
        case "Employee":
            let employee = self as! Employee
            employee.bqNeedsCoreDataExport = NSNumber(bool: false)
            break
        case "Service":
            let service = self as! Service
            service.bqNeedsCoreDataExport = NSNumber(bool: false)
            break
        case "ServiceCategory":
            let serviceCategory = self as! ServiceCategory
            serviceCategory.bqNeedsCoreDataExport = NSNumber(bool: false)
            break
        case "Appointment":
            let appointment = self as! Appointment
            appointment.bqNeedsCoreDataExport = NSNumber(bool: false)
            break
        case "Sale":
            let sale = self as! Sale
            sale.bqNeedsCoreDataExport = NSNumber(bool: false)
            break
        case "SaleItem":
            let saleItem = self as! SaleItem
            saleItem.bqNeedsCoreDataExport = NSNumber(bool: false)
            break
        default:
            break
        }
    }
}
// MARK:- NSManagedObjectContext extension
extension NSManagedObjectContext {
    func objectForIDString(coredataIDString:String) -> NSManagedObject {
        guard let coordinator = self.persistentStoreCoordinator else {
            preconditionFailure("The managed object context doesn't have a persistent store coordinator")
        }
        guard let uriRepresentation = NSURL(string: coredataIDString) else {
            preconditionFailure("Unable to construct a URL from the string \(coredataIDString)")
        }
        guard let managedObjectID = coordinator.managedObjectIDForURIRepresentation(uriRepresentation) else {
            preconditionFailure("The persistent store coordinate didn't return an objectID for the URL representation")
        }
        return self.objectWithID(managedObjectID)
    }
}



////////////////

// MARK:- Appointment
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
        return NSManagedObject.cloudkitRecordFromMetadata(self.bqdata?.metadata)
    }
    func setbqdata(data:NSData) {
        let className = self.className
        switch className {
        case Salon.className():
            let salon = self as! Salon
            salon.bqMetadata = data
        case Employee.className():
            let employee = self as! Employee
            employee.bqMetadata = data
        case Customer.className():
            let customer = self as! Customer
            customer.bqMetadata = data
        case ServiceCategory.className():
            let serviceCategory = self as! ServiceCategory
            serviceCategory.bqMetadata = data
        case Service.className():
            let service = self as! Service
            service.bqMetadata = data
        case Appointment.className():
            let appointment = self as! Appointment
            appointment.bqMetadata = data
        case Sale.className():
            let sale = self as! Sale
            sale.bqMetadata = data
        case SaleItem.className():
            let saleItem = self as! SaleItem
            saleItem.bqMetadata = data
        default:
            break
        }
    }
    var bqdata:(metadata:NSData?,bqNeedsExport:Bool)? {
        let className = self.className
        switch className {
        case Salon.className():
            let salon = self as! Salon
            return (salon.bqMetadata,salon.bqNeedsCoreDataExport!.boolValue)
        case Employee.className():
            let employee = self as! Employee
            return (employee.bqMetadata,employee.bqNeedsCoreDataExport!.boolValue)
        case Customer.className():
            let customer = self as! Customer
            return (customer.bqMetadata,customer.bqNeedsCoreDataExport!.boolValue)
        case ServiceCategory.className():
            let serviceCategory = self as! ServiceCategory
            return (serviceCategory.bqMetadata,serviceCategory.bqNeedsCoreDataExport!.boolValue)
        case Service.className():
            let service = self as! Service
            return (service.bqMetadata,service.bqNeedsCoreDataExport!.boolValue)
        case Appointment.className():
            let appointment = self as! Appointment
            return (appointment.bqMetadata,appointment.bqNeedsCoreDataExport!.boolValue)
        case Sale.className():
            let sale = self as! Sale
            return (sale.bqMetadata,sale.bqNeedsCoreDataExport!.boolValue)
        case SaleItem.className():
            let saleItem = self as! SaleItem
            return (saleItem.bqMetadata,saleItem.bqNeedsCoreDataExport!.boolValue)
        default:
            return nil
        }
    }
}