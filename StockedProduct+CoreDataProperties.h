//
//  StockedProduct+CoreDataProperties.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 26/01/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "StockedProduct.h"

NS_ASSUME_NONNULL_BEGIN

@interface StockedProduct (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *barcode;
@property (nullable, nonatomic, retain) NSString *code;
@property (nullable, nonatomic, retain) NSDate *createdDate;
@property (nullable, nonatomic, retain) NSNumber *currentStockLevel;
@property (nullable, nonatomic, retain) NSNumber *isConsumable;
@property (nullable, nonatomic, retain) NSDate *lastUpdatedDate;
@property (nullable, nonatomic, retain) NSNumber *minimumStockTrigger;
@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, retain) NSNumber *numberToBuy;
@property (nullable, nonatomic, retain) NSSet<Note *> *notes;
@property (nullable, nonatomic, retain) NSSet<ShoppingListItem *> *shoppingListItems;
@property (nullable, nonatomic, retain) StockedBrand *stockedBrand;
@property (nullable, nonatomic, retain) StockedCategory *stockedCategory;
@property (nullable, nonatomic, retain) NSSet<StockedItem *> *stockedItems;

@end

@interface StockedProduct (CoreDataGeneratedAccessors)

- (void)addNotesObject:(Note *)value;
- (void)removeNotesObject:(Note *)value;
- (void)addNotes:(NSSet<Note *> *)values;
- (void)removeNotes:(NSSet<Note *> *)values;

- (void)addShoppingListItemsObject:(ShoppingListItem *)value;
- (void)removeShoppingListItemsObject:(ShoppingListItem *)value;
- (void)addShoppingListItems:(NSSet<ShoppingListItem *> *)values;
- (void)removeShoppingListItems:(NSSet<ShoppingListItem *> *)values;

- (void)addStockedItemsObject:(StockedItem *)value;
- (void)removeStockedItemsObject:(StockedItem *)value;
- (void)addStockedItems:(NSSet<StockedItem *> *)values;
- (void)removeStockedItems:(NSSet<StockedItem *> *)values;

@end

NS_ASSUME_NONNULL_END
