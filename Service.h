//
//  Service.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 31/03/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Employee, Note, Product, SaleItem, ServiceCategory;

@interface Service : NSManagedObject

@property (nonatomic, retain) NSDate * createdDate;
@property (nonatomic, retain) NSNumber * deluxe;
@property (nonatomic, retain) NSNumber * expectedTimeRequired;
@property (nonatomic, retain) NSNumber * hairLength;
@property (nonatomic, retain) NSNumber * hidden;
@property (nonatomic, retain) NSDate * lastUpdatedDate;
@property (nonatomic, retain) NSNumber * maximumCharge;
@property (nonatomic, retain) NSNumber * minimumCharge;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * nominalCharge;
@property (nonatomic, retain) NSNumber * priceNegotiable;
@property (nonatomic, retain) NSNumber * selectable;
@property (nonatomic, retain) NSSet *canBeDoneBy;
@property (nonatomic, retain) NSSet *notes;
@property (nonatomic, retain) NSSet *product;
@property (nonatomic, retain) NSSet *saleItem;
@property (nonatomic, retain) ServiceCategory *serviceCategory;
@end

@interface Service (CoreDataGeneratedAccessors)

- (void)addCanBeDoneByObject:(Employee *)value;
- (void)removeCanBeDoneByObject:(Employee *)value;
- (void)addCanBeDoneBy:(NSSet *)values;
- (void)removeCanBeDoneBy:(NSSet *)values;

- (void)addNotesObject:(Note *)value;
- (void)removeNotesObject:(Note *)value;
- (void)addNotes:(NSSet *)values;
- (void)removeNotes:(NSSet *)values;

- (void)addProductObject:(Product *)value;
- (void)removeProductObject:(Product *)value;
- (void)addProduct:(NSSet *)values;
- (void)removeProduct:(NSSet *)values;

- (void)addSaleItemObject:(SaleItem *)value;
- (void)removeSaleItemObject:(SaleItem *)value;
- (void)addSaleItem:(NSSet *)values;
- (void)removeSaleItem:(NSSet *)values;

@end
