//
//  WorkRecord+Methods.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 29/01/2015.
//  Copyright (c) 2015 Keith Staines. All rights reserved.
//
#import "AMCSalonDocument.h"
#import "WorkRecord.h"

@interface WorkRecord (Methods)
+(id)newObjectWithMoc:(NSManagedObjectContext*)moc;
+(NSArray*)allObjectsWithMoc:(NSManagedObjectContext*)moc;
@property (readonly) NSNumber * totalHoursForWeek;
@property (readonly) NSNumber * daysWorked;
@property (copy) NSDictionary * hoursWorkedDictionary;
@property (readonly, copy) NSDate * weekBeginningDate;

-(NSNumber*)hoursForDay:(NSString*)dayName;
-(void)setHours:(NSNumber*) hours forDay:(NSString*)dayName;

@end
