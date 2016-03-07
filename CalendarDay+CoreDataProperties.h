//
//  CalendarDay+CoreDataProperties.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 06/03/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "CalendarDay.h"

NS_ASSUME_NONNULL_BEGIN

@interface CalendarDay (CoreDataProperties)

@property (nullable, nonatomic, retain) NSDate *date;
@property (nullable, nonatomic, retain) IntervalDuringDay *openingTimes;

@end

NS_ASSUME_NONNULL_END
