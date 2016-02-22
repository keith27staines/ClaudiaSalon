//
//  SaleItem.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 25/01/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "AMCObjectWithNotesProtocol.h"
@class Employee, Note, Payment, Sale, Service;

NS_ASSUME_NONNULL_BEGIN

@interface SaleItem : NSManagedObject <AMCObjectWithNotesProtocol>
+(id)newObjectWithMoc:(NSManagedObjectContext*)moc;
+(NSArray*)allObjectsWithMoc:(NSManagedObjectContext*)moc;
+(void)markSaleItemsForExportInMoc:(NSManagedObjectContext*)parentMoc saleItemIDs:(NSSet*)saleItemIDs;
-(void)updatePrice;
-(double)discountAmount;
-(void)convertToDiscountVersion2;
@end

NS_ASSUME_NONNULL_END

#import "SaleItem+CoreDataProperties.h"
