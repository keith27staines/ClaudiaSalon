//
//  ShoppingList+CoreDataProperties.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 26/01/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "ShoppingList.h"

NS_ASSUME_NONNULL_BEGIN

@interface ShoppingList (CoreDataProperties)

@property (nullable, nonatomic, retain) NSDate *createdDate;
@property (nullable, nonatomic, retain) NSDate *shoppingDate;
@property (nullable, nonatomic, retain) NSString *status;
@property (nullable, nonatomic, retain) NSSet<ShoppingListItem *> *items;
@property (nullable, nonatomic, retain) Payment *payment;

@end

@interface ShoppingList (CoreDataGeneratedAccessors)

- (void)addItemsObject:(ShoppingListItem *)value;
- (void)removeItemsObject:(ShoppingListItem *)value;
- (void)addItems:(NSSet<ShoppingListItem *> *)values;
- (void)removeItems:(NSSet<ShoppingListItem *> *)values;

@end

NS_ASSUME_NONNULL_END
