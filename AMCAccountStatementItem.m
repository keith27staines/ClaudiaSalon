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
    id _financialTransaction;
    __weak Sale * _sale;
    __weak Payment * _payment;
}
@property (readwrite) id financialTransaction;
@property (weak) Sale * sale;
@property (weak) Payment * payment;
@end

@implementation AMCAccountStatementItem

-(instancetype)initWithFinancialTransaction:(id)object {
    self = [super init];
    if ([object isKindOfClass:[Sale class]]) {
        self.financialTransaction = object;
        return self;
    }
    if ([object isKindOfClass:[Payment class]]) {
        self.financialTransaction = object;
    }
    return self;
}
-(instancetype)initWithPayment:(Payment *)payment {
    return [self initWithFinancialTransaction:payment];
}

-(instancetype)initWithSale:(Sale *)sale {
    return [self initWithFinancialTransaction:sale];
}
-(id)financialTransaction {
    return _financialTransaction;
}
-(void)setFinancialTransaction:(id)financialTransaction {
    _financialTransaction = financialTransaction;
    if ([financialTransaction isKindOfClass:[Payment class]]) {
        self.payment = (Payment*)financialTransaction;
    }
    if ([financialTransaction isKindOfClass:[Sale class]]) {
        self.sale = (Sale*)financialTransaction;
    }
    if (!financialTransaction) {
        self.sale = nil;
        self.payment = nil;
    }
}
-(Payment *)payment {
    return _payment;
}
-(void)setPayment:(Payment *)payment {
    _payment = payment;
    if (payment) {
        self.sale = nil;
    }
}
-(Sale *)sale {
    return _sale;
}
-(void)setSale:(Sale *)sale {
    _sale = sale;
    if (sale) {
        self.payment = nil;
    }
}
-(NSDate *)date {
    if (self.payment) {
        if (self.payment.bankStatementTransactionDate) {
            return self.payment.bankStatementTransactionDate;
        } else {
            return self.payment.createdDate;
        }
    }
    if (self.sale) {
        return self.sale.createdDate;
    }
    return nil;
}
-(double)amountGross {
    if (self.payment) {
        if ([self.payment.direction isEqualToString:kAMCPaymentDirectionIn]) {
            return self.payment.amount.doubleValue;
        } else {
            return -self.payment.amount.doubleValue;
        }
    }
    if (self.sale) {
        return self.sale.actualCharge.doubleValue;
    }
    return 0;
}
-(double)transactionFee {
    return fabs(fabs([self amountGross]) - fabs([self amountNet]));
}
-(double)amountNet {
    if (self.payment) {
        if ([self.payment.direction isEqualToString:kAMCPaymentDirectionIn]) {
            if ([self.payment.account.friendlyName isEqualToString:@"PayPal"]) {
                return [self amountAfterFeeFrom:self.payment.amount.doubleValue withFeePercentage:2.75];
            } else {
                return self.payment.amount.doubleValue;
            }
        } else {
            return -self.payment.amount.doubleValue;
        }
    }
    if (self.sale) {
        if ([self.sale.account.friendlyName isEqualToString:@"PayPal"]) {
            return [self amountAfterFeeFrom:self.sale.actualCharge.doubleValue withFeePercentage:2.75];
        } else {
            return self.sale.actualCharge.doubleValue;
        }
    }
    return 0;
}
-(double)amountAfterFeeFrom:(double)amount withFeePercentage:(double)feePercent {
    double fee = round(amount *100 * feePercent/100.0);
    double after = amount * 100  - fee;
    return round(after)/100.0;
}
-(NSString *)payeeName {
    if (self.payment) {
        return self.payment.payeeName;
    }
    if (self.sale) {
        return @"Customer";
    }
    return @"";
}
-(NSString *)categoryName {
    if (self.payment) {
        return self.payment.paymentCategory.categoryName;
    }
    if (self.sale) {
        return @"Sale";
    }
    return @"";
}
-(NSString *)note {
    if (self.payment) {
        return self.payment.reason;
    }
    if (self.sale) {
        return @"";
    }
    return @"";
}
-(BOOL)isReconciled {
    if (self.payment) {
        return self.payment.reconciledWithBankStatement.boolValue;
    }
    if (self.sale) {
        return NO;
    }
    return NO;
}
-(NSString *)direction {
    if (self.payment) {
        // Payments can be incoming or outgoing
        return self.payment.direction;
    } else {
        // Sales are always "IN"
        return kAMCPaymentDirectionIn;
    }
}
-(BOOL)isPayment {
    return (self.payment != nil);
}
-(void)voidTransaction {
    if (self.payment) {
        self.payment.voided = @(YES);
    }
    if (self.sale) {
        self.sale.voided = @(YES);
    }
}
-(BOOL)paired {
    return (self.pairingRecord)?YES:NO;
}
@end
