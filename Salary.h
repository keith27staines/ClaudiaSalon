//
//  Salary.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 19/02/2015.
//  Copyright (c) 2015 Keith Staines. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Employee;

@interface Salary : NSManagedObject

@property (nonatomic, retain) NSNumber * extraHoursRate;
@property (nonatomic, retain) NSNumber * hourlyRate;
@property (nonatomic, retain) NSNumber * nominalDaysPerWeek;
@property (nonatomic, retain) NSNumber * nominalHoursPerDay;
@property (nonatomic, retain) NSNumber * payByHour;
@property (nonatomic, retain) NSNumber * percentage;
@property (nonatomic, retain) NSDate * validFromDate;
@property (nonatomic, retain) NSDate * validToDate;
@property (nonatomic, retain) Employee *employee;

@end
