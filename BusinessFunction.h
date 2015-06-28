//
//  BusinessFunction.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 28/06/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Permission;

@interface BusinessFunction : NSManagedObject

@property (nonatomic, retain) NSString * codeUnitName;
@property (nonatomic, retain) NSString * fullDescription;
@property (nonatomic, retain) NSString * functionName;
@property (nonatomic, retain) NSSet *permissions;
@end

@interface BusinessFunction (CoreDataGeneratedAccessors)

- (void)addPermissionsObject:(Permission *)value;
- (void)removePermissionsObject:(Permission *)value;
- (void)addPermissions:(NSSet *)values;
- (void)removePermissions:(NSSet *)values;

@end
