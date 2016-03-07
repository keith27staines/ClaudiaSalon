//
//  Holiday+CoreDataProperties.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 06/03/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Holiday.h"

NS_ASSUME_NONNULL_BEGIN

@interface Holiday (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *holidayName;
@property (nullable, nonatomic, retain) NSNumber *isPublicHoliday;
@property (nullable, nonatomic, retain) NSNumber *isSalonHoliday;
@property (nullable, nonatomic, retain) NSNumber *wholeDay;
@property (nullable, nonatomic, retain) Employee *employee;
@property (nullable, nonatomic, retain) IntervalDuringDay *intervalDuringDay;

@end

NS_ASSUME_NONNULL_END
