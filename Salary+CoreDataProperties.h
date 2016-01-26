//
//  Salary+CoreDataProperties.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 26/01/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Salary.h"

NS_ASSUME_NONNULL_BEGIN

@interface Salary (CoreDataProperties)

@property (nullable, nonatomic, retain) NSNumber *extraHoursRate;
@property (nullable, nonatomic, retain) NSNumber *hourlyRate;
@property (nullable, nonatomic, retain) NSNumber *nominalDaysPerWeek;
@property (nullable, nonatomic, retain) NSNumber *nominalHoursPerDay;
@property (nullable, nonatomic, retain) NSNumber *payByHour;
@property (nullable, nonatomic, retain) NSNumber *percentage;
@property (nullable, nonatomic, retain) NSDate *validFromDate;
@property (nullable, nonatomic, retain) NSDate *validToDate;
@property (nullable, nonatomic, retain) Employee *employee;

@end

NS_ASSUME_NONNULL_END
