//
//  Payment.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 25/01/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

#import "Payment.h"
#import "Account.h"
#import "Note.h"
#import "PaymentCategory.h"
#import "RecurringItem.h"
#import "Sale.h"
#import "SaleItem.h"
#import "ShoppingList.h"
#import "WorkRecord.h"
#import "AMCConstants.h"
#import "Salon.h"


@implementation Payment
+(NSManagedObject*)createObjectInMoc:(NSManagedObjectContext*)moc
{
    Payment * payment = [NSEntityDescription insertNewObjectForEntityForName:@"Payment" inManagedObjectContext:moc];
    NSDate * rightNow = [NSDate date];
    payment.createdDate = rightNow;
    payment.lastUpdatedDate = rightNow;
    payment.paymentDate = rightNow;
    payment.payeeName = @"";
    payment.reason = @"";
    payment.amount = @(0);
    payment.direction = kAMCPaymentDirectionOut;
    payment.paymentCategory = [Salon salonWithMoc:moc].defaultPaymentCategoryForPayments;
    return payment;
}
+(NSArray*)allObjectsWithMoc:(NSManagedObjectContext*)moc {
    NSArray * array = nil;
    NSFetchRequest * fetch = [NSFetchRequest fetchRequestWithEntityName:@"Payment"];
    array = [moc executeFetchRequest:fetch error:nil];
    return array;
}
+(NSArray*)nonSalepaymentsBetweenStartDate:(NSDate*)startDate endDate:(NSDate*)endDate withMoc:(NSManagedObjectContext*)moc {
    return [[self paymentsBetweenStartDate:startDate endDate:endDate withMoc:moc] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"sale = nil"]];
}
+(NSArray*)paymentsBetweenStartDate:(NSDate*)startDate endDate:(NSDate*)endDate withMoc:(NSManagedObjectContext*)moc {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Payment" inManagedObjectContext:moc];
    [fetchRequest setEntity:entity];
    // Specify criteria for filtering which objects to fetch
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"paymentDate <= %@ && paymentDate >= %@ && voided == %@", endDate,startDate,@NO];
    [fetchRequest setPredicate:predicate];
    // Specify how the fetched objects should be sorted
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"paymentDate"
                                                                   ascending:YES];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];
    
    NSError *error = nil;
    NSArray *fetchedObjects = [moc executeFetchRequest:fetchRequest error:&error];
    if (fetchedObjects == nil) {
        NSLog(@"Unexpected error: %@",error);
    }
    return fetchedObjects;
}
-(BOOL)isReconciled {
    return [self.account isReconciledToDate:self.paymentDate];
}
-(BOOL)isIncoming {
    return [self.direction isEqualToString:kAMCPaymentDirectionIn];
}
-(BOOL)isOutgoing {
    return !self.isIncoming;
}
-(NSNumber *)signedAmount {
    if (self.isIncoming) {
        return self.amount;
    } else {
        return @(-self.amount.doubleValue);
    }
}
-(NSNumber *)signedAmountNet {
    if (self.isIncoming) {
        return self.amountNet;
    } else {
        return @(-self.amountNet.doubleValue);
    }
}
-(NSString*)refundYNString
{
    return (self.refunding)?@"Yes":@"No";
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
-(NSNumber*)calculateFeeForAmount:(NSNumber*)amount withFeePercentage:(NSNumber*)feePercent {
    if ([self.direction isEqualToString:kAMCPaymentDirectionIn]) {
        return [self feeFromAmount:amount withPercentage:feePercent];
    }
    return @(0);
}
-(NSNumber*)calculateFeeForAmount:(NSNumber*)amount {
    if (self.isIncoming) {
        NSNumber * feePercent = self.account.transactionFeePercentageIncoming;
        return [self calculateFeeForAmount:amount withFeePercentage:feePercent];
    }
    return 0;
}
-(NSNumber*)feeFromAmount:(NSNumber*)amount withPercentage:(NSNumber*)feePercent {
    double fee = (100.0 * amount.doubleValue) * feePercent.doubleValue;
    if (fee - floor(fee) < 0.5) {
        fee = floor(fee);
    } else {
        fee = ceil(fee);
    }
    return @(fee/100.0);
}
-(NSNumber*)amountAfterFeeFrom:(NSNumber*)amount withFeePercentage:(NSNumber*)feePercent {
    NSNumber * fee = [self feeFromAmount:amount withPercentage:feePercent];
    return [self amountAfterFeeFrom:amount fee:fee];
}
-(NSNumber*)amountAfterFeeFrom:(NSNumber*)amount fee:(NSNumber*)fee {
    double after = amount.doubleValue - fee.doubleValue;
    return @(round(after*100)/100.0);
}
-(void)recalculateNetAmountWithFeePercentage:(NSNumber*)feePercent {
    NSNumber * fee = [self calculateFeeForAmount:self.amount withFeePercentage:feePercent];
    [self recalculateNetAmountWithFee:fee];
}
-(void)recalculateFromCurrentAmount {
    [self recalculateWithAmount:self.amount];
}
-(void)recalculateWithAmount:(NSNumber *)amount {
    if (self.isIncoming) {
        [self recalculateWithAmount:amount feePercent:self.account.transactionFeePercentageIncoming];
    } else {
        [self recalculateWithAmount:amount feePercent:self.account.transactionFeePercentageOutgoing];
    }
}
-(void)recalculateNetAmountWithFee:(NSNumber *)fee {
    if (self.isIncoming) {
        self.transactionFee = fee;
        self.amountNet = [self amountAfterFeeFrom:self.amount fee:fee];
    } else {
        self.transactionFee = @0;
        self.amountNet = self.amount;
    }
}
-(void)recalculateWithAmount:(NSNumber *)amount fee:(NSNumber *)fee {
    self.amount = amount;
    [self recalculateNetAmountWithFee:fee];
}
-(void)recalculateWithAmount:(NSNumber *)amount feePercent:(NSNumber*)fee {
    self.amount = amount;
    [self recalculateNetAmountWithFeePercentage:fee];
}
@end
