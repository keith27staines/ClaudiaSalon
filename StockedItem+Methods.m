//
//  StockedItem+Methods.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 29/12/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "StockedItem+Methods.h"
#import "Note+Methods.h"

@implementation StockedItem (Methods)

+(id)newObjectWithMoc:(NSManagedObjectContext*)moc
{
    StockedItem *stockedItem = [NSEntityDescription insertNewObjectForEntityForName:@"StockedItem" inManagedObjectContext:moc];
    NSDate * rightNow = [NSDate date];
    stockedItem.createdDate = rightNow;
    return stockedItem;
}
+(NSArray*)allObjectsWithMoc:(NSManagedObjectContext*)moc {
    NSArray * array = nil;
    NSFetchRequest * fetch = [NSFetchRequest fetchRequestWithEntityName:@"StockedItem"];
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
