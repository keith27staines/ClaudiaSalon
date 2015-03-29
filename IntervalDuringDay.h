//
//  IntervalDuringDay.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 28/03/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class CalendarDay, Holiday, OpeningHoursDayTemplate;

@interface IntervalDuringDay : NSManagedObject

@property (nonatomic, retain) NSNumber * startTime;
@property (nonatomic, retain) NSNumber * endTime;
@property (nonatomic, retain) OpeningHoursDayTemplate *openingHoursDayTemplate;
@property (nonatomic, retain) Holiday *holiday;
@property (nonatomic, retain) CalendarDay *calendarDay;

@end
