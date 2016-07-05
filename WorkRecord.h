//
//  WorkRecord.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 25/01/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Employee, Payment;

@interface WorkRecord: NSManagedObject
+(NSManagedObject*)createObjectInMoc:(NSManagedObjectContext*)moc;
+(NSArray*)allObjectsWithMoc:(NSManagedObjectContext*)moc;
@property (readonly) NSNumber * totalHoursForWeek;
@property (readonly) NSNumber * daysWorked;
@property (copy) NSDictionary * hoursWorkedDictionary;
@property (readonly, copy) NSDate * weekBeginningDate;

-(NSNumber*)hoursForDay:(NSString*)dayName;
-(void)setHours:(NSNumber*) hours forDay:(NSString*)dayName;

@end

#import "WorkRecord+CoreDataProperties.h"
