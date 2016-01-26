//
//  OpeningHoursWeekTemplate+CoreDataProperties.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 26/01/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "OpeningHoursWeekTemplate.h"

NS_ASSUME_NONNULL_BEGIN

@interface OpeningHoursWeekTemplate (CoreDataProperties)

@property (nullable, nonatomic, retain) NSSet<OpeningHoursDayTemplate *> *dayTemplates;
@property (nullable, nonatomic, retain) Salon *salon;

@end

@interface OpeningHoursWeekTemplate (CoreDataGeneratedAccessors)

- (void)addDayTemplatesObject:(OpeningHoursDayTemplate *)value;
- (void)removeDayTemplatesObject:(OpeningHoursDayTemplate *)value;
- (void)addDayTemplates:(NSSet<OpeningHoursDayTemplate *> *)values;
- (void)removeDayTemplates:(NSSet<OpeningHoursDayTemplate *> *)values;

@end

NS_ASSUME_NONNULL_END
