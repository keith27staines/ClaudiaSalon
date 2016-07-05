//
//  StockedProduct+Methods.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 29/12/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "StockedProduct+Methods.h"
#import "Note.h"
#import "StockedProduct+Methods.h"
#import "StockedCategory+Methods.h"

@implementation StockedProduct (Methods)
+(NSManagedObject*)createObjectInMoc:(NSManagedObjectContext*)moc
{
    StockedProduct *stockedProduct = [NSEntityDescription insertNewObjectForEntityForName:@"StockedProduct" inManagedObjectContext:moc];
    NSDate * rightNow = [NSDate date];
    
    stockedProduct.createdDate = rightNow;

    return stockedProduct;
}
+(NSArray*)allObjectsWithMoc:(NSManagedObjectContext*)moc {
    NSArray * array = nil;
    NSFetchRequest * fetch = [NSFetchRequest fetchRequestWithEntityName:@"StockedProduct"];
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
+(NSArray*)allProductsForCategory:(StockedCategory*)category withMoc:(NSManagedObjectContext*)moc {
    NSArray * array = [category.stockedProduct allObjects];
    NSMutableArray * sortDescriptors = [NSMutableArray array];
    NSSortDescriptor * sort = [NSSortDescriptor sortDescriptorWithKey:@"stockedBrand.shortBrandName" ascending:YES];
    [sortDescriptors addObject:sort];
    sort = [NSSortDescriptor sortDescriptorWithKey:@"code" ascending:YES];
    [sortDescriptors addObject:sort];
    return [array sortedArrayUsingDescriptors:sortDescriptors];
}
+(NSArray*)allProductsForCategory:(StockedCategory*)category brand:(StockedBrand*)brand withMoc:(NSManagedObjectContext*)moc {
    NSPredicate * predicate = [NSPredicate predicateWithFormat:@"stockedBrand == %@",brand];
    NSArray * array = [self allProductsForCategory:category withMoc:moc];
    array = [array filteredArrayUsingPredicate:predicate];
    NSMutableArray * sortDescriptors = [NSMutableArray array];
    NSSortDescriptor * sort = [NSSortDescriptor sortDescriptorWithKey:@"stockedBrand.shortBrandName" ascending:YES];
    [sortDescriptors addObject:sort];
    sort = [NSSortDescriptor sortDescriptorWithKey:@"code" ascending:YES];
    [sortDescriptors addObject:sort];
    array = [array sortedArrayUsingDescriptors:sortDescriptors];
    return array;
}
+(StockedProduct*)fetchProductWithBarcode:(NSString*)barcode withMoc:(NSManagedObjectContext*)moc {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"StockedProduct" inManagedObjectContext:moc];
    [fetchRequest setEntity:entity];
    // Specify criteria for filtering which objects to fetch
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"barcode == %@", barcode];
    [fetchRequest setPredicate:predicate];
    
    NSError *error = nil;
    NSArray *fetchedObjects = [moc executeFetchRequest:fetchRequest error:&error];
    if (fetchedObjects == nil) {
        NSLog(@"Unexpected error: %@",error);
    }
    if (fetchedObjects.count == 0) {
        return nil;
    }
    if (fetchedObjects.count == 1) {
        return fetchedObjects[0];
    }
    NSAssert(fetchedObjects.count < 2, @"More than one product with barcode");
    return nil;
}
@end
