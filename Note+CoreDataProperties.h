//
//  Note+CoreDataProperties.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 26/01/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Note.h"

NS_ASSUME_NONNULL_BEGIN

@interface Note (CoreDataProperties)

@property (nullable, nonatomic, retain) NSDate *createdDate;
@property (nullable, nonatomic, retain) NSNumber *isAuditNote;
@property (nullable, nonatomic, retain) NSDate *lastUpdatedDate;
@property (nullable, nonatomic, retain) NSString *text;
@property (nullable, nonatomic, retain) NSString *title;
@property (nullable, nonatomic, retain) Appointment *appointment;
@property (nullable, nonatomic, retain) Employee *createdBy;
@property (nullable, nonatomic, retain) Customer *customer;
@property (nullable, nonatomic, retain) Employee *employee;
@property (nullable, nonatomic, retain) Payment *payment;
@property (nullable, nonatomic, retain) Product *product;
@property (nullable, nonatomic, retain) Sale *sale;
@property (nullable, nonatomic, retain) SaleItem *saleItem;
@property (nullable, nonatomic, retain) Service *service;
@property (nullable, nonatomic, retain) ServiceCategory *serviceCategory;
@property (nullable, nonatomic, retain) StockedBrand *stockedBrand;
@property (nullable, nonatomic, retain) StockedCategory *stockedCategory;
@property (nullable, nonatomic, retain) StockedItem *stockedItem;
@property (nullable, nonatomic, retain) StockedProduct *stockedType;

@end

NS_ASSUME_NONNULL_END
