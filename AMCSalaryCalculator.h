//
//  AMCSalaryCalculator.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 10/02/2015.
//  Copyright (c) 2015 Keith Staines. All rights reserved.
//

@class WorkRecord, Salary, Employee, Payment;

#import <Foundation/Foundation.h>

@interface AMCSalaryCalculator : NSObject

+(BOOL)doesIntervalOfWorkRecord:(WorkRecord*)workRecord overlapSalary:(Salary*)salary;

-(BOOL)isSalaryModifiable:(Salary*)salary;

-(NSArray*)dateSortedSalariesForEmployee:(Employee*)employee;
-(NSArray*)allSalariesForWorkRecord:(WorkRecord*)workRecord;

-(double)amountPaidForWorkRecord:(WorkRecord*)workRecord;
-(double)amountOfPayOutstandingForWorkRecord:(WorkRecord*)workRecord;
-(double)payForWorkRecord:(WorkRecord*)workRecord;
-(double)payForWorkRecords:(NSArray*)workRecords;
-(NSDictionary*)amalgamatedWorkHoursDictionary:(NSArray*)workRecords;
-(double)standardHoursWorkedForWorkRecord:(WorkRecord*)workRecord;
-(double)extraHoursWorkedForWorkRecord:(WorkRecord*)workRecord;
-(NSInteger)daysWorkedForWorkRecord:(WorkRecord*)workRecord;
@end
