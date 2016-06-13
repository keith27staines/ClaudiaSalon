//
//  Employee+CoreDataProperties.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 28/03/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Employee.h"

NS_ASSUME_NONNULL_BEGIN

@interface Employee (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *addressLine1;
@property (nullable, nonatomic, retain) NSString *addressLine2;
@property (nullable, nonatomic, retain) NSNumber *basicHourlyRate;
@property (nullable, nonatomic, retain) NSNumber *basicHoursPerWeek;
@property (nullable, nonatomic, retain) NSString *bqCloudID;
@property (nullable, nonatomic, retain) NSNumber *bqHasClientChanges;
@property (nullable, nonatomic, retain) NSData *bqMetadata;
@property (nullable, nonatomic, retain) NSNumber *bqNeedsCoreDataExport;
@property (nullable, nonatomic, retain) NSDate *createdDate;
@property (nullable, nonatomic, retain) NSNumber *dayOfBirth;
@property (nullable, nonatomic, retain) NSString *email;
@property (nullable, nonatomic, retain) NSString *firstName;
@property (nullable, nonatomic, retain) NSNumber *hidden;
@property (nullable, nonatomic, retain) NSNumber *isActive;
@property (nullable, nonatomic, retain) NSString *lastName;
@property (nullable, nonatomic, retain) NSDate *lastUpdatedDate;
@property (nullable, nonatomic, retain) NSDate *leavingDate;
@property (nullable, nonatomic, retain) NSNumber *monthOfBirth;
@property (nullable, nonatomic, retain) NSNumber *paidFromManagersBudget;
@property (nullable, nonatomic, retain) NSString *password;
@property (nullable, nonatomic, retain) NSString *phone;
@property (nullable, nonatomic, retain) id photo;
@property (nullable, nonatomic, retain) NSString *postcode;
@property (nullable, nonatomic, retain) NSDate *startingDate;
@property (nullable, nonatomic, retain) NSString *uid;
@property (nullable, nonatomic, retain) NSSet<Service *> *canDo;
@property (nullable, nonatomic, retain) NSSet<Holiday *> *holidays;
@property (nullable, nonatomic, retain) Salon *manages;
@property (nullable, nonatomic, retain) NSSet<Note *> *notes;
@property (nullable, nonatomic, retain) NSSet<Note *> *notesCreated;
@property (nullable, nonatomic, retain) NSSet<SaleItem *> *performedService;
@property (nullable, nonatomic, retain) NSSet<Role *> *roles;
@property (nullable, nonatomic, retain) NSSet<Salary *> *salaries;
@property (nullable, nonatomic, retain) NSSet<WorkRecord *> *workRecords;
@property (nullable, nonatomic, retain) WorkRecord *workRecordTemplate;

@end

@interface Employee (CoreDataGeneratedAccessors)

- (void)addCanDoObject:(Service *)value;
- (void)removeCanDoObject:(Service *)value;
- (void)addCanDo:(NSSet<Service *> *)values;
- (void)removeCanDo:(NSSet<Service *> *)values;

- (void)addHolidaysObject:(Holiday *)value;
- (void)removeHolidaysObject:(Holiday *)value;
- (void)addHolidays:(NSSet<Holiday *> *)values;
- (void)removeHolidays:(NSSet<Holiday *> *)values;

- (void)addNotesObject:(Note *)value;
- (void)removeNotesObject:(Note *)value;
- (void)addNotes:(NSSet<Note *> *)values;
- (void)removeNotes:(NSSet<Note *> *)values;

- (void)addNotesCreatedObject:(Note *)value;
- (void)removeNotesCreatedObject:(Note *)value;
- (void)addNotesCreated:(NSSet<Note *> *)values;
- (void)removeNotesCreated:(NSSet<Note *> *)values;

- (void)addPerformedServiceObject:(SaleItem *)value;
- (void)removePerformedServiceObject:(SaleItem *)value;
- (void)addPerformedService:(NSSet<SaleItem *> *)values;
- (void)removePerformedService:(NSSet<SaleItem *> *)values;

- (void)addRolesObject:(Role *)value;
- (void)removeRolesObject:(Role *)value;
- (void)addRoles:(NSSet<Role *> *)values;
- (void)removeRoles:(NSSet<Role *> *)values;

- (void)addSalariesObject:(Salary *)value;
- (void)removeSalariesObject:(Salary *)value;
- (void)addSalaries:(NSSet<Salary *> *)values;
- (void)removeSalaries:(NSSet<Salary *> *)values;

- (void)addWorkRecordsObject:(WorkRecord *)value;
- (void)removeWorkRecordsObject:(WorkRecord *)value;
- (void)addWorkRecords:(NSSet<WorkRecord *> *)values;
- (void)removeWorkRecords:(NSSet<WorkRecord *> *)values;

@end

NS_ASSUME_NONNULL_END
