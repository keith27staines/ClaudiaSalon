//
//  SaleItem.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 25/01/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

#import "SaleItem.h"
#import "Employee.h"
#import "Note.h"
#import "Payment.h"
#import "Sale.h"
#import "Service.h"

#import "AMCDiscountCalculator.h"
#import "AMCConstants.h"

@implementation SaleItem

+(id)newObjectWithMoc:(NSManagedObjectContext*)moc
{
    SaleItem * saleItem = [NSEntityDescription insertNewObjectForEntityForName:@"SaleItem" inManagedObjectContext:moc];
    NSDate * rightNow = [NSDate date];
    saleItem.createdDate = rightNow;
    saleItem.lastUpdatedDate = rightNow;
    saleItem.discountVersion = @2;
    saleItem.isActive = @YES;
    return saleItem;
}
+(NSArray*)allObjectsWithMoc:(NSManagedObjectContext*)moc {
    NSArray * array = nil;
    NSFetchRequest * fetch = [NSFetchRequest fetchRequestWithEntityName:@"SaleItem"];
    array = [moc executeFetchRequest:fetch error:nil];
    return array;
}
+(void)markSaleItemsForExportInMoc:(NSManagedObjectContext*)parentMoc saleItemIDs:(NSSet*)saleItemIDs {
    NSManagedObjectContext * privateMoc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    privateMoc.parentContext = parentMoc;
    [privateMoc performBlockAndWait:^{
        for (NSManagedObjectID * saleItemID in saleItemIDs) {
            SaleItem * saleItem = [privateMoc objectWithID:saleItemID];
            if (saleItem) {
                NSDate * rightNow = [NSDate date];
                saleItem.lastUpdatedDate = rightNow;
                saleItem.bqNeedsCoreDataExport = @YES;
                NSError * error;
                [privateMoc save:(&error)];
                if (error) {
                    NSAssert(@"Error while marking saleItem for export: %@",error.description);
                }
            }
        }
    }];
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
            NSAssert(NO, @"SaleItem has an obsolete version number, cannot update price");
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
            NSAssert(NO,@"Can't calculate discountAmount for saleItem with (obsolete) discountVersion = 1");
            return 0;
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
