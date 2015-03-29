//
//  StockedProduct.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 28/03/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Note, ShoppingListItem, StockedBrand, StockedCategory, StockedItem;

@interface StockedProduct : NSManagedObject

@property (nonatomic, retain) NSString * barcode;
@property (nonatomic, retain) NSString * code;
@property (nonatomic, retain) NSDate * createdDate;
@property (nonatomic, retain) NSNumber * currentStockLevel;
@property (nonatomic, retain) NSNumber * isConsumable;
@property (nonatomic, retain) NSDate * lastUpdatedDate;
@property (nonatomic, retain) NSNumber * minimumStockTrigger;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * numberToBuy;
@property (nonatomic, retain) NSSet *notes;
@property (nonatomic, retain) NSSet *shoppingListItems;
@property (nonatomic, retain) StockedBrand *stockedBrand;
@property (nonatomic, retain) StockedCategory *stockedCategory;
@property (nonatomic, retain) NSSet *stockedItems;
@end

@interface StockedProduct (CoreDataGeneratedAccessors)

- (void)addNotesObject:(Note *)value;
- (void)removeNotesObject:(Note *)value;
- (void)addNotes:(NSSet *)values;
- (void)removeNotes:(NSSet *)values;

- (void)addShoppingListItemsObject:(ShoppingListItem *)value;
- (void)removeShoppingListItemsObject:(ShoppingListItem *)value;
- (void)addShoppingListItems:(NSSet *)values;
- (void)removeShoppingListItems:(NSSet *)values;

- (void)addStockedItemsObject:(StockedItem *)value;
- (void)removeStockedItemsObject:(StockedItem *)value;
- (void)addStockedItems:(NSSet *)values;
- (void)removeStockedItems:(NSSet *)values;

@end
