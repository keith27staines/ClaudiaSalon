//
//  CalendarDay.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 28/03/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class IntervalDuringDay;

@interface CalendarDay : NSManagedObject

@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) IntervalDuringDay *openingTimes;

@end
