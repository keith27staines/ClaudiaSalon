//
//  SaleItem+CoreDataProperties.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 21/03/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "SaleItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface SaleItem (CoreDataProperties)

@property (nullable, nonatomic, retain) NSNumber *actualCharge;
@property (nullable, nonatomic, retain) NSString *bqCloudID;
@property (nullable, nonatomic, retain) NSData *bqMetadata;
@property (nullable, nonatomic, retain) NSNumber *bqNeedsCoreDataExport;
@property (nullable, nonatomic, retain) NSDate *createdDate;
@property (nullable, nonatomic, retain) NSNumber *discountType;
@property (nullable, nonatomic, retain) NSNumber *discountValue;
@property (nullable, nonatomic, retain) NSNumber *discountVersion;
@property (nullable, nonatomic, retain) NSDate *lastUpdatedDate;
@property (nullable, nonatomic, retain) NSNumber *maximumCharge;
@property (nullable, nonatomic, retain) NSNumber *minimumCharge;
@property (nullable, nonatomic, retain) NSNumber *nominalCharge;
@property (nullable, nonatomic, retain) NSNumber *bqHasClientChanges;
@property (nullable, nonatomic, retain) NSSet<Note *> *notes;
@property (nullable, nonatomic, retain) Employee *performedBy;
@property (nullable, nonatomic, retain) Payment *refund;
@property (nullable, nonatomic, retain) Sale *sale;
@property (nullable, nonatomic, retain) Service *service;

@end

@interface SaleItem (CoreDataGeneratedAccessors)

- (void)addNotesObject:(Note *)value;
- (void)removeNotesObject:(Note *)value;
- (void)addNotes:(NSSet<Note *> *)values;
- (void)removeNotes:(NSSet<Note *> *)values;

@end

NS_ASSUME_NONNULL_END
