//
//  StockedBrand+CoreDataProperties.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 26/01/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "StockedBrand.h"

NS_ASSUME_NONNULL_BEGIN

@interface StockedBrand (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *brandName;
@property (nullable, nonatomic, retain) NSDate *createdDate;
@property (nullable, nonatomic, retain) NSString *shortBrandName;
@property (nullable, nonatomic, retain) NSSet<Note *> *notes;
@property (nullable, nonatomic, retain) NSSet<StockedProduct *> *stockedProducts;

@end

@interface StockedBrand (CoreDataGeneratedAccessors)

- (void)addNotesObject:(Note *)value;
- (void)removeNotesObject:(Note *)value;
- (void)addNotes:(NSSet<Note *> *)values;
- (void)removeNotes:(NSSet<Note *> *)values;

- (void)addStockedProductsObject:(StockedProduct *)value;
- (void)removeStockedProductsObject:(StockedProduct *)value;
- (void)addStockedProducts:(NSSet<StockedProduct *> *)values;
- (void)removeStockedProducts:(NSSet<StockedProduct *> *)values;

@end

NS_ASSUME_NONNULL_END
