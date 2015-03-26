//
//  AccountReconciliation+Methods.m
//  ClaudiasSalon
//
//  Created by service on 16/09/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "AccountReconciliation+Methods.h"
#import "NSDate+AMCDate.h"

@implementation AccountReconciliation (Methods)
+(id)newObjectWithMoc:(NSManagedObjectContext*)moc
{
    AccountReconciliation * reconciliation = [NSEntityDescription insertNewObjectForEntityForName:@"AccountReconciliation" inManagedObjectContext:moc];
    reconciliation.reconciliationDate = [NSDate date];
    reconciliation.account = nil;
    reconciliation.actualBalance = @(0.0);
    return reconciliation;
}
-(void)awakeFromInsert {
    self.reconciliationDate = [[NSDate date] beginningOfDay];
}
@end
