//
//  Salon.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 23/06/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Account, AccountingPaymentGroup, Customer, Employee, OpeningHoursWeekTemplate, PaymentCategory, Role, ServiceCategory;

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
@property (nonatomic, retain) Customer *anonymousCustomer;
@property (nonatomic, retain) Account *cardPaymentAccount;
@property (nonatomic, retain) PaymentCategory *defaultPaymentCategoryForMoneyTransfers;
@property (nonatomic, retain) PaymentCategory *defaultPaymentCategoryForPayments;
@property (nonatomic, retain) PaymentCategory *defaultPaymentCategoryForSales;
@property (nonatomic, retain) PaymentCategory *defaultPaymentCategoryForWages;
@property (nonatomic, retain) AccountingPaymentGroup *expenditureOtherGroup;
@property (nonatomic, retain) AccountingPaymentGroup *incomeOtherGroup;
@property (nonatomic, retain) Employee *manager;
@property (nonatomic, retain) OpeningHoursWeekTemplate *openingHoursWeekTemplate;
@property (nonatomic, retain) Account *primaryBankAccount;
@property (nonatomic, retain) AccountingPaymentGroup *rootAccountingGroup;
@property (nonatomic, retain) AccountingPaymentGroup *rootExpenditureGroup;
@property (nonatomic, retain) AccountingPaymentGroup *rootIncomeGroup;
@property (nonatomic, retain) ServiceCategory *rootServiceCategory;
@property (nonatomic, retain) ServiceCategory *serviceCategories;
@property (nonatomic, retain) Account *tillAccount;
@property (nonatomic, retain) Role *systemRole;
@property (nonatomic, retain) Role *devSupportRole;
@property (nonatomic, retain) Role *systemAdminRole;
@property (nonatomic, retain) Role *accountantRole;
@property (nonatomic, retain) Role *managerRole;
@property (nonatomic, retain) Role *basicUserRole;
@property (nonatomic, retain) Role *receptionistRole;

@end
