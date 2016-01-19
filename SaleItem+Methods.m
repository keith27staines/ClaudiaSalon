//
//  SaleItem+Methods.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 19/07/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "SaleItem+Methods.h"
#import "AMCDiscountCalculator.h"
#import "AMCConstants.h"

@implementation SaleItem (Methods)
+(id)newObjectWithMoc:(NSManagedObjectContext*)moc
{
    SaleItem * saleItem = [NSEntityDescription insertNewObjectForEntityForName:@"SaleItem" inManagedObjectContext:moc];
    NSDate * rightNow = [NSDate date];
    saleItem.createdDate = rightNow;
    saleItem.lastUpdatedDate = rightNow;
    return saleItem;
}
+(NSArray*)allObjectsWithMoc:(NSManagedObjectContext*)moc {
    NSArray * array = nil;
    NSFetchRequest * fetch = [NSFetchRequest fetchRequestWithEntityName:@"SaleItem"];
    array = [moc executeFetchRequest:fetch error:nil];
    return array;
}
-(NSSet*)nonAuditNotes {
    NSMutableSet * nonAuditNotes = [NSMutableSet set];
    for (Note * note in self.notes) {
        if (!note.isAuditNote.boolValue) {
            [nonAuditNotes addObject:note];
        }
    }
    return nonAuditNotes;
}
-(void)updatePrice {
    switch (self.discountVersion.integerValue) {
        case 0:
        case 1:
        {
            AMCDiscount discountType = self.discountType.integerValue;
            double nominalPrice = self.nominalCharge.doubleValue;
            double actualPrice = [AMCDiscountCalculator calculateDiscountedPriceWithDiscountType:discountType undiscountedPrice:nominalPrice];
            self.actualCharge = @(actualPrice);
            break;
        }
        case 2:
        {
            AMCDiscountType discountType = self.discountType.integerValue;
            long discountValue = self.discountValue.integerValue;
            double nominalPrice = self.nominalCharge.doubleValue;
            double actualPrice = [AMCDiscountCalculator calculateDiscountedPriceWithDiscountType:discountType discountValue:discountValue undiscountedPrice:nominalPrice];
            self.actualCharge = @(actualPrice);
            break;
        }
        default:
            NSAssert(NO, @"Don't know how to updatePrice for discount version %@",self.discountVersion);
            break;
    }
}
-(double)discountAmount {
    switch (self.discountVersion.integerValue) {
        case 0:
        case 1:
        {
            return [AMCDiscountCalculator calculateDiscountWithDiscountType:self.discountType.integerValue onPrice:self.nominalCharge.doubleValue];
            break;
        }
        case 2:
        {
            return [AMCDiscountCalculator calculateDiscountWithDiscountType:self.discountType.integerValue discountValue:self.discountValue.doubleValue onPrice:self.nominalCharge.doubleValue];
            break;
        }
        default:
            NSAssert(NO,@"Don't know how to calculate discountAmount for discount version %@", self.discountVersion);
            return 0;
            break;
    }
}
-(void)convertToDiscountVersion2 {
    if (self.discountVersion.integerValue < 1) {
        NSLog(@"Don't know how to convert this discount type");
    }
    if (self.discountVersion.integerValue >= 2) { return; }
    AMCDiscountType discountType = [AMCDiscountCalculator discountTypeForVersion1Discount:self.discountType.integerValue];
    double discountValue = [AMCDiscountCalculator discountValueForVersion1Discount:self.discountType.integerValue];
    self.discountType = @(discountType);
    self.discountValue = @(discountValue);
    self.discountVersion = @2;
}

@end
