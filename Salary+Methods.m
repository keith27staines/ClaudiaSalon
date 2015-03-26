//
//  Salary+Methods.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 08/02/2015.
//  Copyright (c) 2015 Keith Staines. All rights reserved.
//

#import "Salary+Methods.h"
#import "WorkRecord+Methods.h"
#import "Employee+Methods.h"
#import "AMCSalaryCalculator.h"
#import "AMCSalonDocument.h"

@implementation Salary (Methods)
+(id)newObjectWithMoc:(NSManagedObjectContext*)moc
{
    Salary *salary = [NSEntityDescription insertNewObjectForEntityForName:@"Salary" inManagedObjectContext:moc];
    salary.extraHoursRate = @(0);
    salary.nominalDaysPerWeek = @(6);
    salary.nominalHoursPerDay = @(8);
    salary.hourlyRate = @(0);
    salary.validFromDate = [NSDate distantPast];
    salary.validToDate = [NSDate distantFuture];
    salary.payByHour = @(YES);
    salary.percentage = @(60);
    return salary;
}

+(NSArray*)allObjectsWithMoc:(NSManagedObjectContext*)moc {
    NSArray * array = nil;
    NSFetchRequest * fetch = [NSFetchRequest fetchRequestWithEntityName:@"Salary"];
    array = [moc executeFetchRequest:fetch error:nil];
    return array;
}
-(NSNumber*)weeklyRate {
    double weeklyHours = self.nominalDaysPerWeek.doubleValue * self.nominalHoursPerDay.doubleValue;
    double hourlyRate = self.hourlyRate.doubleValue;
    return @(weeklyHours * hourlyRate);
}
-(void)setWeeklyRate:(NSNumber*)weeklyRate {
    double hoursPerDay = self.nominalHoursPerDay.doubleValue;
    double daysPerWeek = self.nominalDaysPerWeek.doubleValue;
    if (hoursPerDay > 0 && daysPerWeek > 0) {
        self.hourlyRate = @(weeklyRate.doubleValue / (hoursPerDay * daysPerWeek));
    } else {
        self.hourlyRate = @0;
    }
}
@end
