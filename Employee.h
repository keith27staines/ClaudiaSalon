//
//  Employee.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 25/01/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "AMCObjectWithNotesProtocol.h"

@class Holiday, Note, Role, Salary, SaleItem, Salon, Service, WorkRecord, BusinessFunction;

NS_ASSUME_NONNULL_BEGIN

@interface Employee: NSManagedObject <AMCObjectWithNotesProtocol>

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


NS_ASSUME_NONNULL_END

#import "Employee+CoreDataProperties.h"
