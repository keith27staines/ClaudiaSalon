//
//  Account+Methods.m
//  ClaudiasSalon
//
//  Created by service on 16/09/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "Account+Methods.h"
#import "AMCConstants.h"
#import "AccountReconciliation+Methods.h"
#import "Payment+Methods.h"
#import "Sale+Methods.h"

@implementation Account (Methods)

+(id)newObjectWithMoc:(NSManagedObjectContext*)moc {
    Account * account = [NSEntityDescription insertNewObjectForEntityForName:@"Account" inManagedObjectContext:moc];
    account.friendlyName = @"friendly name";
    account.sortCode = @"";
    account.accountNumber = @"";
    account.bankName = @"";
    return account;
}
+accountWithFriendlyName:(NSString*)friendlyName withMoc:(NSManagedObjectContext*)moc {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Account" inManagedObjectContext:moc];
    [fetchRequest setEntity:entity];
    // Specify criteria for filtering which objects to fetch
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"friendlyName == %@", friendlyName];
    [fetchRequest setPredicate:predicate];
    NSError *error = nil;
    NSArray *fetchedObjects = [moc executeFetchRequest:fetchRequest error:&error];
    return [fetchedObjects firstObject];
}
+(NSArray*)allObjectsWithMoc:(NSManagedObjectContext*)moc {
    NSArray * array = nil;
    NSFetchRequest * fetch = [NSFetchRequest fetchRequestWithEntityName:@"Account"];
    NSSortDescriptor * sort = [NSSortDescriptor sortDescriptorWithKey:@"friendlyName" ascending:YES];
    fetch.sortDescriptors = @[sort];
    array = [moc executeFetchRequest:fetch error:nil];
    return array;
}
-(AccountReconciliation*)lastAccountReconcilliationOnOrBeforeDate:(NSDate*)date {
    NSArray * array = [self.reconciliations allObjects];
    NSSortDescriptor * sort = [NSSortDescriptor sortDescriptorWithKey:@"reconciliationDate" ascending:YES];
    array = [array sortedArrayUsingDescriptors:@[sort]];
    AccountReconciliation * returnValue = nil;
    if (array && array.count >= 1) {
        for (AccountReconciliation * rec in array) {
            if ([rec.reconciliationDate isLessThanOrEqualTo:date]) {
                returnValue = rec;
            }
        }
    }
    return returnValue;
}
-(AccountReconciliation*)latestAccountReconcilliation {
    NSArray * array = [self.reconciliations allObjects];
    NSSortDescriptor * sort = [NSSortDescriptor sortDescriptorWithKey:@"reconciliationDate" ascending:NO];
    array = [array sortedArrayUsingDescriptors:@[sort]];
    if (array && array.count >= 1) {
        return array[0];
    }
    return nil;
}
-(NSNumber*)expectedBalanceFromReconciliation:(AccountReconciliation *)reconciliation {
    return [self expectedBalanceFromReconciliation:reconciliation toDate:[NSDate date]];
}
-(NSNumber*)amountBroughtForward:(NSDate*)date {
    AccountReconciliation * reconciliation = [self lastAccountReconcilliationOnOrBeforeDate:date];
    return [self expectedBalanceFromReconciliation:reconciliation toDate:date];
}
-(NSNumber*)expectedBalanceFromReconciliation:(AccountReconciliation*)reconciliation toDate:(NSDate*)toDate {
    NSDate * fromDate = nil;
    double balanceBroughtForward = 0.0;
    if (reconciliation) {
        fromDate = reconciliation.reconciliationDate;
        balanceBroughtForward = reconciliation.actualBalance.doubleValue;
    } else {
        fromDate = [NSDate distantPast];
        balanceBroughtForward = 0.0;
    }
    double summedPayments = [self sumPayments:[self paymentsBetween:fromDate endDate:toDate]];
    return @([self addAmount:balanceBroughtForward to:summedPayments]);
}
-(double)addAmount:(double)amount to:(double)otherAmount {
    return (round(amount * 100.0) + round(otherAmount * 100.0))/100.0;
}
-(double)sumPayments:(NSArray*)payments {
    double sum = 0.0;
    for (Payment * payment in payments) {
        double amount = 0;
        if ([payment.direction isEqualToString:kAMCPaymentDirectionOut]) {
            amount = -payment.amount.doubleValue;
        } else {
            amount = payment.amountNet.doubleValue;
        }
        sum = [self addAmount:sum to:amount];
    }
    return sum;
}
-(NSArray*)paymentsAfter:(NSDate*)date {
    return [self paymentsBetween:date endDate:[NSDate distantFuture]];
}
-(NSArray*)paymentsBefore:(NSDate*)date {
    return [self paymentsBetween:[NSDate distantPast] endDate:date];
}
-(NSArray*)paymentsBetween:(NSDate*)startDate endDate:(NSDate*)endDate {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Payment" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    // Specify criteria for filtering which objects to fetch
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"account = %@ and paymentDate >= %@ and paymentDate <= %@ and voided = %@", self,startDate,endDate,@NO];
    [fetchRequest setPredicate:predicate];
    // Specify how the fetched objects should be sorted
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"paymentDate"
                                                                   ascending:YES];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];
    
    NSError *error = nil;
    NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (fetchedObjects == nil) {
        
    }
    return fetchedObjects;
}
@end
