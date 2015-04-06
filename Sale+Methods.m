//
//  Sale+Methods.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 19/07/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "Sale+Methods.h"
#import "SaleItem+Methods.h"
#import "Payment+Methods.h"
#import "Account+Methods.h"
#import "AMCDiscountCalculator.h"
#import "Salon+Methods.h"


@implementation Sale (Methods)

+(id)newObjectWithMoc:(NSManagedObjectContext*)moc
{
    Sale * sale = [NSEntityDescription insertNewObjectForEntityForName:@"Sale" inManagedObjectContext:moc];
    NSDate * rightNow = [NSDate date];
    
    sale.nominalCharge = @(0);
    sale.actualCharge = @(0);
    
    sale.createdDate = rightNow;
    sale.lastUpdatedDate = rightNow;
    sale.account = [Salon salonWithMoc:moc].tillAccount;
    return sale;
}
+(NSArray*)allObjectsWithMoc:(NSManagedObjectContext*)moc {
    NSArray * array = nil;
    NSFetchRequest * fetch = [NSFetchRequest fetchRequestWithEntityName:@"Sale"];
    array = [moc executeFetchRequest:fetch error:nil];
    return array;
}
+(NSArray*)salesBetweenStartDate:(NSDate*)startDate endDate:(NSDate*)endDate withMoc:(NSManagedObjectContext*)moc{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Sale" inManagedObjectContext:moc];
    [fetchRequest setEntity:entity];
    // Specify criteria for filtering which objects to fetch
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"createdDate <= %@ && createdDate >= %@", endDate,startDate];
    [fetchRequest setPredicate:predicate];
    // Specify how the fetched objects should be sorted
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createdDate"
                                                                   ascending:YES];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];
    
    NSError *error = nil;
    NSArray *fetchedObjects = [moc executeFetchRequest:fetchRequest error:&error];
    if (fetchedObjects == nil) {
        [NSApp presentError:error];
    }
    return fetchedObjects;
}
+(Sale*)firstEverSaleWithMoc:(NSManagedObjectContext*)moc {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Sale" inManagedObjectContext:moc];
    [fetchRequest setEntity:entity];

    // Predicate
    NSPredicate * predicate = [NSPredicate predicateWithFormat:@"voided = %@ and isQuote = %@ and hidden = %@",@(NO),@(NO),@(NO)];
    // Specify how the fetched objects should be sorted
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createdDate"
                                                                   ascending:YES];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];
    [fetchRequest setPredicate:predicate];
    
    NSError *error = nil;
    NSArray *fetchedObjects = [moc executeFetchRequest:fetchRequest error:&error];
    if (!fetchedObjects || fetchedObjects.count == 0) {
        return nil;
    } else {
         return fetchedObjects[0];
    }
}
-(NSString*)saleType {
    if (self.isQuote.boolValue) {
        return @"Quote";
    } else {
        return @"Sale";
    }
}
-(NSString*)refundStatus
{
    double refundAmount = 0;
    for (SaleItem * saleItem in self.saleItem) {
        if (saleItem.refund) {
            refundAmount += saleItem.refund.amount.doubleValue;
        }
    }
    if (refundAmount == 0) {
        return @"";
    }
    if (refundAmount < self.actualCharge.doubleValue) {
        return [NSString stringWithFormat:@"Partial refund of £%1.2f",refundAmount];
    }
    if (refundAmount == self.actualCharge.doubleValue) {
        return [NSString stringWithFormat:@"Full refund of £%1.2f",refundAmount];
    }
    NSAssert(NO, @"Unexpected status");
    return @"Error";
}
-(NSNumber *)discountAmount
{
    return @(self.nominalCharge.doubleValue - self.actualCharge.doubleValue);
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
-(void)updatePriceFromSaleItems {
    double saleItemNominalTotal = 0.0;
    double saleItemActualTotal = 0.0;
    double nonDiscountedItemTotal = 0.0;
    for (SaleItem * saleItem in self.saleItem) {
        saleItemNominalTotal += [AMCDiscountCalculator roundVeryCloseOrDown:saleItem.nominalCharge.doubleValue];
        saleItemActualTotal += [AMCDiscountCalculator roundVeryCloseOrDown:saleItem.actualCharge.doubleValue];
        if (saleItem.discountType.integerValue == AMCDiscountNone) {
            nonDiscountedItemTotal += [AMCDiscountCalculator roundVeryCloseOrDown:saleItem.nominalCharge.doubleValue];
        }
    }
    double extraDiscount = 0.0;
    double discountedExtra;
    AMCDiscount extraDiscountType = self.discountType.integerValue;
    if (extraDiscountType < AMCDiscountLowestPound ) {
        discountedExtra = [AMCDiscountCalculator calculateDiscountedPriceWithDiscountType:extraDiscountType undiscountedPrice:nonDiscountedItemTotal];
        extraDiscount = [AMCDiscountCalculator calculateDiscountWithDiscountType:extraDiscountType onPrice:nonDiscountedItemTotal];
    } else {
        discountedExtra = [AMCDiscountCalculator calculateDiscountedPriceWithDiscountType:extraDiscountType undiscountedPrice:saleItemActualTotal];
        discountedExtra = [AMCDiscountCalculator roundVeryCloseOrDown:discountedExtra];
        extraDiscount = saleItemActualTotal - discountedExtra;
    }
    double actualCharge = saleItemActualTotal - extraDiscount;
    double totalDiscount = saleItemNominalTotal - saleItemActualTotal + extraDiscount;

    self.nominalCharge = @(saleItemNominalTotal);
    self.actualCharge = @(actualCharge);
    self.discountAmount = @(totalDiscount);
    self.chargeAfterIndividualDiscounts = @(saleItemActualTotal);
}
-(double)roundUpPenny:(double)amount
{
    return ceil(amount * 100.0) / 100.0;
}
-(double)roundDownPenny:(double)amount
{
    return floor(amount * 100.0) / 100.0;
}
@end
