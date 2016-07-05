//
//  Note.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 25/01/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

#import "Note.h"

@implementation Note
+(NSManagedObject*)createObjectInMoc:(NSManagedObjectContext*)moc
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
