//
//  AMCAccountStatementItem.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 05/03/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "AMCAccountStatementItem.h"
#import "Sale+Methods.h"
#import "Payment+Methods.h"
#import "Customer+Methods.h"
#import "Employee+Methods.h"
#import "PaymentCategory+Methods.h"
#import "Account+Methods.h"

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
    if (self.payment) {
        if (self.payment.paymentDate) {
            return self.payment.paymentDate;
        } else {
            return self.payment.createdDate;
        }
    }
    return nil;
}
-(double)amountGross {
    if (self.payment) {
        if (self.payment.isIncoming) {
            return self.payment.amount.doubleValue;
        } else {
            return -self.payment.amount.doubleValue;
        }
    }
    return 0;
}
-(double)signedAmountGross {
    if (self.payment) {
        if (self.payment.isIncoming) {
            return fabs(self.amountGross);
        } else {
            return -fabs(self.amountGross);
        }
    }
    return 0;
}
-(double)signedAmountNet {
    if (self.payment) {
        if (self.payment.isIncoming) {
            return fabs(self.amountNet);
        } else {
            return -fabs(self.amountNet);
        }
    }
    return 0;
}
-(double)amountNet {
    if (self.payment) {
        if (self.payment.isIncoming) {
            return self.payment.amountNet.doubleValue;
        } else {
            return -self.payment.amount.doubleValue;
        }
    }
    return 0;
}
-(double)transactionFee {
    if ([self.direction isEqualToString:kAMCPaymentDirectionIn]) {
        return self.payment.transactionFee.doubleValue;
    }
    return 0;
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
    if (self.payment) {
        return self.payment.paymentCategory.categoryName;
    }

    return @"";
}
-(NSString *)note {
    if (self.payment) {
        return self.payment.reason;
    }
    return @"";
}
-(BOOL)isReconciled {
    if (self.payment) {
        return self.payment.reconciledWithBankStatement.boolValue;
    }
    return NO;
}
-(NSString *)direction {
    if (self.payment) {
        return self.payment.direction;
    }
    return nil;
}
-(BOOL)isPayment {
    return (self.payment.sale == nil);
}
-(void)voidTransaction {
    if (self.payment) {
        self.payment.voided = @(YES);
        if (self.payment.sale) {
            self.payment.sale.voided = @(YES);
        }
    }
}
-(BOOL)paired {
    return (self.pairingRecord)?YES:NO;
}
@end
