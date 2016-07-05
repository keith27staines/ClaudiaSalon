//
//  Payment.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 25/01/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "AMCObjectWithNotesProtocol.h"

@class Account, Note, PaymentCategory, RecurringItem, Sale, SaleItem, ShoppingList, WorkRecord;

NS_ASSUME_NONNULL_BEGIN

@interface Payment: NSManagedObject <AMCObjectWithNotesProtocol>
+(NSManagedObject*)createObjectInMoc:(NSManagedObjectContext*)moc;
+(NSArray*)allObjectsWithMoc:(NSManagedObjectContext*)moc;
+(NSArray*)paymentsBetweenStartDate:(NSDate*)startDate endDate:(NSDate*)endDate withMoc:(NSManagedObjectContext*)moc;
+(NSArray*)nonSalepaymentsBetweenStartDate:(NSDate*)startDate endDate:(NSDate*)endDate withMoc:(NSManagedObjectContext*)moc;
-(NSString*)refundYNString;
-(NSNumber*)calculateFeeForAmount:(NSNumber*)amount withFeePercentage:(NSNumber*)feePercent;
-(void)recalculateFromCurrentAmount;
-(void)recalculateNetAmountWithFee:(NSNumber *)fee;
-(void)recalculateNetAmountWithFeePercentage:(NSNumber*)feePercent;
@property (readonly) BOOL isReconciled;
@property (readonly) BOOL isIncoming;
@property (readonly) BOOL isOutgoing;
@property (readonly) NSNumber * signedAmount;
@property (readonly) NSNumber * signedAmountNet;
@end

NS_ASSUME_NONNULL_END

#import "Payment+CoreDataProperties.h"
