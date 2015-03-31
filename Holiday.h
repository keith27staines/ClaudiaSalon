//
//  Holiday.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 31/03/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Employee, IntervalDuringDay;

@interface Holiday : NSManagedObject

@property (nonatomic, retain) NSString * holidayName;
@property (nonatomic, retain) NSNumber * isPublicHoliday;
@property (nonatomic, retain) NSNumber * isSalonHoliday;
@property (nonatomic, retain) NSNumber * wholeDay;
@property (nonatomic, retain) Employee *employee;
@property (nonatomic, retain) IntervalDuringDay *intervalDuringDay;

@end
