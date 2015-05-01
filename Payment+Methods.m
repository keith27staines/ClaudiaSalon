//
//  Payment+Methods.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 23/07/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "Payment+Methods.h"
#import "AMCConstants.h"
#import "Salon+Methods.h"
#import "Account+Methods.h"

@implementation Payment (Methods)
+(id)newObjectWithMoc:(NSManagedObjectContext*)moc
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
        [NSApp presentError:error];
    }
    return fetchedObjects;
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
    if ([self.direction isEqualToString:kAMCPaymentDirectionIn]) {
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
    if ([self.direction isEqualToString:kAMCPaymentDirectionIn]) {
        self.transactionFeeIncoming = [self calculateFeeForAmount:self.amount withFeePercentage:feePercent];
        self.amountNet = [self amountAfterFeeFrom:self.amount withFeePercentage:feePercent];
    }
}
-(void)recalculateWithAmount:(NSNumber *)amount {
    if ([self.direction isEqualToString:kAMCPaymentDirectionIn]) {
        [self recalculateWithAmount:amount feePercent:self.account.transactionFeePercentageIncoming];
    }
}
-(void)recalculateNetAmountWithFee:(NSNumber *)fee {
    if ([self.direction isEqualToString:kAMCPaymentDirectionIn]) {
        self.transactionFeeIncoming = fee;
        self.amountNet = [self amountAfterFeeFrom:self.amount fee:fee];
    } else {
        self.transactionFeeIncoming = 0;
        self.amountNet = self.amount;
    }
}
-(void)recalculateWithAmount:(NSNumber *)amount fee:(NSNumber *)fee {
    self.amount = amount;
    [self recalculateNetAmountWithFee:fee];
}
-(void)recalculateWithAmount:(NSNumber *)amount feePercent:(NSNumber*)fee {
    self.amount = amount;
    if ([self.direction isEqualToString:kAMCPaymentDirectionIn]) {
        [self recalculateNetAmountWithFeePercentage:fee];
    }
}
@end
