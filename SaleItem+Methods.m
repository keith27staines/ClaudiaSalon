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
    AMCDiscount discountType = self.discountType.integerValue;
    double nominalPrice = self.nominalCharge.doubleValue;
    double actualPrice = [AMCDiscountCalculator calculateDiscountedPriceWithDiscountType:discountType undiscountedPrice:nominalPrice];
    self.actualCharge = @(actualPrice);
}
-(double)discountAmount {
    return [AMCDiscountCalculator calculateDiscountWithDiscountType:self.discountType.integerValue onPrice:self.nominalCharge.doubleValue];
}

@end
