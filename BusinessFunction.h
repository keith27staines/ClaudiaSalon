//
//  BusinessFunction.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 27/06/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Permission;

@interface BusinessFunction : NSManagedObject

@property (nonatomic, retain) NSString * fullDescription;
@property (nonatomic, retain) NSString * functionName;
@property (nonatomic, retain) NSString * codeUnitName;
@property (nonatomic, retain) NSSet *roleFunctionActions;
@end

@interface BusinessFunction (CoreDataGeneratedAccessors)

- (void)addRoleFunctionActionsObject:(Permission *)value;
- (void)removeRoleFunctionActionsObject:(Permission *)value;
- (void)addRoleFunctionActions:(NSSet *)values;
- (void)removeRoleFunctionActions:(NSSet *)values;

@end
