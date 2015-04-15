//
//  Salon.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 15/04/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Account, Employee, OpeningHoursWeekTemplate, PaymentCategory;

@interface Salon : NSManagedObject

@property (nonatomic, retain) NSString * addressLine1;
@property (nonatomic, retain) NSString * addressLine2;
@property (nonatomic, retain) NSDate * firstDayOfTrading;
@property (nonatomic, retain) NSNumber * firstDayOfWeek;
@property (nonatomic, retain) NSString * fullDescription;
@property (nonatomic, retain) NSString * phone;
@property (nonatomic, retain) NSString * postcode;
@property (nonatomic, retain) NSString * purpose;
@property (nonatomic, retain) NSString * salonName;
@property (nonatomic, retain) NSString * serviceEmail;
@property (nonatomic, retain) NSDate * startOfAccountingYear;
@property (nonatomic, retain) Account *cardPaymentAccount;
@property (nonatomic, retain) Employee *manager;
@property (nonatomic, retain) OpeningHoursWeekTemplate *openingHoursWeekTemplate;
@property (nonatomic, retain) Account *primaryBankAccount;
@property (nonatomic, retain) Account *tillAccount;
@property (nonatomic, retain) PaymentCategory *defaultPaymentCategory;

@end
