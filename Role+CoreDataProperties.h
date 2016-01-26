//
//  Role+CoreDataProperties.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 26/01/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Role.h"

NS_ASSUME_NONNULL_BEGIN

@interface Role (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *fullDescription;
@property (nullable, nonatomic, retain) NSNumber *isSystemRole;
@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, retain) Salon *accountantRoleForSalon;
@property (nullable, nonatomic, retain) Salon *basicUserRoleForSalon;
@property (nullable, nonatomic, retain) Salon *devSupportRoleForSalon;
@property (nullable, nonatomic, retain) NSSet<Employee *> *employeesInRole;
@property (nullable, nonatomic, retain) Salon *managerRoleForSalon;
@property (nullable, nonatomic, retain) NSSet<Permission *> *permissions;
@property (nullable, nonatomic, retain) Salon *receptionistRoleForSalon;
@property (nullable, nonatomic, retain) Salon *systemAdminRoleForSalon;
@property (nullable, nonatomic, retain) Salon *systemRoleForSalon;

@end

@interface Role (CoreDataGeneratedAccessors)

- (void)addEmployeesInRoleObject:(Employee *)value;
- (void)removeEmployeesInRoleObject:(Employee *)value;
- (void)addEmployeesInRole:(NSSet<Employee *> *)values;
- (void)removeEmployeesInRole:(NSSet<Employee *> *)values;

- (void)addPermissionsObject:(Permission *)value;
- (void)removePermissionsObject:(Permission *)value;
- (void)addPermissions:(NSSet<Permission *> *)values;
- (void)removePermissions:(NSSet<Permission *> *)values;

@end

NS_ASSUME_NONNULL_END
