//
//  SaleItem.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 25/01/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Employee, Note, Payment, Sale, Service;

NS_ASSUME_NONNULL_BEGIN

@interface SaleItem : NSManagedObject

// Insert code here to declare functionality of your managed object subclass

@end

NS_ASSUME_NONNULL_END

#import "SaleItem+CoreDataProperties.h"
