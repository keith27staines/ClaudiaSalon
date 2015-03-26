//
//  Account+Methods.h
//  ClaudiasSalon
//
//  Created by service on 16/09/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//
@class AccountReconciliation;

#import "AMCSalonDocument.h"
#import "Account.h"

@interface Account (Methods)
+(id)newObjectWithMoc:(NSManagedObjectContext*)moc;
+accountWithFriendlyName:(NSString*)friendlyName withMoc:(NSManagedObjectContext*)moc;
-(AccountReconciliation*)latestAccountReconcilliation;
-(AccountReconciliation*)lastAccountReconcilliationBeforeDate:(NSDate*)date;
-(double)expectedBalanceFromReconciliation:(AccountReconciliation*)reconciliation;
-(double)expectedBalanceFromReconciliation:(AccountReconciliation*)reconciliation toDate:(NSDate*)date;
+(NSArray*)allObjectsWithMoc:(NSManagedObjectContext*)moc;
@end
