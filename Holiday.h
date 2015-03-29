//
//  Holiday.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 28/03/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Employee, IntervalDuringDay;

@interface Holiday : NSManagedObject

@property (nonatomic, retain) NSNumber * isSalonHoliday;
@property (nonatomic, retain) NSNumber * wholeDay;
@property (nonatomic, retain) NSNumber * isPublicHoliday;
@property (nonatomic, retain) NSString * holidayName;
@property (nonatomic, retain) Employee *employee;
@property (nonatomic, retain) IntervalDuringDay *intervalDuringDay;

@end
