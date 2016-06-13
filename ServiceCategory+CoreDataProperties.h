//
//  ServiceCategory+CoreDataProperties.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 28/03/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "ServiceCategory.h"

NS_ASSUME_NONNULL_BEGIN

@interface ServiceCategory (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *bqCloudID;
@property (nullable, nonatomic, retain) NSNumber *bqHasClientChanges;
@property (nullable, nonatomic, retain) NSData *bqMetadata;
@property (nullable, nonatomic, retain) NSNumber *bqNeedsCoreDataExport;
@property (nullable, nonatomic, retain) NSDate *createdDate;
@property (nullable, nonatomic, retain) NSNumber *hidden;
@property (nullable, nonatomic, retain) NSNumber *index;
@property (nullable, nonatomic, retain) NSNumber *isDefaultCategory;
@property (nullable, nonatomic, retain) NSNumber *isSystemCategory;
@property (nullable, nonatomic, retain) NSDate *lastUpdatedDate;
@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, retain) NSNumber *selectable;
@property (nullable, nonatomic, retain) NSSet<Note *> *notes;
@property (nullable, nonatomic, retain) ServiceCategory *parent;
@property (nullable, nonatomic, retain) Salon *rootCategoryOfSalon;
@property (nullable, nonatomic, retain) Salon *salon;
@property (nullable, nonatomic, retain) NSSet<Service *> *service;
@property (nullable, nonatomic, retain) NSSet<ServiceCategory *> *subCategories;

@end

@interface ServiceCategory (CoreDataGeneratedAccessors)

- (void)addNotesObject:(Note *)value;
- (void)removeNotesObject:(Note *)value;
- (void)addNotes:(NSSet<Note *> *)values;
- (void)removeNotes:(NSSet<Note *> *)values;

- (void)addServiceObject:(Service *)value;
- (void)removeServiceObject:(Service *)value;
- (void)addService:(NSSet<Service *> *)values;
- (void)removeService:(NSSet<Service *> *)values;

- (void)addSubCategoriesObject:(ServiceCategory *)value;
- (void)removeSubCategoriesObject:(ServiceCategory *)value;
- (void)addSubCategories:(NSSet<ServiceCategory *> *)values;
- (void)removeSubCategories:(NSSet<ServiceCategory *> *)values;

@end

NS_ASSUME_NONNULL_END
