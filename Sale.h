//
//  Sale.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 17/01/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Account, Appointment, Customer, Note, Payment, SaleItem;

NS_ASSUME_NONNULL_BEGIN

@interface Sale : NSManagedObject

// Insert code here to declare functionality of your managed object subclass

@end

NS_ASSUME_NONNULL_END

#import "Sale+CoreDataProperties.h"
