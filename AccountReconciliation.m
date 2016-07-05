//
//  AccountReconciliation.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 25/01/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

#import "AccountReconciliation.h"
#import "Account.h"
#import "NSDate+AMCDate.h"

@implementation AccountReconciliation

// Insert code here to add functionality to your managed object subclass
+(NSManagedObject*)createObjectInMoc:(NSManagedObjectContext*)moc
{
    AccountReconciliation * reconciliation = [NSEntityDescription insertNewObjectForEntityForName:@"AccountReconciliation" inManagedObjectContext:moc];
    reconciliation.reconciliationDate = [NSDate date];
    reconciliation.account = nil;
    reconciliation.actualBalance = @(0.0);
    return (AccountReconciliation*)reconciliation;
}

+(NSArray*)allObjectsWithMoc:(NSManagedObjectContext*)moc  {
    NSArray * array = nil;
    NSFetchRequest * fetch = [NSFetchRequest fetchRequestWithEntityName:@"AccountReconciliation"];
    array = [moc executeFetchRequest:fetch error:nil];
    return array;
}

-(void)awakeFromInsert {
    self.reconciliationDate = [[NSDate date] beginningOfDay];
}
@end
