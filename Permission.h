//
//  Permission.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 25/01/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class BusinessFunction, Role;

NS_ASSUME_NONNULL_BEGIN

@interface Permission: NSManagedObject
+(NSArray*)allObjectsWithMoc:(NSManagedObjectContext*)moc;
+(id)newObjectWithMoc:(NSManagedObjectContext*)moc;
+(Permission*)fetchPermissionWithRole:(Role*)role businessFunction:(BusinessFunction*)businessFunction;
@end

NS_ASSUME_NONNULL_END

#import "Permission+CoreDataProperties.h"
