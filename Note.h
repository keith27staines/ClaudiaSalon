//
//  Note.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 25/01/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Appointment, Customer, Employee, Payment, Product, Sale, SaleItem, Service, ServiceCategory, StockedBrand, StockedCategory, StockedItem, StockedProduct;

NS_ASSUME_NONNULL_BEGIN

@interface Note: NSManagedObject
+(id)newObjectWithMoc:(NSManagedObjectContext*)moc;
+(NSArray*)allObjectsWithMoc:(NSManagedObjectContext*)moc;
@end

NS_ASSUME_NONNULL_END

#import "Note+CoreDataProperties.h"
