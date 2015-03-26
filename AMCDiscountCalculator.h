//
//  AMCDiscountCalculator.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 04/08/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AMCSalonDocument.h"

@interface AMCDiscountCalculator : NSObject
+(double)calculateDiscountedPriceWithDiscountType:(AMCDiscount)discountType undiscountedPrice:(double)amount;

+(NSString*)discountDescriptionforDiscount:(AMCDiscount)discountType;
+(double)calculateDiscountWithDiscountType:(AMCDiscount)discountType onPrice:(double)amount;
+(double)roundVeryCloseOrUp:(double)amount;
+(double)roundVeryCloseOrDown:(double)amount;
@end
