//
//  Role.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 23/06/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Employee, RoleAction, Salon;

@interface Role : NSManagedObject

@property (nonatomic, retain) NSString * fullDescription;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * isSystemRole;
@property (nonatomic, retain) NSSet *allowedActions;
@property (nonatomic, retain) NSSet *employeesInRole;
@property (nonatomic, retain) Salon *systemRoleForSalon;
@property (nonatomic, retain) Salon *devSupportRoleForSalon;
@property (nonatomic, retain) Salon *systemAdminRoleForSalon;
@property (nonatomic, retain) Salon *managerRoleForSalon;
@property (nonatomic, retain) Salon *accountantRoleForSalon;
@property (nonatomic, retain) Salon *receptionistRoleForSalon;
@property (nonatomic, retain) Salon *basicUserRoleForSalon;
@end

@interface Role (CoreDataGeneratedAccessors)

- (void)addAllowedActionsObject:(RoleAction *)value;
- (void)removeAllowedActionsObject:(RoleAction *)value;
- (void)addAllowedActions:(NSSet *)values;
- (void)removeAllowedActions:(NSSet *)values;

- (void)addEmployeesInRoleObject:(Employee *)value;
- (void)removeEmployeesInRoleObject:(Employee *)value;
- (void)addEmployeesInRole:(NSSet *)values;
- (void)removeEmployeesInRole:(NSSet *)values;

@end
