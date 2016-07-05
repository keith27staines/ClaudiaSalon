//
//  Sale.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 25/01/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

#import "Sale.h"
#import "Account.h"
#import "Appointment.h"
#import "Customer.h"
#import "Note.h"
#import "Payment.h"
#import "SaleItem.h"

#import "SaleItem.h"
#import "Payment.h"
#import "Account.h"
#import "AMCDiscountCalculator.h"
#import "Salon.h"
#import "Customer.h"


@implementation Sale

+(NSManagedObject*)createObjectInMoc:(NSManagedObjectContext*)moc
{
    Sale * sale = [NSEntityDescription insertNewObjectForEntityForName:@"Sale" inManagedObjectContext:moc];
    NSDate * rightNow = [NSDate date];
    
    sale.nominalCharge = @(0);
    sale.actualCharge = @(0);
    
    sale.createdDate = rightNow;
    sale.lastUpdatedDate = rightNow;
    sale.discountVersion = @2;
    sale.account = [Salon salonWithMoc:moc].tillAccount;
    return sale;
}
+(NSArray*)allObjectsWithMoc:(NSManagedObjectContext*)moc {
    NSArray * array = nil;
    NSFetchRequest * fetch = [NSFetchRequest fetchRequestWithEntityName:@"Sale"];
    array = [moc executeFetchRequest:fetch error:nil];
    return array;
}

+(void)markSaleForExportInMoc:(NSManagedObjectContext*)parentMoc saleID:(NSManagedObjectID*)saleID {
    NSManagedObjectContext * privateMoc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    privateMoc.parentContext = parentMoc;
    [privateMoc performBlockAndWait:^{
        Sale * sale = [privateMoc objectWithID:saleID];
        Appointment * appointment = sale.fromAppointment;
        if (appointment) {
            NSDate * rightNow = [NSDate date];
            if (appointment.customer != sale.customer) {
                appointment.customer = sale.customer;
                appointment.customer.bqNeedsCoreDataExport = @YES;
                appointment.customer.lastUpdatedDate = rightNow;
                appointment.lastUpdatedDate = rightNow;
                appointment.bqNeedsCoreDataExport = @YES;
            }
            sale.lastUpdatedDate = rightNow;
            sale.bqNeedsCoreDataExport = @YES;
            for (SaleItem * saleItem in sale.saleItem) {
                saleItem.lastUpdatedDate = rightNow;
                saleItem.bqNeedsCoreDataExport = @YES;
            }
            
            NSError * error;
            [privateMoc save:(&error)];
            if (error) {
                NSAssert(@"Error while marking appointment for export: %@",error.description);
            }
        }
    }];
}

+(NSArray*)salesBetweenStartDate:(NSDate*)startDate endDate:(NSDate*)endDate withMoc:(NSManagedObjectContext*)moc{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Sale" inManagedObjectContext:moc];
    [fetchRequest setEntity:entity];
    // Specify criteria for filtering which objects to fetch
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"createdDate <= %@ && createdDate >= %@", endDate,startDate];
    [fetchRequest setPredicate:predicate];
    // Specify how the fetched objects should be sorted
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createdDate"
                                                                   ascending:YES];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];
    
    NSError *error = nil;
    NSArray *fetchedObjects = [moc executeFetchRequest:fetchRequest error:&error];
    if (fetchedObjects == nil) {
        NSLog(@"Unexpected error: %@",error);
    }
    return fetchedObjects;
}
+(Sale*)firstEverSaleWithMoc:(NSManagedObjectContext*)moc {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Sale" inManagedObjectContext:moc];
    [fetchRequest setEntity:entity];
    
    // Predicate
    NSPredicate * predicate = [NSPredicate predicateWithFormat:@"voided = %@ and isQuote = %@ and hidden = %@",@(NO),@(NO),@(NO)];
    // Specify how the fetched objects should be sorted
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createdDate"
                                                                   ascending:YES];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];
    [fetchRequest setPredicate:predicate];
    
    NSError *error = nil;
    NSArray *fetchedObjects = [moc executeFetchRequest:fetchRequest error:&error];
    if (!fetchedObjects || fetchedObjects.count == 0) {
        return nil;
    } else {
        return fetchedObjects[0];
    }
}
-(NSString*)saleType {
    if (self.isQuote.boolValue) {
        return @"Quote";
    } else {
        return @"Sale";
    }
}
-(BOOL)isVoidable {
    for (Payment * payment in self.payments) {
        if (payment.isReconciled) {
            return NO;
        }
    }
    return YES;
}
-(void)reopenAppointment {
    self.hidden = @(YES);
    self.isQuote = @(YES);
    self.amountGivenByCustomer = @(0);
    self.changeGiven = @(0);
    self.fromAppointment.completed = @(NO);
    self.fromAppointment.completionNote = @"";
    self.fromAppointment.completionType = AMCompletionTypeNotCompleted;
    for (Payment * payment in self.payments) {
        if (payment != self.advancePayment) {
            payment.voided = @YES;
        }
    }
}
-(void)setVoided:(NSNumber *)voided {
    NSString * voidedKey = @"voided";
    if ([voided isEqualToNumber:[self primitiveValueForKey:voidedKey]]) {
        return;
    }
    if (![self isVoidable]) {
        return;
    }
    if (voided) {
        for (Payment * payment in self.payments) {
            payment.voided = @(YES);
        }
        self.advancePayment = nil;
    }
    [self willChangeValueForKey:voidedKey];
    [self setPrimitiveValue:voided forKey:voidedKey];
    [self didChangeValueForKey:voidedKey];
}
-(Payment*)makePaymentInFull {
    return [self makePaymentOfAmount:[self amountOutstanding]];
}
-(void)makeAdvancePayment:(double)amount inAccount:(Account*)account {
    if (self.advancePayment) {
        self.advancePayment.voided = @(YES);
    }
    self.advancePayment = [self makePaymentOfAmount:amount inAccount:account];
    self.advancePayment.createdDate = [NSDate date];
    self.advancePayment.paymentDate = self.advancePayment.createdDate;
    self.advancePayment.reason = @"Sale - advance payment";
    self.advancePayment.paymentCategory = [Salon salonWithMoc:self.managedObjectContext].defaultPaymentCategoryForSales;
}
-(Payment*)makePaymentOfAmount:(double)amount inAccount:(Account*)account {
    NSAssert(account, @"account must not be nill");
    Payment * payment = nil;
    NSString * customerName = self.customer.fullName;
    if (!customerName || customerName.length == 0) {
        customerName = @"Customer";
    }
    Salon * salon = [Salon salonWithMoc:self.managedObjectContext];
    payment = [account makePaymentWithAmount:@(amount)
                                        date:self.createdDate
                                    category:salon.defaultPaymentCategoryForSales
                                   direction:kAMCPaymentDirectionIn
                                   payeeName:customerName
                                      reason:@"Sale"];
    payment.voided = self.voided;
    [self addPaymentsObject:payment];
    return payment;
    
}
-(Payment*)makePaymentOfAmount:(double)amount {
    NSAssert(self.account, @"account must not be nil");
    return [self makePaymentOfAmount:amount inAccount:self.account];
}
-(double)amountPaidNet {
    double amount = 0.0;
    for (Payment * payment in self.payments) {
        if (!payment.voided.boolValue) {
            amount += payment.amountNet.doubleValue;
        }
    }
    return amount;
}
-(double)amountPaid {
    double amount = 0.0;
    for (Payment * payment in self.payments) {
        if (!payment.voided.boolValue) {
            amount += payment.amount.doubleValue;
        }
    }
    return amount;
}
-(double)amountAdvanced {
    if (!self.advancePayment || self.advancePayment.voided.boolValue) {
        return 0;
    } else {
        return self.advancePayment.amount.doubleValue;
    }
}
-(double)amountOutstanding {
    return self.actualCharge.doubleValue - [self amountPaid];
}
-(NSString*)refundStatus
{
    double refundAmount = 0;
    for (SaleItem * saleItem in self.saleItem) {
        if (saleItem.refund) {
            refundAmount += saleItem.refund.amount.doubleValue;
        }
    }
    if (refundAmount == 0) {
        return @"";
    }
    if (refundAmount < self.actualCharge.doubleValue) {
        return [NSString stringWithFormat:@"Partial refund of £%1.2f",refundAmount];
    }
    if (refundAmount == self.actualCharge.doubleValue) {
        return [NSString stringWithFormat:@"Full refund of £%1.2f",refundAmount];
    }
    NSAssert(NO, @"Unexpected status");
    return @"Error";
}
-(NSNumber *)discountAmount
{
    return @(self.nominalCharge.doubleValue - self.actualCharge.doubleValue);
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
-(NSArray*)activeSaleItems {
    NSPredicate * activePredicate = [NSPredicate predicateWithFormat:@"isActive = %@",@YES];
    NSArray * allSaleItems = [self.saleItem allObjects];
    NSArray * activeSaleItems = [allSaleItems filteredArrayUsingPredicate:activePredicate];
    return activeSaleItems;
}
-(void)updatePriceFromSaleItems {
    double saleItemNominalTotal = 0.0;
    double saleItemActualTotal = 0.0;
    double nonDiscountedItemTotal = 0.0;
    for (SaleItem * saleItem in [self activeSaleItems]) {
        if (saleItem.isActive.boolValue) {
            saleItemNominalTotal += [AMCDiscountCalculator roundVeryCloseOrDown:saleItem.nominalCharge.doubleValue];
            saleItemActualTotal += [AMCDiscountCalculator roundVeryCloseOrDown:saleItem.actualCharge.doubleValue];
            if (saleItem.discountType.integerValue == AMCDiscountTypeNone) {
                nonDiscountedItemTotal += [AMCDiscountCalculator roundVeryCloseOrDown:saleItem.nominalCharge.doubleValue];
            }
        }
    }
    
    double extraDiscountAmount = 0.0;
    switch (self.discountType.integerValue) {
        case AMCDiscountTypeNone:
        {
            extraDiscountAmount = 0.0;
            break;
        }
        case AMCDiscountTypePercentage:
        {
            // Discount a percentage, but this acts only on the subtotal of the saleitems that haven't already had a discount applied
            extraDiscountAmount = [AMCDiscountCalculator calculateDiscountWithDiscountType:AMCDiscountTypePercentage discountValue:self.discountValue.doubleValue onPrice:nonDiscountedItemTotal];
            break;
        }
        case AMCDiscountTypeAbsoluteAmount:
        {
            // Discount an absolute amount on actual charge so far
            extraDiscountAmount = [AMCDiscountCalculator calculateDiscountWithDiscountType:AMCDiscountTypeAbsoluteAmount discountValue:self.discountValue.doubleValue onPrice:saleItemActualTotal];
            break;
        }
    }
    double actualCharge = saleItemActualTotal - extraDiscountAmount;
    double totalDiscount = saleItemNominalTotal - saleItemActualTotal + extraDiscountAmount;
    
    self.nominalCharge = @(saleItemNominalTotal);
    self.actualCharge = @(actualCharge);
    self.discountAmount = @(totalDiscount);
    self.chargeAfterIndividualDiscounts = @(saleItemActualTotal);
}
-(double)roundUpPenny:(double)amount
{
    return ceil(amount * 100.0) / 100.0;
}
-(double)roundDownPenny:(double)amount
{
    return floor(amount * 100.0) / 100.0;
}
-(void)convertToDiscountVersion2 {
    long discountVersion = self.discountVersion.integerValue;
    if (discountVersion >= 2) { return; }
    for (SaleItem * saleItem in self.saleItem) {
        [saleItem convertToDiscountVersion2];
    }
    self.discountType = @([AMCDiscountCalculator discountTypeForVersion1Discount:self.discountType.integerValue]);
    self.discountValue = @([AMCDiscountCalculator discountValueForVersion1Discount:self.discountType.integerValue]);
    self.discountVersion = @2;
}
@end

