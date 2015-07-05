//
//  Employee+Methods.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 19/07/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "Employee.h"
#import "AMCSalonDocument.h"
#import "AMCObjectWithNotesProtocol.h"
@interface Employee (Methods) <AMCObjectWithNotesProtocol>

+(id)newObjectWithMoc:(NSManagedObjectContext*)moc;
+(NSArray*)allObjectsWithMoc:(NSManagedObjectContext*)moc;
+(NSArray*)allActiveEmployeesWithMoc:(NSManagedObjectContext*)moc;
+(NSArray*)employeesWhoCanPerformService:(Service*)service withMoc:(NSManagedObjectContext*)moc;
-(NSString *)fullName;
-(Salary*)salaryForDate:(NSDate*)date;
-(Salary*)currentSalary;
-(Salary*)endCurrentSalaryAndCreateNextOnDate:(NSDate*)lastDay;

-(Salary*)salaryFollowingSalary:(Salary*)salary;
-(Salary*)salaryPreceedingSalary:(Salary*)salary;
-(NSArray*)workRecordsForDate:(NSDate*)date;
-(WorkRecord*)ensureWorkRecordTemplateExists;
-(NSNumber*)canPerformBusinessFunction:(BusinessFunction*)businessFunction verb:(NSString*)verb;
+(NSArray*)fetchEmployeesWhoCanPerformBusinessFunction:(BusinessFunction*)function;

@end
