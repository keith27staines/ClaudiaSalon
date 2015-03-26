//
//  AMCSalaryCalculator.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 10/02/2015.
//  Copyright (c) 2015 Keith Staines. All rights reserved.
//

#import "AMCSalaryCalculator.h"
#import "Salary+Methods.h"
#import "WorkRecord+Methods.h"
#import "Employee+Methods.h"
#import "NSDate+AMCDate.h"
#import "Payment+Methods.h"

@implementation AMCSalaryCalculator

-(double)payForWorkRecords:(NSArray*)workRecords {
    Employee * employee;
    double pay = 0;
    for (WorkRecord * workRecord in workRecords) {
        if (!employee) {
            employee = workRecord.employee;
        } else {
            NSAssert(employee == workRecord.employee, @"work record is for wrong employee");
        }
        pay += [self payForWorkRecord:workRecord];
    }
    return pay;
}
-(double)payForWorkRecord:(WorkRecord*)workRecord {
    NSArray * salaries = [self allSalariesForWorkRecord:workRecord];
    double pay = 0;
    for (Salary * salary in salaries) {
        pay += [self payForWorkRecord:workRecord againstSalary:salary];
    }
    return pay;
}
-(double)payForWorkRecord:(WorkRecord*)workRecord againstSalary:(Salary*)salary {
    double pay = 0;
    if (salary.payByHour) {
        NSDictionary * hoursDictionary = [self hoursWorkedForWorkRecord:workRecord againstSalary:salary];
        double standardHours = ((NSNumber*)hoursDictionary[@"standard"]).doubleValue;
        double extraHours = ((NSNumber*)hoursDictionary[@"extra"]).doubleValue;
        pay = (standardHours * salary.hourlyRate.doubleValue +extraHours * salary.extraHoursRate.doubleValue);
    } else {
        return -1000;
    }
    return pay;
}
-(double)standardHoursWorkedForWorkRecord:(WorkRecord *)workRecord {
    double hours = 0;
    NSArray * salaries = [self allSalariesForWorkRecord:workRecord];
    for (Salary * salary in salaries) {
        NSDictionary * hoursDictionary = [self hoursWorkedForWorkRecord:workRecord againstSalary:salary];
        hours += ((NSNumber*)(hoursDictionary[@"standard"])).doubleValue;
    }
    return hours;
}
-(double)extraHoursWorkedForWorkRecord:(WorkRecord *)workRecord {
    double hours = 0;
    NSArray * salaries = [self allSalariesForWorkRecord:workRecord];
    for (Salary * salary in salaries) {
        NSDictionary * hoursDictionary = [self hoursWorkedForWorkRecord:workRecord againstSalary:salary];
        hours += ((NSNumber*)(hoursDictionary[@"extra"])).doubleValue;
    }
    return hours;
}
-(NSInteger)daysWorkedForWorkRecord:(WorkRecord*)workRecord {
    NSMutableDictionary * daysWorked = [NSMutableDictionary dictionary];
    [self getDaysWorkedForWorkRecord:workRecord inDictionary:daysWorked];
    return daysWorked.count;
}
-(void)getDaysWorkedForWorkRecord:(WorkRecord*)workRecord inDictionary:(NSMutableDictionary*)daysWorked {
    NSDictionary * hoursDictionary = workRecord.hoursWorkedDictionary;
    for (NSString * day in hoursDictionary) {
        NSNumber * hoursOnDay = hoursDictionary[day];
        double hours = hoursOnDay.doubleValue;
        if (hours > 0) {
            daysWorked[day] = @(YES);
        }
    }
}
-(NSDictionary*)hoursWorkedForWorkRecord:(WorkRecord *)workRecord againstSalary:(Salary*)salary {
    double hoursWorked = 0;
    double standardHours= 0;
    double extraHours = 0;
    for (int day = 0; day < 7; day++) {
        NSDate * startOfDay = [self startOfDayForWorkRecord:workRecord atDayIndex:day];
        NSDate * endOfDay = [startOfDay endOfDay];
        if ([salary.validFromDate isLessThan:endOfDay] && [salary.validToDate isGreaterThan:startOfDay]) {
            hoursWorked = [self hoursFromWorkRecord:workRecord onDate:startOfDay];
            if (hoursWorked <= salary.nominalHoursPerDay.doubleValue) {
                standardHours += hoursWorked;
                extraHours += 0;
            } else {
                standardHours += salary.nominalHoursPerDay.doubleValue;
                extraHours += hoursWorked - salary.nominalHoursPerDay.doubleValue;
            }

        }
    }
    return @{@"standard":@(standardHours), @"extra":@(extraHours)};
}
-(double)amountOfPayOutstandingForWorkRecord:(WorkRecord*)workRecord {
    double totalPayRequired = [self payForWorkRecord:workRecord];
    double amountPaid = [self amountPaidForWorkRecord:workRecord];
    return totalPayRequired - amountPaid;
}
-(double)amountPaidForWorkRecord:(WorkRecord*)workRecord {
    double pay = 0;
    for (Payment * payment in workRecord.wages) {
        if (!payment.voided.boolValue) {
            pay += payment.amount.doubleValue;
        }
    }
    return pay;
}
-(double)hoursFromWorkRecord:(WorkRecord*)workRecord onDate:(NSDate*)date {
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat: @"EEEE"];
    if ([[[dateFormatter stringFromDate:date] lowercaseString] isEqualToString:@"monday"]) return workRecord.monday.doubleValue;
    if ([[[dateFormatter stringFromDate:date] lowercaseString] isEqualToString:@"tuesday"]) return workRecord.tuesday.doubleValue;
    if ([[[dateFormatter stringFromDate:date] lowercaseString] isEqualToString:@"wednesday"]) return workRecord.wednesday.doubleValue;
    if ([[[dateFormatter stringFromDate:date] lowercaseString] isEqualToString:@"thursday"]) return workRecord.thursday.doubleValue;
    if ([[[dateFormatter stringFromDate:date] lowercaseString] isEqualToString:@"friday"]) return workRecord.friday.doubleValue;
    if ([[[dateFormatter stringFromDate:date] lowercaseString] isEqualToString:@"saturday"]) return workRecord.saturday.doubleValue;
    if ([[[dateFormatter stringFromDate:date] lowercaseString] isEqualToString:@"sunday"]) return workRecord.sunday.doubleValue;
    NSAssert(NO,@"Unable to calculate day");
    return 0;
}
-(NSDate*)startOfDayForWorkRecord:(WorkRecord*)workRecord atDayIndex:(NSInteger)day {
    NSDate * middleOfLastDay = [[workRecord.weekEndingDate beginningOfDay] dateByAddingTimeInterval:12*3600];
    NSDate * middleOfIndexedDay = [middleOfLastDay dateByAddingTimeInterval:-(6-day)*24*3600];
    return [middleOfIndexedDay beginningOfDay];
}
-(NSArray*)allSalariesForWorkRecord:(WorkRecord*)workRecord {
    NSArray * salariesForEmployee = [self dateSortedSalariesForEmployee:workRecord.employee];
    NSMutableArray * salariesForWorkRecord = [NSMutableArray array];
    for (Salary * salary in salariesForEmployee) {
        if ([AMCSalaryCalculator doesIntervalOfWorkRecord:workRecord overlapSalary:salary]) {
            [salariesForWorkRecord addObject:salary];
        }
    }
    return salariesForWorkRecord;
}
-(NSArray*)dateSortedSalariesForEmployee:(Employee*)employee {
    NSArray * allSalaries = [employee.salaries allObjects];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"validFromDate"
                                                                   ascending:YES];
    allSalaries = [allSalaries sortedArrayUsingDescriptors:@[sortDescriptor]];
    return allSalaries;
}
-(BOOL)isSalaryModifiable:(Salary*)salary {
    NSArray * workRecords = [salary.employee.workRecords allObjects];
    for (WorkRecord * workRecord in workRecords) {
        if (workRecord.isTemplate.boolValue) continue;
        if (!workRecord.wages.count > 0) continue;
        if ([AMCSalaryCalculator doesIntervalOfWorkRecord:workRecord overlapSalary:salary]) {
            return NO;
        }
    }
    return YES;
}
+(BOOL)doesIntervalOfWorkRecord:(WorkRecord*)workRecord overlapSalary:(Salary*)salary {
    NSDate * recordEndDate = workRecord.weekEndingDate;
    NSDate * recordStartDate = [recordEndDate dateByAddingTimeInterval:-7*24*3600];
    if ([salary.validFromDate isLessThan:recordEndDate] && [salary.validToDate isGreaterThan:recordStartDate]) {
        return YES;
    }
    return NO;
}

-(NSDictionary*)amalgamatedWorkHoursDictionary:(NSArray*)workRecords {
    NSDate * endDate;
    NSMutableDictionary * workHours;
    double hoursAlready = 0;
    double hoursToAdd = 0;
    for (WorkRecord * workRecord in workRecords) {
        if (!workHours) {
            workHours = [[workRecord hoursWorkedDictionary] mutableCopy];
            endDate = workRecord.weekEndingDate;
        } else {
            NSAssert([workRecord.weekEndingDate isEqualToDate:endDate],@"Cannot amalgamate this work record because its end date is different to that of the first");
            
            for (NSString * day in workRecord.hoursWorkedDictionary) {
                hoursAlready = ((NSNumber*)(workHours[day])).doubleValue;
                hoursToAdd = ((NSNumber*)(workRecord.hoursWorkedDictionary[day])).doubleValue;
                workHours[day] = @(hoursAlready + hoursToAdd);
            }            
        }
    }
    return [workHours copy];
}



@end
