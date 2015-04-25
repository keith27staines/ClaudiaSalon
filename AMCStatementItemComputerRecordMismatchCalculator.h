//
//  AMCStatementItemComputerRecordMismatchCalculator.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 23/04/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//
@class AMCAccountStatementItem;
#import <Foundation/Foundation.h>

@interface AMCStatementItemComputerRecordMismatchCalculator : NSObject
-(double)mismatchFirstDate:(NSDate*)firstDate secondDate:(NSDate*)secondDate;

-(double)mismatchFirstAmount:(NSNumber*)firstAmount secondAmount:(NSNumber*)secondAmount;

-(double)mismatchFirstFee:(NSNumber*)firstFee secondFee:(NSNumber*)secondFee;
-(double)mismatchFirstNetAmount:(NSNumber*)firstNet secondNetAmount:(NSNumber*)secondNet;
-(double)mismatchBetweenTransactionDictionary:(NSDictionary*)transaction item:(AMCAccountStatementItem*)item;
@property double amountWeight;
@property double feeWeight;
@property double netAmountWeight;
@property double dateWeight;
@property BOOL signTolerant;
@property BOOL fractionTolerant;
@property NSInteger monthTolerance;
@property NSInteger yearTolerance;
@property NSInteger dayTolerance;
@end
