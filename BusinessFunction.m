//
//  BusinessFunction.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 25/01/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

#import "BusinessFunction.h"
#import "Permission.h"

#import "Role.h"
#import "Permission.h"
#import "Salon.h"

@implementation BusinessFunction
+(NSArray*)allObjectsWithMoc:(NSManagedObjectContext*)moc {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"BusinessFunction" inManagedObjectContext:moc];
    [fetchRequest setEntity:entity];
    
    // Specify how the fetched objects should be sorted
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"functionName"
                                                                   ascending:YES];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];
    
    NSError *error = nil;
    NSArray *fetchedObjects = [moc executeFetchRequest:fetchRequest error:&error];
    return fetchedObjects;
}
+(id)newObjectWithMoc:(NSManagedObjectContext*)moc {
    BusinessFunction * action = [NSEntityDescription insertNewObjectForEntityForName:@"BusinessFunction" inManagedObjectContext:moc];
    return action;
}
+(BusinessFunction*)fetchBusinessFunctionWithCodeUnitName:(NSString*)name inMoc:(NSManagedObjectContext*)moc {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"codeUnitName == %@",name];
    NSArray * filteredArray = [[self allObjectsWithMoc:moc] filteredArrayUsingPredicate:predicate];
    if (!filteredArray || filteredArray.count == 0) {
        return nil;
    } else {
        NSAssert(filteredArray.count == 1, @"BusinessFunction names must be unique");
        return filteredArray.firstObject;
    }
}
-(NSArray *)mappedRoles {
    NSMutableSet * mappedRoles = [NSMutableSet set];
    for (Permission * permission in self.permissions) {
        [mappedRoles addObject:permission.role];
    }
    return [mappedRoles allObjects];
}
@end

