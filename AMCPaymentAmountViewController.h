//
//  AMCPaymentAmountViewController.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 15/02/2015.
//  Copyright (c) 2015 Keith Staines. All rights reserved.
//

@class Account, Payment,PaymentCategory;

#import <Cocoa/Cocoa.h>
#import "AMCSalonDocument.h"
@interface AMCPaymentAmountViewController : AMCViewController
@property (readonly) Payment * payment;
-(void)makePaymentWithTitle:(NSString*)title
                     amount:(double)amount
       allowingLowerPayment:(BOOL)allowingLowerPayment
                 inCategory:(PaymentCategory*)category
                fromAccount:(Account*)account
                    toPayee:(NSString*)payee
                 withReason:(NSString*)reason;
@end
