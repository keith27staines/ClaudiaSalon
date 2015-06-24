//
//  RoleAction.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 23/06/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Role;

@interface RoleAction : NSManagedObject

@property (nonatomic, retain) NSString * fullDescription;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *roles;
@end

@interface RoleAction (CoreDataGeneratedAccessors)

- (void)addRolesObject:(Role *)value;
- (void)removeRolesObject:(Role *)value;
- (void)addRoles:(NSSet *)values;
- (void)removeRoles:(NSSet *)values;

@end
