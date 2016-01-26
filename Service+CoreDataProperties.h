//
//  Service+CoreDataProperties.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 26/01/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Service.h"

NS_ASSUME_NONNULL_BEGIN

@interface Service (CoreDataProperties)

@property (nullable, nonatomic, retain) NSDate *createdDate;
@property (nullable, nonatomic, retain) NSNumber *deluxe;
@property (nullable, nonatomic, retain) NSNumber *expectedTimeRequired;
@property (nullable, nonatomic, retain) NSNumber *hairLength;
@property (nullable, nonatomic, retain) NSNumber *hidden;
@property (nullable, nonatomic, retain) NSDate *lastUpdatedDate;
@property (nullable, nonatomic, retain) NSNumber *maximumCharge;
@property (nullable, nonatomic, retain) NSNumber *minimumCharge;
@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, retain) NSNumber *nominalCharge;
@property (nullable, nonatomic, retain) NSNumber *priceNegotiable;
@property (nullable, nonatomic, retain) NSNumber *selectable;
@property (nullable, nonatomic, retain) NSData *bqMetadata;
@property (nullable, nonatomic, retain) NSNumber *bqNeedsCoreDataExport;
@property (nullable, nonatomic, retain) NSSet<Employee *> *canBeDoneBy;
@property (nullable, nonatomic, retain) NSSet<Note *> *notes;
@property (nullable, nonatomic, retain) NSSet<Product *> *product;
@property (nullable, nonatomic, retain) NSSet<SaleItem *> *saleItem;
@property (nullable, nonatomic, retain) ServiceCategory *serviceCategory;

@end

@interface Service (CoreDataGeneratedAccessors)

- (void)addCanBeDoneByObject:(Employee *)value;
- (void)removeCanBeDoneByObject:(Employee *)value;
- (void)addCanBeDoneBy:(NSSet<Employee *> *)values;
- (void)removeCanBeDoneBy:(NSSet<Employee *> *)values;

- (void)addNotesObject:(Note *)value;
- (void)removeNotesObject:(Note *)value;
- (void)addNotes:(NSSet<Note *> *)values;
- (void)removeNotes:(NSSet<Note *> *)values;

- (void)addProductObject:(Product *)value;
- (void)removeProductObject:(Product *)value;
- (void)addProduct:(NSSet<Product *> *)values;
- (void)removeProduct:(NSSet<Product *> *)values;

- (void)addSaleItemObject:(SaleItem *)value;
- (void)removeSaleItemObject:(SaleItem *)value;
- (void)addSaleItem:(NSSet<SaleItem *> *)values;
- (void)removeSaleItem:(NSSet<SaleItem *> *)values;

@end

NS_ASSUME_NONNULL_END
