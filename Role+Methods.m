//
//  Role+Methods.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 23/06/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "Role+Methods.h"
#import "Salon+Methods.h"
#import "RoleAction+Methods.h"
#import "Employee+Methods.h"

@implementation Role (Methods)

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
+(id)newObjectWithMoc:(NSManagedObjectContext*)moc {
    Role * role = [NSEntityDescription insertNewObjectForEntityForName:@"Role" inManagedObjectContext:moc];
    return role;
}
-(NSNumber*)allowsActionWithCodeUnitName:(NSString*)name actionName:(NSString*)verb {
    RoleAction * action = [self actionWithCodeUnitName:name verb:verb];
    return [self allowsAction:action];
}
-(NSNumber*)allowsAction:(RoleAction*)action {
    if ([self.allowedActions containsObject:action]) {
        return @YES;
    }
    return @NO;
}
-(RoleAction*)actionWithCodeUnitName:(NSString*)name verb:(NSString*)verb {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"codeUnitName == %@ and actionName == %@",name,verb];
    NSSet * filteredSet = [self.allowedActions filteredSetUsingPredicate:predicate];
    if (!filteredSet || filteredSet.count == 0) {
        return nil;
    } else {
        NSAssert(filteredSet.count == 1, @"RoleAction names must be unique");
        return filteredSet.anyObject;
    }
}

@end
