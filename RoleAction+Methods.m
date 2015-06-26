//
//  RoleAction+Methods.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 23/06/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "RoleAction+Methods.h"
#import "Role+Methods.h"
#import "Salon+Methods.h"
@implementation RoleAction (Methods)
+(NSArray*)allObjectsWithMoc:(NSManagedObjectContext*)moc {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"RoleAction" inManagedObjectContext:moc];
    [fetchRequest setEntity:entity];
    
    // Specify how the fetched objects should be sorted
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name"
                                                                   ascending:YES];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];
    
    NSError *error = nil;
    NSArray *fetchedObjects = [moc executeFetchRequest:fetchRequest error:&error];
    return fetchedObjects;
}
+(id)newObjectWithMoc:(NSManagedObjectContext*)moc {
    RoleAction * action = [NSEntityDescription insertNewObjectForEntityForName:@"RoleAction" inManagedObjectContext:moc];
    return action;
}
+(RoleAction*)fetchActionWithCodeUnitName:(NSString*)name actionName:(NSString*)action inMoc:(NSManagedObjectContext*)moc {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"codeUnitName == %@ and actionName = %@",name,action];
    NSArray * filteredArray = [[self allObjectsWithMoc:moc] filteredArrayUsingPredicate:predicate];
    if (!filteredArray || filteredArray.count == 0) {
        return nil;
    } else {
        NSAssert(filteredArray.count == 1, @"RoleAction names must be unique");
        return filteredArray.firstObject;
    }
}
@end
