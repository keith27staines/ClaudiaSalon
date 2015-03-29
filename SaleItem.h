//
//  SaleItem.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 28/03/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Employee, Note, Payment, Sale, Service;

@interface SaleItem : NSManagedObject

@property (nonatomic, retain) NSNumber * actualCharge;
@property (nonatomic, retain) NSDate * createdDate;
@property (nonatomic, retain) NSNumber * discountType;
@property (nonatomic, retain) NSDate * lastUpdatedDate;
@property (nonatomic, retain) NSNumber * maximumCharge;
@property (nonatomic, retain) NSNumber * minimumCharge;
@property (nonatomic, retain) NSNumber * nominalCharge;
@property (nonatomic, retain) NSSet *notes;
@property (nonatomic, retain) Employee *performedBy;
@property (nonatomic, retain) Payment *refund;
@property (nonatomic, retain) Sale *sale;
@property (nonatomic, retain) Service *service;
@end

@interface SaleItem (CoreDataGeneratedAccessors)

- (void)addNotesObject:(Note *)value;
- (void)removeNotesObject:(Note *)value;
- (void)addNotes:(NSSet *)values;
- (void)removeNotes:(NSSet *)values;

@end
