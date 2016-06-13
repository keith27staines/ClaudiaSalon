//
//  Customer+CoreDataProperties.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 28/03/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Customer.h"

NS_ASSUME_NONNULL_BEGIN

@interface Customer (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *addressLine1;
@property (nullable, nonatomic, retain) NSString *addressLine2;
@property (nullable, nonatomic, retain) NSString *birthday;
@property (nullable, nonatomic, retain) NSString *bqCloudID;
@property (nullable, nonatomic, retain) NSNumber *bqHasClientChanges;
@property (nullable, nonatomic, retain) NSData *bqMetadata;
@property (nullable, nonatomic, retain) NSNumber *bqNeedsCoreDataExport;
@property (nullable, nonatomic, retain) NSDate *createdDate;
@property (nullable, nonatomic, retain) NSNumber *dayOfBirth;
@property (nullable, nonatomic, retain) NSString *email;
@property (nullable, nonatomic, retain) NSString *firstName;
@property (nullable, nonatomic, retain) NSString *fullName;
@property (nullable, nonatomic, retain) NSNumber *hidden;
@property (nullable, nonatomic, retain) NSString *lastName;
@property (nullable, nonatomic, retain) NSDate *lastUpdatedDate;
@property (nullable, nonatomic, retain) NSDate *lastVisitDate;
@property (nullable, nonatomic, retain) NSNumber *monthOfBirth;
@property (nullable, nonatomic, retain) NSString *phone;
@property (nullable, nonatomic, retain) NSString *postcode;
@property (nullable, nonatomic, retain) NSString *saleType;
@property (nullable, nonatomic, retain) NSString *title;
@property (nullable, nonatomic, retain) NSString *uid;
@property (nullable, nonatomic, retain) Salon *anonymousCustomerForSalon;
@property (nullable, nonatomic, retain) NSSet<Appointment *> *appointments;
@property (nullable, nonatomic, retain) NSSet<Note *> *notes;
@property (nullable, nonatomic, retain) NSSet<Sale *> *sales;

@end

@interface Customer (CoreDataGeneratedAccessors)

- (void)addAppointmentsObject:(Appointment *)value;
- (void)removeAppointmentsObject:(Appointment *)value;
- (void)addAppointments:(NSSet<Appointment *> *)values;
- (void)removeAppointments:(NSSet<Appointment *> *)values;

- (void)addNotesObject:(Note *)value;
- (void)removeNotesObject:(Note *)value;
- (void)addNotes:(NSSet<Note *> *)values;
- (void)removeNotes:(NSSet<Note *> *)values;

- (void)addSalesObject:(Sale *)value;
- (void)removeSalesObject:(Sale *)value;
- (void)addSales:(NSSet<Sale *> *)values;
- (void)removeSales:(NSSet<Sale *> *)values;

@end

NS_ASSUME_NONNULL_END
