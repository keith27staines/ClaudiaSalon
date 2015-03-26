//
//  Note+Methods.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 29/08/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "Note+Methods.h"

@implementation Note (Methods)
+(id)newObjectWithMoc:(NSManagedObjectContext*)moc
{
    Note * note = [NSEntityDescription insertNewObjectForEntityForName:@"Note" inManagedObjectContext:moc];
    NSDate * rightNow = [NSDate date];
    note.createdDate = rightNow;
    note.lastUpdatedDate = rightNow;
    note.title = @"";
    note.text = @"";
    return note;
}
+(NSArray*)allObjectsWithMoc:(NSManagedObjectContext*)moc {
    NSArray * array = nil;
    NSFetchRequest * fetch = [NSFetchRequest fetchRequestWithEntityName:@"Note"];
    array = [moc executeFetchRequest:fetch error:nil];
    return array;
}
@end
