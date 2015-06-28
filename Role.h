//
//  Role.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 28/06/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Employee, Permission, Salon;

@interface Role : NSManagedObject

@property (nonatomic, retain) NSString * fullDescription;
@property (nonatomic, retain) NSNumber * isSystemRole;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) Salon *accountantRoleForSalon;
@property (nonatomic, retain) Salon *basicUserRoleForSalon;
@property (nonatomic, retain) Salon *devSupportRoleForSalon;
@property (nonatomic, retain) NSSet *employeesInRole;
@property (nonatomic, retain) Salon *managerRoleForSalon;
@property (nonatomic, retain) Salon *receptionistRoleForSalon;
@property (nonatomic, retain) NSSet *permissions;
@property (nonatomic, retain) Salon *systemAdminRoleForSalon;
@property (nonatomic, retain) Salon *systemRoleForSalon;
@end

@interface Role (CoreDataGeneratedAccessors)

- (void)addEmployeesInRoleObject:(Employee *)value;
- (void)removeEmployeesInRoleObject:(Employee *)value;
- (void)addEmployeesInRole:(NSSet *)values;
- (void)removeEmployeesInRole:(NSSet *)values;

- (void)addPermissionsObject:(Permission *)value;
- (void)removePermissionsObject:(Permission *)value;
- (void)addPermissions:(NSSet *)values;
- (void)removePermissions:(NSSet *)values;

@end
