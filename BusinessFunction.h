//
//  BusinessFunction.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 25/01/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Permission;

NS_ASSUME_NONNULL_BEGIN

@interface BusinessFunction: NSManagedObject
+(NSArray*)allObjectsWithMoc:(NSManagedObjectContext*)moc;
+(id)newObjectWithMoc:(NSManagedObjectContext*)moc;
+(BusinessFunction*)fetchBusinessFunctionWithCodeUnitName:(NSString*)name inMoc:(NSManagedObjectContext*)moc;
-(NSArray*)mappedRoles;
@end

NS_ASSUME_NONNULL_END

#import "BusinessFunction+CoreDataProperties.h"
