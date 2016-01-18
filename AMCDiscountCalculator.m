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

+(double)calculateDiscountWithDiscountType:(AMCDiscount)discountType onPrice:(double)amount
{
    // Deprecated!!!
    double discount;
    switch (discountType) {
        case AMCDiscountNone:
            discount = 0;
            break;
        case AMCDiscount5pc:
            discount = 0.05 * amount;
            break;
        case AMCDiscount10pc:
            discount = 0.1 * amount;
            break;
        case AMCDiscount20pc:
            discount = 0.2 * amount;
            break;
        case AMCDiscount30pc:
            discount = 0.3 * amount;
            break;
        case AMCDiscount40pc:
            discount = 0.4 * amount;
            break;
        case AMCDiscount50pc:
            discount = 0.5 * amount;
            break;
        case AMCDiscount100pc:
            discount = amount;
            break;
        case AMCDiscount1Pound:
            discount = 1;
            break;
        case AMCDiscount2Pound:
            discount = 2;
            break;
        case AMCDiscount5Pound:
            discount = 5;
            break;
        case AMCDiscount10Pound:
            discount = 10;
            break;
        case AMCDiscount20Pound:
            discount = 20;
            break;
        case AMCDiscount50Pound:
            discount = 50;
            break;
    }
    return [self roundVeryCloseOrUp:discount];
}
+(double)calculateDiscountedPriceWithDiscountType:(AMCDiscount)discountType undiscountedPrice:(double)amount {
    // Deprecated!!!
    double discount = [self calculateDiscountWithDiscountType:discountType onPrice:amount];
    return [self roundVeryCloseOrDown:(amount - discount)];
}

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
    if (discount > value) {
        discount = value;
    }
    return [self roundVeryCloseOrUp:discount];
}
+(double)calculateDiscountedPriceWithDiscountType:(AMCDiscountType)discountType discountValue:(double)value undiscountedPrice:(double)amount {
    double discount = [self calculateDiscountWithDiscountType:discountType discountValue:value onPrice:amount];
    return [self roundVeryCloseOrDown:(amount - discount)];
}

+(NSString*)discountDescriptionforDiscount:(AMCDiscount)discountType
{
    switch (discountType) {
        case AMCDiscountNone:
            return @"No discount";
            break;
        case AMCDiscount5pc:
            return @"5%";
            break;
        case AMCDiscount10pc:
            return @"10%";
            break;
        case AMCDiscount20pc:
            return @"20%";
            break;
        case AMCDiscount30pc:
            return @"30%";
            break;
        case AMCDiscount40pc:
            return @"40%";
            break;
        case AMCDiscount50pc:
            return @"50%";
            break;
        case AMCDiscount100pc:
            return @"100%";
            break;
        case AMCDiscount1Pound:
            return @"£1";
            break;
        case AMCDiscount2Pound:
            return @"£2";
            break;
        case AMCDiscount5Pound:
            return @"£5";
            break;
        case AMCDiscount10Pound:
            return @"£10";
            break;
        case AMCDiscount20Pound:
            return @"£20";
            break;
        case AMCDiscount50Pound:
            return @"£50";
            break;
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
