//
//  AMCAccountStatementItem.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 05/03/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "AMCAccountStatementItem.h"
#import "Sale.h"
#import "Payment.h"
#import "Customer.h"
#import "Employee.h"
#import "PaymentCategory.h"
#import "Account.h"

@interface AMCAccountStatementItem()
{
    __weak Payment * _payment;
}
@end

@implementation AMCAccountStatementItem

-(instancetype)initWithPayment:(Payment *)payment {
    self = [super init];
    if (self) {
        _payment = payment;
    }
    return self;
}
-(Payment *)payment {
    return _payment;
}
-(NSDate *)date {
    return self.payment.paymentDate;
}
-(double)amountGross {
    return self.payment.amount.doubleValue;
}
-(double)signedAmountGross {
    return self.payment.signedAmount.doubleValue;
}
-(double)signedAmountNet {
    return self.payment.signedAmountNet.doubleValue;
}
-(double)amountNet {
    return self.payment.amountNet.doubleValue;
}
-(double)transactionFee {
    return self.payment.transactionFee.doubleValue;
}
-(NSString *)payeeName {
    if (self.payment.payeeName) {
        return self.payment.payeeName;
    } else {
        if (self.payment.sale) {
            return @"Customer";
        }
    }
    return @"";
}
-(NSString *)categoryName {
    return self.payment.paymentCategory.categoryName;
}
-(NSString *)note {
    return self.payment.reason;
}
-(NSString *)direction {
    return self.payment.direction;
}
-(BOOL)isPayment {
    return (self.payment.sale == nil);
}
-(void)voidTransaction {
    self.payment.voided = @(YES);
}
-(BOOL)paired {
    return (self.pairingRecord)?YES:NO;
}
@end
