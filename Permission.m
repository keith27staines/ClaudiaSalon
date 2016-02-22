//
//  Permission.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 25/01/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

#import "Permission.h"
#import "BusinessFunction.h"
#import "Role.h"

@implementation Permission
+(NSArray*)allObjectsWithMoc:(NSManagedObjectContext*)moc {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Permission" inManagedObjectContext:moc];
    [fetchRequest setEntity:entity];
    
    NSArray *fetchedObjects = [moc executeFetchRequest:fetchRequest error:nil];
    return fetchedObjects;
}
+(id)newObjectWithMoc:(NSManagedObjectContext*)moc {
    Permission * permission = [NSEntityDescription insertNewObjectForEntityForName:@"Permission" inManagedObjectContext:moc];
    return permission;
}
+(Permission*)fetchPermissionWithRole:(Role*)role businessFunction:(BusinessFunction*)businessFunction {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Permission" inManagedObjectContext:role.managedObjectContext];
    [fetchRequest setEntity:entity];
    // Specify criteria for filtering which objects to fetch
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"role = %@ and businessFunction = %@", role,businessFunction];
    [fetchRequest setPredicate:predicate];
    
    NSArray *fetchedObjects = [role.managedObjectContext executeFetchRequest:fetchRequest error:nil];
    if (!fetchedObjects || fetchedObjects.count == 0) {
        return nil;
    }
    NSAssert(fetchedObjects.count==1, @"There should be only one object joining the role to the business function");
    return fetchedObjects.firstObject;
}
@end

