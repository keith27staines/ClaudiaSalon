//
//  Product+Methods.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 19/07/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "Product+Methods.h"

@implementation Product (Methods)
+(id)newObjectWithMoc:(NSManagedObjectContext*)moc
{
    Product * product = [NSEntityDescription insertNewObjectForEntityForName:@"Product" inManagedObjectContext:moc];
    NSDate * rightNow = [NSDate date];
    product.createdDate = rightNow;
    product.lastUpdatedDate = rightNow;
    return product;
}
+(NSArray*)allObjectsWithMoc:(NSManagedObjectContext*)moc {
    NSArray * array = nil;
    NSFetchRequest * fetch = [NSFetchRequest fetchRequestWithEntityName:@"Product"];
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
@end
