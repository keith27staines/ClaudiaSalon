//
//  NSPersistentDocument+SalonMethods.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 23/02/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "NSPersistentDocument+SalonMethods.h"
#import "LastUpdatedBy.h"

@implementation NSPersistentDocument (SalonMethods)
-(void)deleteObject:(NSManagedObject*)object {
    [[self managedObjectContext] deleteObject:object];
}
-(LastUpdatedBy*)lastUpdate {
    NSManagedObjectContext * moc = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"LastUpdatedBy" inManagedObjectContext:moc];
    [fetchRequest setEntity:entity];
    NSArray *fetchedObjects = [moc executeFetchRequest:fetchRequest error:nil];
    if (fetchedObjects == nil) {
        return NO;
    }
    LastUpdatedBy * lastUpdatedBy = 0;
    if (fetchedObjects.count == 0) {
        lastUpdatedBy = [NSEntityDescription insertNewObjectForEntityForName:@"LastUpdatedBy" inManagedObjectContext:moc];
    } else {
        lastUpdatedBy = fetchedObjects[0];
    }
    if (!lastUpdatedBy) {
        NSAssert(NO,@"Could not create lastUpdated record and no pre-existing record exists");
        return NO;
    }
    return lastUpdatedBy;
}
-(BOOL)islastUpdateByCurrentUserOnCurrentComputer {
    LastUpdatedBy * lastUpdate = [self lastUpdate];
    if ( [lastUpdate.userIdentity isEqualToString:NSFullUserName()] && [lastUpdate.computerIdentity isEqualToString:[self computerName]] ) {
        return YES;
    } else {
        return NO;
    }
}
-(NSString*)computerName {
    static NSString * computerName = @"";
    if ([computerName isEqualToString:@""]) {
        computerName = [[NSHost currentHost] localizedName];
    }
    return computerName;
}
@end
