//
//  IntervalDuringDay+CoreDataProperties.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 26/01/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "IntervalDuringDay.h"

NS_ASSUME_NONNULL_BEGIN

@interface IntervalDuringDay (CoreDataProperties)

@property (nullable, nonatomic, retain) NSNumber *endTime;
@property (nullable, nonatomic, retain) NSNumber *startTime;
@property (nullable, nonatomic, retain) CalendarDay *calendarDay;
@property (nullable, nonatomic, retain) Holiday *holiday;
@property (nullable, nonatomic, retain) OpeningHoursDayTemplate *openingHoursDayTemplate;

@end

NS_ASSUME_NONNULL_END
