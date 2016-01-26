//
//  Payment.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 25/01/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Account, Note, PaymentCategory, RecurringItem, Sale, SaleItem, ShoppingList, WorkRecord;

NS_ASSUME_NONNULL_BEGIN

@interface Payment : NSManagedObject

// Insert code here to declare functionality of your managed object subclass

@end

NS_ASSUME_NONNULL_END

#import "Payment+CoreDataProperties.h"
