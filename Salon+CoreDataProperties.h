//
//  Salon+CoreDataProperties.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 24/02/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Salon.h"

NS_ASSUME_NONNULL_BEGIN

@interface Salon (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *addressLine1;
@property (nullable, nonatomic, retain) NSString *addressLine2;
@property (nullable, nonatomic, retain) NSData *bqMetadata;
@property (nullable, nonatomic, retain) NSNumber *bqNeedsCoreDataExport;
@property (nullable, nonatomic, retain) NSDate *firstDayOfTrading;
@property (nullable, nonatomic, retain) NSNumber *firstDayOfWeek;
@property (nullable, nonatomic, retain) NSString *fullDescription;
@property (nullable, nonatomic, retain) NSString *phone;
@property (nullable, nonatomic, retain) NSString *postcode;
@property (nullable, nonatomic, retain) NSString *purpose;
@property (nullable, nonatomic, retain) NSString *salonName;
@property (nullable, nonatomic, retain) NSString *serviceEmail;
@property (nullable, nonatomic, retain) NSDate *startOfAccountingYear;
@property (nullable, nonatomic, retain) NSString *bqCloudID;
@property (nullable, nonatomic, retain) Role *accountantRole;
@property (nullable, nonatomic, retain) Customer *anonymousCustomer;
@property (nullable, nonatomic, retain) Role *basicUserRole;
@property (nullable, nonatomic, retain) Account *cardPaymentAccount;
@property (nullable, nonatomic, retain) PaymentCategory *defaultPaymentCategoryForMoneyTransfers;
@property (nullable, nonatomic, retain) PaymentCategory *defaultPaymentCategoryForPayments;
@property (nullable, nonatomic, retain) PaymentCategory *defaultPaymentCategoryForSales;
@property (nullable, nonatomic, retain) PaymentCategory *defaultPaymentCategoryForWages;
@property (nullable, nonatomic, retain) Role *devSupportRole;
@property (nullable, nonatomic, retain) AccountingPaymentGroup *expenditureOtherGroup;
@property (nullable, nonatomic, retain) AccountingPaymentGroup *incomeOtherGroup;
@property (nullable, nonatomic, retain) Employee *manager;
@property (nullable, nonatomic, retain) Role *managerRole;
@property (nullable, nonatomic, retain) OpeningHoursWeekTemplate *openingHoursWeekTemplate;
@property (nullable, nonatomic, retain) Account *primaryBankAccount;
@property (nullable, nonatomic, retain) Role *receptionistRole;
@property (nullable, nonatomic, retain) AccountingPaymentGroup *rootAccountingGroup;
@property (nullable, nonatomic, retain) AccountingPaymentGroup *rootExpenditureGroup;
@property (nullable, nonatomic, retain) AccountingPaymentGroup *rootIncomeGroup;
@property (nullable, nonatomic, retain) ServiceCategory *rootServiceCategory;
@property (nullable, nonatomic, retain) ServiceCategory *serviceCategories;
@property (nullable, nonatomic, retain) Role *systemAdminRole;
@property (nullable, nonatomic, retain) Role *systemRole;
@property (nullable, nonatomic, retain) Account *tillAccount;

@end

NS_ASSUME_NONNULL_END
