//
//  Sale.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 26/04/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "Sale.h"
#import "Account.h"
#import "Appointment.h"
#import "Customer.h"
#import "Note.h"
#import "Payment.h"
#import "SaleItem.h"


@implementation Sale

@dynamic actualCharge;
@dynamic amountGivenByCustomer;
@dynamic changeGiven;
@dynamic chargeAfterIndividualDiscounts;
@dynamic createdDate;
@dynamic discountAmount;
@dynamic discountType;
@dynamic hidden;
@dynamic isQuote;
@dynamic lastUpdatedDate;
@dynamic nominalCharge;
@dynamic voided;
@dynamic account;
@dynamic customer;
@dynamic fromAppointment;
@dynamic notes;
@dynamic payments;
@dynamic saleItem;

@end
