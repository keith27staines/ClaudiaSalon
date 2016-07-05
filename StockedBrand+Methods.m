//
//  StockedBrand+Methods.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 29/12/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "StockedBrand+Methods.h"
#import "Note.h"

@implementation StockedBrand (Methods)
+(NSManagedObject*)createObjectInMoc:(NSManagedObjectContext*)moc
{
    StockedBrand * brand = [NSEntityDescription insertNewObjectForEntityForName:@"StockedBrand" inManagedObjectContext:moc];
    NSDate * rightNow = [NSDate date];
    brand.createdDate = rightNow;
    return brand;
}
+(NSArray*)allObjectsWithMoc:(NSManagedObjectContext*)moc {
    NSArray * array = nil;
    NSFetchRequest * fetch = [NSFetchRequest fetchRequestWithEntityName:@"StockedBrand"];
    array = [moc executeFetchRequest:fetch error:nil];
    return array;
}
+(StockedBrand*)brandFromShortBrandName:(NSString*)shortName withMoc:(NSManagedObjectContext*)moc {
    NSPredicate * predicate = [NSPredicate predicateWithFormat:@"shortBrandName == %@",shortName];
    NSArray * filtered = [[self allObjectsWithMoc:moc] filteredArrayUsingPredicate:predicate];
    NSAssert(filtered.count == 1, @"Unexpected number of results - expected only one");
    return filtered[0];
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


@end
