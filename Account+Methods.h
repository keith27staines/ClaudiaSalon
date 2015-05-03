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
-(AccountReconciliation*)lastAccountReconcilliationOnOrBeforeDate:(NSDate*)date;
-(NSNumber*)expectedBalanceFromReconciliation:(AccountReconciliation*)reconciliation;
-(NSNumber*)expectedBalanceFromReconciliation:(AccountReconciliation*)reconciliation toDate:(NSDate*)date;
-(NSArray*)paymentsBetween:(NSDate*)startDate endDate:(NSDate*)endDate;
-(NSArray*)paymentsAfter:(NSDate*)date;
-(NSArray*)paymentsBefore:(NSDate*)date;
-(NSNumber*)amountBroughtForward:(NSDate*)date;
+(NSArray*)allObjectsWithMoc:(NSManagedObjectContext*)moc;
-(Payment*)makePaymentWithAmount:(NSNumber*)amount
                            date:(NSDate*)date
                        category:(PaymentCategory*)category
                       direction:(NSString*)direction
                       payeeName:(NSString*)name
                          reason:(NSString*)reason;
@end
