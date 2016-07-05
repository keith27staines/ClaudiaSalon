//
//  Customer.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 25/01/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

#import "Customer.h"
#import "Appointment.h"
#import "Note.h"
#import "Sale.h"
#import "Salon.h"
#import "SaleItem.h"
#import "Payment.h"
#import "Note.h"
#import "NSDate+AMCDate.h"

@implementation Customer

+(NSManagedObject*)createObjectInMoc:(NSManagedObjectContext*)moc
{
    Customer * customer = [NSEntityDescription insertNewObjectForEntityForName:@"Customer" inManagedObjectContext:moc];
    NSDate * rightNow = [NSDate date];
    customer.createdDate = rightNow;
    customer.lastUpdatedDate = rightNow;
    customer.firstName = @"";
    customer.lastName = @"";
    customer.phone = @"";
    customer.email = @"";
    customer.postcode = @"";
    customer.addressLine1 = @"";
    customer.addressLine2 = @"";
    customer.dayOfBirth = 0;
    customer.monthOfBirth = 0;
    return customer;
}
+(NSArray*)allObjectsWithMoc:(NSManagedObjectContext*)moc {
    NSArray * array = nil;
    NSFetchRequest * fetch = [NSFetchRequest fetchRequestWithEntityName:@"Customer"];
    array = [moc executeFetchRequest:fetch error:nil];
    return array;
}
-(NSString *)fullName
{
    NSString * first = self.firstName;
    NSString * last = self.lastName;
    NSString * full = @"";
    if (first && first.length > 0) {
        full = [first copy];
    }
    if (last &&  last.length > 0) {
        full = [full stringByAppendingString:@" "];
        full = [full stringByAppendingString:last];
    }
    return full;
}
-(NSNumber*)numberOfPreviousVisits {
    NSInteger i = 0;
    for (Sale * sale in self.sales) {
        if (sale.voided.boolValue) continue;
        if (sale.isQuote.boolValue) continue;
        i++;
    }
    return @(i);
}
-(NSDate*)lastVisitDate
{
    NSDate * lastVisit = self.createdDate;
    if (self.sales) {
        for (Sale * sale in self.sales) {
            if ([sale.createdDate isGreaterThan:lastVisit]) {
                lastVisit = sale.createdDate;
            }
        }
    }
    return lastVisit;
}
-(NSString *)birthday
{
    NSInteger day = self.dayOfBirth.integerValue;
    NSInteger month = self.monthOfBirth.integerValue;
    NSString * monthString = (month>0)?[NSDate monthNameFromNumber:month]:@"";
    NSString * dayString = (day>0)?@(day).stringValue:@"";
    return [NSString stringWithFormat:@"%@ %@",dayString,monthString];
}
-(NSNumber*)totalMoneySpent {
    double total = 0;
    for (Sale * sale in self.sales) {
        if (sale.isQuote.boolValue) continue;
        if (sale.voided.boolValue) continue;
        if (sale.hidden.boolValue) continue;
        total += sale.actualCharge.doubleValue;
    }
    return @(total);
}
-(NSNumber*)totalMoneyRefunded {
    double total = 0;
    for (Sale * sale in self.sales) {
        if (sale.isQuote.boolValue) continue;
        if (sale.voided.boolValue) continue;
        if (sale.hidden.boolValue) continue;
        for (SaleItem * saleItem in sale.saleItem) {
            if (saleItem.refund && !saleItem.refund.voided.boolValue) {
                total += saleItem.refund.amount.doubleValue;
            }
        }
    }
    return @(total);
}

-(NSSet*)nonAuditNotes {
    NSMutableSet * nonAuditNotes = [NSMutableSet set];
    for (Note * note in self.notes) {
        if (!note.isAuditNote.boolValue) {
            [nonAuditNotes addObject:note];
        }
    }
    return nonAuditNotes;
}
@end
