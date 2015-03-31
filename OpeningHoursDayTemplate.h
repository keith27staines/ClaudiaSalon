//
//  OpeningHoursDayTemplate.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 31/03/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class IntervalDuringDay, OpeningHoursWeekTemplate;

@interface OpeningHoursDayTemplate : NSManagedObject

@property (nonatomic, retain) NSString * dayName;
@property (nonatomic, retain) IntervalDuringDay *intervalDuringDay;
@property (nonatomic, retain) OpeningHoursWeekTemplate *openingHoursWeekTemplate;

@end
