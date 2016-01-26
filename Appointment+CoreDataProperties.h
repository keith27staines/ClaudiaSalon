//
//  Appointment+CoreDataProperties.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 26/01/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Appointment.h"

NS_ASSUME_NONNULL_BEGIN

@interface Appointment (CoreDataProperties)

@property (nullable, nonatomic, retain) NSDate *appointmentDate;
@property (nullable, nonatomic, retain) NSDate *appointmentEndDate;
@property (nullable, nonatomic, retain) NSNumber *bookedDuration;
@property (nullable, nonatomic, retain) NSString *cancellationNote;
@property (nullable, nonatomic, retain) NSNumber *cancellationType;
@property (nullable, nonatomic, retain) NSNumber *cancelled;
@property (nullable, nonatomic, retain) NSNumber *completed;
@property (nullable, nonatomic, retain) NSString *completionNote;
@property (nullable, nonatomic, retain) NSNumber *completionType;
@property (nullable, nonatomic, retain) NSDate *createdDate;
@property (nullable, nonatomic, retain) NSDate *lastUpdatedDate;
@property (nullable, nonatomic, retain) NSData *bqMetadata;
@property (nullable, nonatomic, retain) NSNumber *bqNeedsCoreDataExport;
@property (nullable, nonatomic, retain) Customer *customer;
@property (nullable, nonatomic, retain) NSSet<Note *> *notes;
@property (nullable, nonatomic, retain) Sale *sale;

@end

@interface Appointment (CoreDataGeneratedAccessors)

- (void)addNotesObject:(Note *)value;
- (void)removeNotesObject:(Note *)value;
- (void)addNotes:(NSSet<Note *> *)values;
- (void)removeNotes:(NSSet<Note *> *)values;

@end

NS_ASSUME_NONNULL_END
