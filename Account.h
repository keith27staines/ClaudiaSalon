//
//  Account.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 25/01/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class AccountReconciliation, Payment, Sale, Salon,PaymentCategory;


@interface Account: NSManagedObject

NS_ASSUME_NONNULL_BEGIN
+(id)newObjectWithMoc:(NSManagedObjectContext*)moc;
+accountWithFriendlyName:(NSString*)friendlyName withMoc:(NSManagedObjectContext*)moc;
-(AccountReconciliation*)latestAccountReconcilliation;
-(AccountReconciliation*)lastAccountReconcilliationOnOrBeforeDate:(NSDate*)date;
-(BOOL)isReconciledToDate:(NSDate*)date;
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
-(Payment*)makePaymentWithAmount:(NSNumber*)amount
                            date:(NSDate*)date
                       direction:(NSString*)direction
                       payeeName:(NSString*)name
                          reason:(NSString*)reason;
NS_ASSUME_NONNULL_END
@end


#import "Account+CoreDataProperties.h"
