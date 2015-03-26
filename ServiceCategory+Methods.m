//
//  ServiceCategory+Methods.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 24/07/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "ServiceCategory+Methods.h"

@implementation ServiceCategory (Methods)
+(id)newObjectWithMoc:(NSManagedObjectContext*)moc
{
    ServiceCategory * serviceCategory = [NSEntityDescription insertNewObjectForEntityForName:@"ServiceCategory" inManagedObjectContext:moc];
    NSDate * rightNow = [NSDate date];
    serviceCategory.createdDate = rightNow;
    serviceCategory.lastUpdatedDate = rightNow;
    return serviceCategory;
}
+(NSArray*)allObjectsWithMoc:(NSManagedObjectContext*)moc {
    NSArray * array = nil;
    NSFetchRequest * fetch = [NSFetchRequest fetchRequestWithEntityName:@"ServiceCategory"];
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

-(BOOL)isHairCategory {
    if ([[self.name substringToIndex:4].uppercaseString isEqualToString:@"HAIR"]) {
        return YES;
    }
    return NO;
}
@end
