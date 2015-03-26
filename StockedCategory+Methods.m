//
//  StockedCategory+Methods.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 29/12/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "StockedCategory+Methods.h"

@implementation StockedCategory (Methods)
+(id)newObjectWithMoc:(NSManagedObjectContext*)moc
{
    StockedCategory *category = [NSEntityDescription insertNewObjectForEntityForName:@"StockedCategory" inManagedObjectContext:moc];
    NSDate * rightNow = [NSDate date];
    category.createdDate = rightNow;
    return category;
}
+(NSArray*)allObjectsWithMoc:(NSManagedObjectContext*)moc {
    NSArray * array = nil;
    NSFetchRequest * fetch = [NSFetchRequest fetchRequestWithEntityName:@"StockedCategory"];
    array = [moc executeFetchRequest:fetch error:nil];
    return array;
}
+(StockedCategory*)stockedCategoryWithName:(NSString*)name withMoc:(NSManagedObjectContext*)moc {
    NSPredicate * predicate = [NSPredicate predicateWithFormat:@"categoryName == %@",name];
    NSArray * array = nil;
    NSFetchRequest * fetch = [NSFetchRequest fetchRequestWithEntityName:@"StockedCategory"];
    [fetch setPredicate:predicate];
    array = [moc executeFetchRequest:fetch error:nil];
    NSAssert(array.count == 1,@"expected a count of 1");
    return array[0];
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
