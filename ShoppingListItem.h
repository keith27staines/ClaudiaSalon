//
//  ShoppingListItem.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 28/03/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ShoppingList, StockedProduct;

@interface ShoppingListItem : NSManagedObject

@property (nonatomic, retain) NSNumber * numberActuallyPurchased;
@property (nonatomic, retain) NSNumber * numberToPurchase;
@property (nonatomic, retain) ShoppingList *shoppingList;
@property (nonatomic, retain) StockedProduct *stockedProduct;

@end
