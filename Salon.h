//
//  Salon.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 28/03/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Account, Employee, OpeningHoursWeekTemplate;

@interface Salon : NSManagedObject

@property (nonatomic, retain) NSString * addressLine1;
@property (nonatomic, retain) NSString * addressLine2;
@property (nonatomic, retain) NSDate * startOfAccountingYear;
@property (nonatomic, retain) NSDate * firstDayOfTrading;
@property (nonatomic, retain) NSString * fullDescription;
@property (nonatomic, retain) NSString * phone;
@property (nonatomic, retain) NSString * serviceEmail;
@property (nonatomic, retain) NSString * postcode;
@property (nonatomic, retain) NSString * purpose;
@property (nonatomic, retain) NSString * salonName;
@property (nonatomic, retain) NSNumber * firstDayOfWeek;
@property (nonatomic, retain) Account *cardPaymentAccount;
@property (nonatomic, retain) Employee *manager;
@property (nonatomic, retain) Account *primaryBankAccount;
@property (nonatomic, retain) Account *tillAccount;
@property (nonatomic, retain) OpeningHoursWeekTemplate * openingHoursWeekTemplate;

@end
