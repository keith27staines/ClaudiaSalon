//
//  Salary.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 25/01/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Employee;

NS_ASSUME_NONNULL_BEGIN

@interface Salary: NSManagedObject
@property NSNumber * weeklyRate;
+(NSManagedObject*)createObjectInMoc:(NSManagedObjectContext*)moc;
+(NSArray*)allObjectsWithMoc:(NSManagedObjectContext*)moc;
@end

NS_ASSUME_NONNULL_END

#import "Salary+CoreDataProperties.h"
