//
//  BusinessFunction+CoreDataProperties.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 26/01/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "BusinessFunction.h"

NS_ASSUME_NONNULL_BEGIN

@interface BusinessFunction (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *codeUnitName;
@property (nullable, nonatomic, retain) NSString *fullDescription;
@property (nullable, nonatomic, retain) NSString *functionName;
@property (nullable, nonatomic, retain) NSSet<Permission *> *permissions;

@end

@interface BusinessFunction (CoreDataGeneratedAccessors)

- (void)addPermissionsObject:(Permission *)value;
- (void)removePermissionsObject:(Permission *)value;
- (void)addPermissions:(NSSet<Permission *> *)values;
- (void)removePermissions:(NSSet<Permission *> *)values;

@end

NS_ASSUME_NONNULL_END
