//
//  AMCDiscountCalculator.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 04/08/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AMCSalonDocument.h"

typedef NS_ENUM(NSInteger, AMCDiscountType) {
    AMCDiscountTypeNone = 0,
    AMCDiscountTypePercentage = 1,
    AMCDiscountTypeAbsoluteAmount = 2,
};

@interface AMCDiscountCalculator : NSObject
+(double)calculateDiscountedPriceWithDiscountType:(AMCDiscount)discountType undiscountedPrice:(double)amount;
+(double)calculateDiscountWithDiscountType:(AMCDiscount)discountType onPrice:(double)amount;
+(double)calculateDiscountWithDiscountType:(AMCDiscountType)discountType discountValue:(double)value onPrice:(double)amount;
+(double)calculateDiscountedPriceWithDiscountType:(AMCDiscountType)discountType discountValue:(double)value undiscountedPrice:(double)amount;

+(NSString*)discountDescriptionforDiscount:(AMCDiscount)discountType;
+(double)roundVeryCloseOrUp:(double)amount;
+(double)roundVeryCloseOrDown:(double)amount;
+(AMCDiscountType)discountTypeForVersion1Discount:(AMCDiscount)discount;
+(long)discountValueForVersion1Discount:(AMCDiscount)discount;
@end
