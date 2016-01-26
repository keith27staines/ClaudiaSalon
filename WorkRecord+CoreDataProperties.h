//
//  WorkRecord+CoreDataProperties.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 26/01/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "WorkRecord.h"

NS_ASSUME_NONNULL_BEGIN

@interface WorkRecord (CoreDataProperties)

@property (nullable, nonatomic, retain) NSNumber *friday;
@property (nullable, nonatomic, retain) NSNumber *isTemplate;
@property (nullable, nonatomic, retain) NSNumber *monday;
@property (nullable, nonatomic, retain) NSNumber *saturday;
@property (nullable, nonatomic, retain) NSNumber *sunday;
@property (nullable, nonatomic, retain) NSNumber *thursday;
@property (nullable, nonatomic, retain) NSNumber *tuesday;
@property (nullable, nonatomic, retain) NSNumber *wednesday;
@property (nullable, nonatomic, retain) NSDate *weekEndingDate;
@property (nullable, nonatomic, retain) NSSet<Payment *> *bonuses;
@property (nullable, nonatomic, retain) Employee *employee;
@property (nullable, nonatomic, retain) NSSet<Payment *> *wages;
@property (nullable, nonatomic, retain) Employee *workRecordTemplateForEmployee;

@end

@interface WorkRecord (CoreDataGeneratedAccessors)

- (void)addBonusesObject:(Payment *)value;
- (void)removeBonusesObject:(Payment *)value;
- (void)addBonuses:(NSSet<Payment *> *)values;
- (void)removeBonuses:(NSSet<Payment *> *)values;

- (void)addWagesObject:(Payment *)value;
- (void)removeWagesObject:(Payment *)value;
- (void)addWages:(NSSet<Payment *> *)values;
- (void)removeWages:(NSSet<Payment *> *)values;

@end

NS_ASSUME_NONNULL_END
