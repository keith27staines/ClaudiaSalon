//
//  ShoppingList.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 28/03/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Payment, ShoppingListItem;

@interface ShoppingList : NSManagedObject

@property (nonatomic, retain) NSDate * createdDate;
@property (nonatomic, retain) NSDate * shoppingDate;
@property (nonatomic, retain) NSString * status;
@property (nonatomic, retain) NSSet *items;
@property (nonatomic, retain) Payment *payment;
@end

@interface ShoppingList (CoreDataGeneratedAccessors)

- (void)addItemsObject:(ShoppingListItem *)value;
- (void)removeItemsObject:(ShoppingListItem *)value;
- (void)addItems:(NSSet *)values;
- (void)removeItems:(NSSet *)values;

@end
