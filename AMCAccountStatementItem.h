//
//  AMCAccountStatementItem.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 05/03/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//
@class Sale, Payment;
#import <Foundation/Foundation.h>

@interface AMCAccountStatementItem : NSObject

-(instancetype)initWithPayment:(Payment*)payment;
@property (weak,readonly) Payment * payment;
@property (copy,readonly) NSDate * date;
@property (readonly) double signedAmountGross;
@property (readonly) double amountGross;
@property (readonly) double signedAmountNet;
@property (readonly) double amountNet;
@property (readonly) double transactionFee;
@property double balance;
@property (copy,readonly) NSString * payeeName;
@property (copy,readonly) NSString * categoryName;
@property (copy,readonly) NSString * note;
@property (readonly) BOOL isReconciled;
@property (copy,readonly) NSString * direction;
@property (readonly) BOOL isPayment;
@property NSDictionary * pairingRecord;
@property (readonly) BOOL paired;
-(void)voidTransaction;
@end
