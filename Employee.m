//
//  Employee.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 25/01/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

#import "Employee.h"
#import "Holiday.h"
#import "Note.h"
#import "Role.h"
#import "SaleItem.h"
#import "Salon.h"

#import "WorkRecord.h"
#import "NSDate+AMCDate.h"
#import "Salary.h"
#import "Role.h"
#import "BusinessFunction.h"
#import "Service.h"

@implementation Employee

+(id)newObjectWithMoc:(NSManagedObjectContext*)moc
{
    Employee *employee = [NSEntityDescription insertNewObjectForEntityForName:@"Employee" inManagedObjectContext:moc];
    NSDate * rightNow = [NSDate date];
    
    employee.firstName = @"";
    employee.lastName = @"";
    employee.phone = @"";
    employee.email = @"";
    employee.postcode = @"";
    employee.addressLine1 = @"";
    employee.addressLine2 = @"";
    employee.dayOfBirth = 0;
    employee.monthOfBirth = 0;
    employee.createdDate = rightNow;
    employee.lastUpdatedDate = rightNow;
    employee.startingDate = rightNow;
    employee.leavingDate = [NSDate distantFuture];
    employee.uid = @"";
    employee.workRecordTemplate = [WorkRecord newObjectWithMoc:moc];
    Role * basicUserRole = [Salon salonWithMoc:moc].basicUserRole;
    if (basicUserRole) {
        [employee addRolesObject:basicUserRole];
    }
    return employee;
}
+(NSArray*)allActiveEmployeesWithMoc:(NSManagedObjectContext*)moc {
    NSPredicate * predicate = [NSPredicate predicateWithFormat:@"isActive == %@",@YES];
    return [[self allObjectsWithMoc:moc] filteredArrayUsingPredicate:predicate];
}
+(NSArray*)allObjectsWithMoc:(NSManagedObjectContext*)moc {
    NSArray * array = nil;
    NSFetchRequest * fetch = [NSFetchRequest fetchRequestWithEntityName:@"Employee"];
    fetch.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"firstName" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"lastName" ascending:YES]];
    array = [moc executeFetchRequest:fetch error:nil];
    return array;
}
+(NSArray*)employeesWhoCanPerformService:(Service*)service withMoc:(NSManagedObjectContext*)moc{
    NSArray * array = [service.canBeDoneBy allObjects];
    NSPredicate * predicate = [NSPredicate predicateWithFormat:@"isActive = %@",@YES];
    return [array filteredArrayUsingPredicate:predicate];
}
-(NSString *)fullName
{
    NSString * first = self.firstName;
    NSString * last = self.lastName;
    NSString * full = @"";
    if (first && first.length > 0) {
        full = [first copy];
    }
    if (last &&  last.length > 0) {
        full = [full stringByAppendingString:@" "];
        full = [full stringByAppendingString:last];
    }
    return full;
}
-(NSSet*)nonAuditNotes {
    NSMutableSet * nonAuditNotes = [NSMutableSet set];
    for (Note * note in self.notes) {
        if (!note.isAuditNote.boolValue) {
            [nonAuditNotes addObject:note];
        }
    }
    return nonAuditNotes;
}
-(Salary*)salaryForDate:(NSDate*)date {
    [self ensureOneSalaryExists];
    for (Salary * salary in self.salaries) {
        if ([salary.validFromDate isLessThanOrEqualTo:date] && [salary.validToDate isGreaterThan:date]) {
            return salary;
        }
    }
    return nil;
}
-(void)ensureOneSalaryExists {
    if (!self.salaries || self.salaries.count == 0) {
        Salary * salary = [Salary newObjectWithMoc:self.managedObjectContext];
        salary.validFromDate = [self.startingDate copy];
        [self addSalariesObject:salary];
    }
}
-(Salary*)currentSalary {
    NSDate * date = [NSDate date];
    return [self salaryForDate:date];
}
-(Salary*)endCurrentSalaryAndCreateNextOnDate:(NSDate*)lastDay {
    Salary * currentSalary = [self currentSalary];
    currentSalary.validToDate = [[lastDay endOfDay] dateByAddingTimeInterval:-1];
    Salary * nextSalary = [Salary newObjectWithMoc:self.managedObjectContext];
    nextSalary.validFromDate = [[[lastDay endOfDay] dateByAddingTimeInterval:1] beginningOfDay];
    nextSalary.validToDate = [NSDate distantFuture];
    nextSalary.payByHour = [currentSalary.payByHour copy];
    nextSalary.hourlyRate = [currentSalary.hourlyRate copy];
    nextSalary.extraHoursRate = [currentSalary.extraHoursRate copy];
    nextSalary.nominalDaysPerWeek = [currentSalary.nominalDaysPerWeek copy];
    nextSalary.nominalHoursPerDay = [currentSalary.nominalHoursPerDay copy];
    [self addSalariesObject:nextSalary];
    return nextSalary;
}

-(Salary*)salaryFollowingSalary:(Salary*)salary {
    NSDate * date = [salary.validToDate dateByAddingTimeInterval:24*3600];
    return [self salaryForDate:date];
}
-(Salary*)salaryPreceedingSalary:(Salary*)salary {
    NSDate * date = [salary.validFromDate dateByAddingTimeInterval:-24*3600];
    return [self salaryForDate:date];
}

-(NSArray*)workRecordsForDate:(NSDate*)date {
    NSAssert(date,@"date must not be nil");
    NSMutableArray * workRecords = [NSMutableArray array];
    for (WorkRecord * workRecord in self.workRecords) {
        if (workRecord.isTemplate.boolValue) continue;
        if ( [date isGreaterThanOrEqualTo:workRecord.weekBeginningDate] && [date isLessThanOrEqualTo:workRecord.weekEndingDate] ) {
            [workRecords addObject:workRecord];
        }
    }
    if (workRecords.count == 0) {
        WorkRecord * workRecord = [WorkRecord newObjectWithMoc:self.managedObjectContext];
        Salon * salon = [Salon salonWithMoc:self.managedObjectContext];
        workRecord.weekEndingDate = [[date lastDayOfSalonWeek:salon] endOfDay];
        WorkRecord * templateWorkRecord = [self ensureWorkRecordTemplateExists];
        workRecord.hoursWorkedDictionary = templateWorkRecord.hoursWorkedDictionary;
        [self addWorkRecordsObject:workRecord];
        [workRecords addObject:workRecord];
    }
    return workRecords;
}
-(WorkRecord*)ensureWorkRecordTemplateExists {
    if (!self.workRecordTemplate) {
        WorkRecord * workRecord = [WorkRecord newObjectWithMoc:self.managedObjectContext];
        workRecord.isTemplate = @YES;
        self.workRecordTemplate = workRecord;
    }
    return self.workRecordTemplate;
}
-(NSNumber*)canPerformBusinessFunction:(BusinessFunction*)businessFunction verb:(NSString*)verb {
    for (Role * role in self.roles) {
        if ([role allowsBusinessFunction:businessFunction verb:verb].boolValue) {
            return @YES;
        }
    }
    return @NO;
}
+(NSArray*)fetchEmployeesWhoCanPerformBusinessFunction:(BusinessFunction*)function {
    NSPredicate * predicate = [NSPredicate predicateWithFormat:@"any roles.permissions.businessFunction = %@",function];
    return [[self allActiveEmployeesWithMoc:function.managedObjectContext] filteredArrayUsingPredicate:predicate];
}

@end
