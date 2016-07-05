//
//  Role.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 25/01/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

#import "Role.h"
#import "Employee.h"
#import "Permission.h"
#import "Salon.h"

#import "BusinessFunction.h"
#import "Permission.h"

@implementation Role

+(NSArray*)allObjectsWithMoc:(NSManagedObjectContext*)moc {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Role" inManagedObjectContext:moc];
    [fetchRequest setEntity:entity];
    
    // Specify how the fetched objects should be sorted
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name"
                                                                   ascending:YES];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];
    
    NSError *error = nil;
    NSArray *fetchedObjects = [moc executeFetchRequest:fetchRequest error:&error];
    return fetchedObjects;
}
+(NSManagedObject*)createObjectInMoc:(NSManagedObjectContext*)moc {
    Role * role = [NSEntityDescription insertNewObjectForEntityForName:@"Role" inManagedObjectContext:moc];
    return role;
}
-(NSNumber*)allowsBusinessFunction:(BusinessFunction*)function verb:(NSString*)verb {
    NSPredicate * predicate = [NSPredicate predicateWithFormat:@"businessFunction = %@",function];
    NSSet * filteredSet = [self.permissions filteredSetUsingPredicate:predicate];
    NSAssert(filteredSet.count < 2, @"There should only be one Permission connecting the specified function to this role");
    if (filteredSet.count == 1) {
        Permission * permission = filteredSet.anyObject;
        if ([verb isEqualToString:@"View"] && permission.viewAction.boolValue) {
            return @YES;
        }
        if ([verb isEqualToString:@"Edit"] && permission.editAction.boolValue) {
            return @YES;
        }
        if ([verb isEqualToString:@"Create"] && permission.createAction.boolValue) {
            return @YES;
        }
        return @NO;
    }
    return @NO;
}
-(Permission*)permissionForBusinessFunction:(BusinessFunction*)function {
    NSPredicate * predicate = [NSPredicate predicateWithFormat:@"businessFunction = %@",function];
    NSSet * permissionForFunction = [self.permissions filteredSetUsingPredicate:predicate];
    if (!permissionForFunction || permissionForFunction.count == 0) {
        return nil;
    }
    NSAssert(permissionForFunction.count == 1, @"There should be exactly one permission joining this role %@ to business function",self,function);
    return [permissionForFunction anyObject];
}

@end

