//
//  StockedCategory+CoreDataProperties.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 26/01/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "StockedCategory.h"

NS_ASSUME_NONNULL_BEGIN

@interface StockedCategory (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *categoryName;
@property (nullable, nonatomic, retain) NSDate *createdDate;
@property (nullable, nonatomic, retain) NSString *fullDescription;
@property (nullable, nonatomic, retain) NSSet<Note *> *notes;
@property (nullable, nonatomic, retain) StockedCategory *parentCategory;
@property (nullable, nonatomic, retain) NSSet<StockedProduct *> *stockedProduct;
@property (nullable, nonatomic, retain) NSSet<StockedCategory *> *subCategories;

@end

@interface StockedCategory (CoreDataGeneratedAccessors)

- (void)addNotesObject:(Note *)value;
- (void)removeNotesObject:(Note *)value;
- (void)addNotes:(NSSet<Note *> *)values;
- (void)removeNotes:(NSSet<Note *> *)values;

- (void)addStockedProductObject:(StockedProduct *)value;
- (void)removeStockedProductObject:(StockedProduct *)value;
- (void)addStockedProduct:(NSSet<StockedProduct *> *)values;
- (void)removeStockedProduct:(NSSet<StockedProduct *> *)values;

- (void)addSubCategoriesObject:(StockedCategory *)value;
- (void)removeSubCategoriesObject:(StockedCategory *)value;
- (void)addSubCategories:(NSSet<StockedCategory *> *)values;
- (void)removeSubCategories:(NSSet<StockedCategory *> *)values;

@end

NS_ASSUME_NONNULL_END
