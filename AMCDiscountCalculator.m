//
//  AMCDiscountCalculator.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 04/08/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "AMCDiscountCalculator.h"

static const double AMCSmallFractionOfPenny = 0.0001;

@implementation AMCDiscountCalculator

+(double)calculateDiscountWithDiscountType:(AMCDiscountType)discountType discountValue:(double)value onPrice:(double)amount {
    double discount = 0;
    switch (discountType) {
        case AMCDiscountTypeNone:
            discount = 0;
            break;
        case AMCDiscountTypePercentage:
        {
            discount = value /100.0 * amount;
            break;
        }
        case AMCDiscountTypeAbsoluteAmount:
        {
            discount = value;
            break;
        }
    }
    if (discount > amount) {
        discount = amount;
    }
    return [self roundVeryCloseOrUp:discount];
}
+(double)calculateDiscountedPriceWithDiscountType:(AMCDiscountType)discountType discountValue:(double)value undiscountedPrice:(double)amount {
    double discount = [self calculateDiscountWithDiscountType:discountType discountValue:value onPrice:amount];
    return [self roundVeryCloseOrDown:(amount - discount)];
}

+(NSString*)discountDescriptionforDiscountType:(AMCDiscountType)discountType discountValue:(long)value
{
    NSString * percentSymbol = @"%";
    NSString * currencySymbol = @"£";
    if (discountType == AMCDiscountTypePercentage) {
        // Percent
        return [NSString stringWithFormat:@"%@ %@",@(value),percentSymbol];
    } else {
        // Absolute amount
        return [NSString stringWithFormat:@"%@ %@",currencySymbol,@(value)];
    }
}
+(double)roundVeryCloseOrUp:(double)amount {
    amount = amount * 100;
    int intAmount = round(amount);
    if (fabs(amount-intAmount) < AMCSmallFractionOfPenny) {
        amount = intAmount;
    } else {
        amount = ceil(amount);
    }
    return amount/100.0;
}
+(double)roundVeryCloseOrDown:(double)amount {
    amount = amount * 100;
    int intAmount = round(amount);
    if (fabs(amount-intAmount) < AMCSmallFractionOfPenny) {
        amount = intAmount;
    } else {
        amount = floor(amount);
    }
    return amount/100.0;
}
+(AMCDiscountType)discountTypeForVersion1Discount:(AMCDiscount)discount {
    switch (discount) {
        case AMCDiscountNone:
            return AMCDiscountTypeNone;
        case AMCDiscount5pc:
        case AMCDiscount10pc:
        case AMCDiscount20pc:
        case AMCDiscount30pc:
        case AMCDiscount40pc:
        case AMCDiscount50pc:
        case AMCDiscount100pc:
            return AMCDiscountTypePercentage;
        case AMCDiscount1Pound:
        case AMCDiscount2Pound:
        case AMCDiscount5Pound:
        case AMCDiscount10Pound:
        case AMCDiscount20Pound:
        case AMCDiscount50Pound:
            return AMCDiscountTypeAbsoluteAmount;
    }
}
+(long)discountValueForVersion1Discount:(AMCDiscount)discount {
    switch (discount) {
        case AMCDiscountNone:
            return 0;
        case AMCDiscount1Pound:
            return 1;
        case AMCDiscount2Pound:
            return 2;
        case AMCDiscount5Pound:
            return 5;
        case AMCDiscount10Pound:
            return 10;
        case AMCDiscount20Pound:
            return 20;
        case AMCDiscount50Pound:
            return 50;
        case AMCDiscount5pc:
            return 5;
        case AMCDiscount10pc:
            return 10;
        case AMCDiscount20pc:
            return 20;
        case AMCDiscount30pc:
            return 30;
        case AMCDiscount40pc:
            return 40;
        case AMCDiscount50pc:
            return 50;
        case AMCDiscount100pc:
            return 100;
    }
}
@end
