//
//  AMCStatementItemComputerRecordMismatchCalculator.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 23/04/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "AMCStatementItemComputerRecordMismatchCalculator.h"
#import "NSDate+AMCDate.h"
#import "AMCAccountStatementItem.h"
#import "Payment+Methods.h"
#import "Sale+Methods.h"

@implementation AMCStatementItemComputerRecordMismatchCalculator

-(instancetype)init {
    self = [super init];
    if (self) {
        self.amountWeight = 1;
        self.feeWeight = 0.001;
        self.netAmountWeight = 0.001;
        self.dateWeight = 1;
        self.signTolerant = YES;
        self.dayTolerance = 5;
        self.monthTolerance = 1;
        self.yearTolerance = 1;
    }
    return self;
}
-(double)mismatchFirstDate:(NSDate*)firstDate secondDate:(NSDate*)secondDate {
    double seconds = fabs([[secondDate beginningOfDay]  timeIntervalSinceDate:[firstDate beginningOfDay]]);
    double daysDifference = fabs(seconds / 3600.0 / 24.0);
    if (daysDifference == 0) {
        return 0;  // Exact same date
    }
    if (daysDifference < self.dayTolerance) {
        return 0.01; // Within a 'few' days
    }
    NSCalendar * gregorian = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents * firstComponents = [gregorian components:(NSCalendarUnitMonth | NSCalendarUnitYear | NSCalendarUnitDay) fromDate:firstDate];
        NSDateComponents * secondComponents = [gregorian components:(NSCalendarUnitMonth | NSCalendarUnitYear | NSCalendarUnitDay) fromDate:secondDate];

    if (firstComponents.year == secondComponents.year) {
        // Same year same day different month
        if (firstComponents.day == secondComponents.day) {
            return labs(firstComponents.month - secondComponents.month);
        }
    } else {
        // Different year
        NSInteger yearsDifference = labs(firstComponents.year - secondComponents.year);
        if ( yearsDifference < self.yearTolerance) {
            // Same month and day
            if (firstComponents.month == secondComponents.month && firstComponents.day
                == secondComponents.day) {
                return yearsDifference; // Common error, user set wrong year in date field
            }
        }
    }
    return daysDifference;
}
-(double)mismatchFirstAmount:(NSNumber*)firstAmount secondAmount:(NSNumber*)secondAmount {
    NSInteger first;
    NSInteger second;
    BOOL almost = NO;
    if (!firstAmount) {
        return 0; // first amount comes from statement item which might legitimately not have an "amount recorded (because amount can be fee, net, in addition to gross
    }
    // If the statement record contains firstAmount, then the computer record must too, otherwise there is a total mismatch
    double mismatch = MAXFLOAT; // Assume total mismatch
    if (firstAmount && secondAmount) {
        first = round(fabs(firstAmount.doubleValue)*100);   // work in pennies
        second = round(fabs(secondAmount.doubleValue)*100); // work in pennies
        mismatch = (first - second);
        if (mismatch == 0) {
            return 0;
        }
        if (self.signTolerant) {
            mismatch = labs(labs(first) - labs(second));
            if (mismatch == 0) {
                almost = YES;  // exact same amount but different sign
            }
        }
    }
    if (almost) {
        mismatch = 1;  // Anything matching within a pound is regarded as missing by just 1 penny
    }
    // Convert mismatch from penny to pound and return
    return mismatch/100.0;
}
-(double)mismatchBetweenTransactionDictionary:(NSDictionary*)transaction item:(AMCAccountStatementItem*)item {
    double totalWeight = 0;
    double mismatch = 0;

    if (self.amountWeight > 0) {
        mismatch += self.amountWeight * [self mismatchFirstAmount:transaction[@"amount"] secondAmount:@(item.signedAmountGross)];
        totalWeight += self.amountWeight;
    }
    if (self.feeWeight) {
        mismatch += self.feeWeight * [self mismatchFirstFee:transaction[@"fee"] secondFee:@(item.transactionFee)];
        totalWeight += self.feeWeight;
    }
    if (self.netAmountWeight) {
        mismatch += self.netAmountWeight * [self mismatchFirstNetAmount:transaction[@"amountNet"] secondNetAmount:@(item.signedAmountNet)];
        totalWeight += self.netAmountWeight;
    }
    if (self.dateWeight) {
        mismatch += self.dateWeight * [self mismatchFirstDate:transaction[@"date"] secondDate:item.date];
        totalWeight += self.dateWeight;
    }
    return mismatch / totalWeight;
}
-(double)mismatchFirstFee:(NSNumber*)firstFee secondFee:(NSNumber*)secondFee {
    return [self mismatchFirstAmount:firstFee secondAmount:secondFee];
}
-(double)mismatchFirstNetAmount:(NSNumber*)firstNet secondNetAmount:(NSNumber*)secondNet {
    return [self mismatchFirstAmount:firstNet secondAmount:secondNet];
}
@end
