//
//  AMCDiscountCalculator.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 04/08/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AMCConstants.h"

typedef NS_ENUM(NSInteger, AMCDiscountType) {
    AMCDiscountTypeNone = 0,
    AMCDiscountTypePercentage = 1,
    AMCDiscountTypeAbsoluteAmount = 2,
};

@interface AMCDiscountCalculator : NSObject
+(double)calculateDiscountWithDiscountType:(AMCDiscountType)discountType discountValue:(double)value onPrice:(double)amount;
+(double)calculateDiscountedPriceWithDiscountType:(AMCDiscountType)discountType discountValue:(double)value undiscountedPrice:(double)amount;

+(NSString*)discountDescriptionforDiscountType:(AMCDiscountType)discountType discountValue:(long)value;
+(double)roundVeryCloseOrUp:(double)amount;
+(double)roundVeryCloseOrDown:(double)amount;
+(AMCDiscountType)discountTypeForVersion1Discount:(AMCDiscount)discount;
+(long)discountValueForVersion1Discount:(AMCDiscount)discount;
@end
