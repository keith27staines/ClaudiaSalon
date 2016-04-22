//
//  AMCReportWorkerOperation.swift
//  ClaudiaSalon
//
//  Created by Keith Staines on 11/02/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

import Foundation
@objc
class AMCReportWorkerOperation : NSOperation {
    var startDate:NSDate
    var endDate:NSDate
    let earliestDate:NSDate
    var salesTotal = 0.0
    var paymentsTotal = 0.0
    var hairTotal = 0.0
    var beautyTotal = 0.0
    var subIntervalCompletionBlock: ((row:Int,dictionary:[String:NSObject])->Void)?
    let gregorian = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
    let reportingInterval:AMCReportingInterval
    let parentMoc:NSManagedObjectContext
    var moc:NSManagedObjectContext?
    
    init(startDate:NSDate, endDate:NSDate, earliestDate:NSDate, parentMoc:NSManagedObjectContext,reportingInterval:AMCReportingInterval) {
        self.startDate = startDate
        self.endDate = endDate
        self.earliestDate = earliestDate
        self.parentMoc = parentMoc
        self.reportingInterval = reportingInterval
    }
    override func main() {
        self.moc = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        self.moc?.parentContext = self.parentMoc
        //self.moc!.persistentStoreCoordinator = parentMoc.persistentStoreCoordinator
        self.moc!.performBlockAndWait {
            var row = 0
            while self.endDate.isGreaterThan(self.earliestDate) {
                if self.cancelled { return }
                let sales = self.salesBetween(self.startDate, before: self.endDate)
                if self.cancelled { return }
                let payments = self.paymentsBetween(self.startDate, before: self.endDate)
                self.salesTotal = 0
                self.paymentsTotal = 0
                self.hairTotal = 0
                self.beautyTotal = 0
                for sale in sales {
                    if self.cancelled { return }
                    guard !sale.voided!.boolValue && !sale.isQuote!.boolValue else {
                        continue
                    }
                    self.salesTotal += sale.actualCharge!.doubleValue
                    for saleItem in sale.saleItem! {
                        guard let service = saleItem.service else {
                            continue
                        }
                        guard saleItem.isActive == true else {
                            continue
                        }
                        let saleAmount = saleItem.actualCharge!.doubleValue
                        //self.salesTotal += saleAmount
                        if service.serviceCategory!.isHairCategory() {
                            self.hairTotal += saleAmount
                        } else {
                            self.beautyTotal += saleAmount
                        }
                    }
                }
                for payment in payments {
                    if self.cancelled { return }
                    //guard !payment.voided!.boolValue && payment.sale != nil else {
                    guard payment.voided!.boolValue != true else {
                        continue
                    }
                    guard payment.sale == nil else {
                        continue
                    }
                    if payment.isOutgoing.boolValue {
                        self.paymentsTotal += payment.amount!.doubleValue
                    } else {
                        self.paymentsTotal -= payment.amount!.doubleValue
                    }
                }
                let dictionary = ["date": self.startDate,"hairCategories":self.hairTotal, "beautyCategories":self.beautyTotal ,"allCategories":self.salesTotal, "payments":self.paymentsTotal, "profits":(self.salesTotal - self.paymentsTotal)]
                
                if let subIntervalBlock = self.subIntervalCompletionBlock {
                    if self.cancelled {
                        return
                    }
                    subIntervalBlock(row: row, dictionary: dictionary)
                }
                self.startDate = self.previousStartDate(self.startDate)
                self.endDate = self.endDateFromStartDate(self.startDate)
                row += 1;
            }
        }
    }
    func previousStartDate(startDate:NSDate) -> NSDate {
        let offsetComponents = NSDateComponents()
        switch self.reportingInterval {
        case .Daily:
            offsetComponents.day = -1
        case .Weekly:
            offsetComponents.day = -7
        case .Monthly:
            offsetComponents.month = -1
        case .Yearly:
            offsetComponents.year = -1
        }
        let previous = self.gregorian.dateByAddingComponents(offsetComponents, toDate: startDate, options: NSCalendarOptions.init(rawValue: 0))!
        return previous
    }
    func endDateFromStartDate(startDate:NSDate) -> NSDate {
        let offsetComponents = NSDateComponents()
        switch self.reportingInterval {
        case .Daily:
            offsetComponents.day = 1
        case .Weekly:
            offsetComponents.day = 7
        case .Monthly:
            offsetComponents.month = 1
        case .Yearly:
            offsetComponents.year = 1
        }
        let endDate = self.gregorian.dateByAddingComponents(offsetComponents, toDate: startDate, options: NSCalendarOptions.init(rawValue: 0))!
        return endDate
    }
    func salesBetween(after:NSDate,before:NSDate) -> [Sale] {
        let fetchRequest = NSFetchRequest(entityName: "Sale")
        let predicate = NSPredicate(format:"createdDate >= %@ and createdDate < %@", after,before)
        fetchRequest.predicate = predicate
        do {
            let fetchedObjects = try self.moc!.executeFetchRequest(fetchRequest) as! Array<Sale>
            return fetchedObjects.sort({ (sale1, sale2) -> Bool in
                return (sale1.createdDate!.isLessThan(sale2.createdDate))
            })
        } catch {
            return [Sale]()
        }
    }
    func paymentsBetween(after:NSDate,before:NSDate)->[Payment] {
        let fetchRequest = NSFetchRequest(entityName: "Payment")
        let predicate = NSPredicate(format:"paymentDate >= %@ and paymentDate < %@", after,before)
        fetchRequest.predicate = predicate
        do {
            let fetchedObjects = try self.moc!.executeFetchRequest(fetchRequest) as! Array<Payment>
            return fetchedObjects.sort({ (payment1, payment2) -> Bool in
                return (payment1.paymentDate!.isLessThan(payment2.paymentDate))
            })
        } catch {
            return [Payment]()
        }
    }
}




