//
//  Employee.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 23/06/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Holiday, Note, Role, Salary, SaleItem, Salon, Service, WorkRecord;

@interface Employee : NSManagedObject

@property (nonatomic, retain) NSString * addressLine1;
@property (nonatomic, retain) NSString * addressLine2;
@property (nonatomic, retain) NSNumber * basicHourlyRate;
@property (nonatomic, retain) NSNumber * basicHoursPerWeek;
@property (nonatomic, retain) NSDate * createdDate;
@property (nonatomic, retain) NSNumber * dayOfBirth;
@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSString * firstName;
@property (nonatomic, retain) NSNumber * hidden;
@property (nonatomic, retain) NSNumber * isActive;
@property (nonatomic, retain) NSString * lastName;
@property (nonatomic, retain) NSDate * lastUpdatedDate;
@property (nonatomic, retain) NSDate * leavingDate;
@property (nonatomic, retain) NSNumber * monthOfBirth;
@property (nonatomic, retain) NSNumber * paidFromManagersBudget;
@property (nonatomic, retain) NSString * password;
@property (nonatomic, retain) NSString * phone;
@property (nonatomic, retain) id photo;
@property (nonatomic, retain) NSString * postcode;
@property (nonatomic, retain) NSDate * startingDate;
@property (nonatomic, retain) NSString * uid;
@property (nonatomic, retain) NSSet *canDo;
@property (nonatomic, retain) NSSet *holidays;
@property (nonatomic, retain) Salon *manages;
@property (nonatomic, retain) NSSet *notes;
@property (nonatomic, retain) NSSet *notesCreated;
@property (nonatomic, retain) NSSet *performedService;
@property (nonatomic, retain) NSSet *roles;
@property (nonatomic, retain) NSSet *salaries;
@property (nonatomic, retain) NSSet *workRecords;
@property (nonatomic, retain) WorkRecord *workRecordTemplate;
@end

@interface Employee (CoreDataGeneratedAccessors)

- (void)addCanDoObject:(Service *)value;
- (void)removeCanDoObject:(Service *)value;
- (void)addCanDo:(NSSet *)values;
- (void)removeCanDo:(NSSet *)values;

- (void)addHolidaysObject:(Holiday *)value;
- (void)removeHolidaysObject:(Holiday *)value;
- (void)addHolidays:(NSSet *)values;
- (void)removeHolidays:(NSSet *)values;

- (void)addNotesObject:(Note *)value;
- (void)removeNotesObject:(Note *)value;
- (void)addNotes:(NSSet *)values;
- (void)removeNotes:(NSSet *)values;

- (void)addNotesCreatedObject:(Note *)value;
- (void)removeNotesCreatedObject:(Note *)value;
- (void)addNotesCreated:(NSSet *)values;
- (void)removeNotesCreated:(NSSet *)values;

- (void)addPerformedServiceObject:(SaleItem *)value;
- (void)removePerformedServiceObject:(SaleItem *)value;
- (void)addPerformedService:(NSSet *)values;
- (void)removePerformedService:(NSSet *)values;

- (void)addRolesObject:(Role *)value;
- (void)removeRolesObject:(Role *)value;
- (void)addRoles:(NSSet *)values;
- (void)removeRoles:(NSSet *)values;

- (void)addSalariesObject:(Salary *)value;
- (void)removeSalariesObject:(Salary *)value;
- (void)addSalaries:(NSSet *)values;
- (void)removeSalaries:(NSSet *)values;

- (void)addWorkRecordsObject:(WorkRecord *)value;
- (void)removeWorkRecordsObject:(WorkRecord *)value;
- (void)addWorkRecords:(NSSet *)values;
- (void)removeWorkRecords:(NSSet *)values;

@end
