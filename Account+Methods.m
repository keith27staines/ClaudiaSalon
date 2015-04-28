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
-(AccountReconciliation*)lastAccountReconcilliationBeforeDate:(NSDate*)date {
    NSArray * array = [self.reconciliations allObjects];
    NSSortDescriptor * sort = [NSSortDescriptor sortDescriptorWithKey:@"reconciliationDate" ascending:YES];
    array = [array sortedArrayUsingDescriptors:@[sort]];
    AccountReconciliation * returnValue = nil;
    if (array && array.count >= 1) {
        for (AccountReconciliation * rec in array) {
            if ([rec.reconciliationDate isLessThan:date]) {
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
-(double)expectedBalanceFromReconciliation:(AccountReconciliation*)reconciliation toDate:(NSDate*)date {
    NSDate * fromDate = reconciliation.reconciliationDate;
    if (!fromDate) fromDate = [NSDate distantPast];
    double balance = reconciliation.actualBalance.doubleValue;
    for (Payment * payment in self.payments) {
        
        if ([payment.paymentDate isLessThan:fromDate]) continue;
        if ([payment.paymentDate isGreaterThan:date]) continue;
        if (payment.voided.boolValue == YES ) continue;
        
        if ([payment.direction isEqualToString:kAMCPaymentDirectionOut]) {
            balance -= payment.amount.doubleValue;
        } else {
            balance += payment.amountNet.doubleValue;
        }
    }
    return balance;
}
-(double)expectedBalanceFromReconciliation:(AccountReconciliation*)reconciliation {
    NSDate * fromDate = reconciliation.reconciliationDate;
    if (!fromDate) fromDate = [NSDate distantPast];
    double balance = reconciliation.actualBalance.doubleValue;
    for (Payment * payment in self.payments) {
        
        if ([payment.paymentDate isLessThan:fromDate]) continue;
        if (payment.voided.boolValue == YES ) continue;
        
        if ([payment.direction isEqualToString:kAMCPaymentDirectionOut]) {
            balance -= payment.amount.doubleValue;
        } else {
            balance += payment.amount.doubleValue;
        }
    }
    return balance;
}

@end
