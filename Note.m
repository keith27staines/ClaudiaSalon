//
//  Note.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 19/02/2015.
//  Copyright (c) 2015 Keith Staines. All rights reserved.
//

#import "Note.h"
#import "Appointment.h"
#import "Customer.h"
#import "Employee.h"
#import "Payment.h"
#import "Product.h"
#import "Sale.h"
#import "SaleItem.h"
#import "Service.h"
#import "ServiceCategory.h"
#import "StockedBrand.h"
#import "StockedCategory.h"
#import "StockedItem.h"
#import "StockedProduct.h"


@implementation Note

@dynamic createdDate;
@dynamic isAuditNote;
@dynamic lastUpdatedDate;
@dynamic text;
@dynamic title;
@dynamic appointment;
@dynamic createdBy;
@dynamic customer;
@dynamic employee;
@dynamic payment;
@dynamic product;
@dynamic sale;
@dynamic saleItem;
@dynamic service;
@dynamic serviceCategory;
@dynamic stockedBrand;
@dynamic stockedCategory;
@dynamic stockedItem;
@dynamic stockedType;

@end
