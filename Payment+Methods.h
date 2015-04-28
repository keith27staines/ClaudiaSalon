//
//  Payment+Methods.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 23/07/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "Payment.h"
#import "AMCSalonDocument.h"
#import "AMCObjectWithNotesProtocol.h"

@interface Payment (Methods) <AMCObjectWithNotesProtocol>
+(id)newObjectWithMoc:(NSManagedObjectContext*)moc;
+(NSArray*)allObjectsWithMoc:(NSManagedObjectContext*)moc;
+(NSArray*)paymentsBetweenStartDate:(NSDate*)startDate endDate:(NSDate*)endDate withMoc:(NSManagedObjectContext*)moc;
+(NSArray*)nonSalepaymentsBetweenStartDate:(NSDate*)startDate endDate:(NSDate*)endDate withMoc:(NSManagedObjectContext*)moc;
-(NSString*)refundYNString;
-(NSNumber*)calculateFeeForAmount:(NSNumber*)amount withFeePercentage:(NSNumber*)feePercent;
-(void)recalculateNetAmountWithFee:(NSNumber *)fee;
-(void)recalculateNetAmountWithFeePercentage:(NSNumber*)feePercent;
@end
