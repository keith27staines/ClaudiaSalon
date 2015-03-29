//
//  Note.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 28/03/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Appointment, Customer, Employee, Payment, Product, Sale, SaleItem, Service, ServiceCategory, StockedBrand, StockedCategory, StockedItem, StockedProduct;

@interface Note : NSManagedObject

@property (nonatomic, retain) NSDate * createdDate;
@property (nonatomic, retain) NSNumber * isAuditNote;
@property (nonatomic, retain) NSDate * lastUpdatedDate;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) Appointment *appointment;
@property (nonatomic, retain) Employee *createdBy;
@property (nonatomic, retain) Customer *customer;
@property (nonatomic, retain) Employee *employee;
@property (nonatomic, retain) Payment *payment;
@property (nonatomic, retain) Product *product;
@property (nonatomic, retain) Sale *sale;
@property (nonatomic, retain) SaleItem *saleItem;
@property (nonatomic, retain) Service *service;
@property (nonatomic, retain) ServiceCategory *serviceCategory;
@property (nonatomic, retain) StockedBrand *stockedBrand;
@property (nonatomic, retain) StockedCategory *stockedCategory;
@property (nonatomic, retain) StockedItem *stockedItem;
@property (nonatomic, retain) StockedProduct *stockedType;

@end
