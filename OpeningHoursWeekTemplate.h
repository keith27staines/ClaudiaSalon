//
//  OpeningHoursWeekTemplate.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 31/03/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class OpeningHoursDayTemplate, Salon;

@interface OpeningHoursWeekTemplate : NSManagedObject

@property (nonatomic, retain) NSSet *dayTemplates;
@property (nonatomic, retain) Salon *salon;
@end

@interface OpeningHoursWeekTemplate (CoreDataGeneratedAccessors)

- (void)addDayTemplatesObject:(OpeningHoursDayTemplate *)value;
- (void)removeDayTemplatesObject:(OpeningHoursDayTemplate *)value;
- (void)addDayTemplates:(NSSet *)values;
- (void)removeDayTemplates:(NSSet *)values;

@end
