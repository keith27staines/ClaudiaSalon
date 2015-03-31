//
//  Salary.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 31/03/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
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
