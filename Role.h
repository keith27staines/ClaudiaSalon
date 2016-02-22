//
//  Role.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 25/01/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Employee, Permission, Salon, BusinessFunction;

NS_ASSUME_NONNULL_BEGIN

@interface Role: NSManagedObject
+(NSArray*)allObjectsWithMoc:(NSManagedObjectContext*)moc;
+(id)newObjectWithMoc:(NSManagedObjectContext*)moc;
-(NSNumber*)allowsBusinessFunction:(BusinessFunction*)function verb:(NSString*)verb;
-(Permission*)permissionForBusinessFunction:(BusinessFunction*)function;
@end

NS_ASSUME_NONNULL_END

#import "Role+CoreDataProperties.h"
