//
//  ShoppingListItem+CoreDataProperties.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 26/01/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "ShoppingListItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface ShoppingListItem (CoreDataProperties)

@property (nullable, nonatomic, retain) NSNumber *numberActuallyPurchased;
@property (nullable, nonatomic, retain) NSNumber *numberToPurchase;
@property (nullable, nonatomic, retain) ShoppingList *shoppingList;
@property (nullable, nonatomic, retain) StockedProduct *stockedProduct;

@end

NS_ASSUME_NONNULL_END
