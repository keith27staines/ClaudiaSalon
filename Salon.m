//
//  Salon.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 22/01/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

#import "Salon.h"
#import "Account.h"
#import "AccountingPaymentGroup.h"
#import "Customer.h"
#import "Employee.h"
#import "PaymentCategory.h"
#import "Role.h"
#import "ServiceCategory.h"
#import "Salon.h"
#import "LastUpdatedBy.h"
#import "OpeningHoursWeekTemplate.h"
#import "OpeningHoursDayTemplate.h"
#import "IntervalDuringDay.h"
#import "NSDate+AMCDate.h"
#import "Account.h"
#import "PaymentCategory.h"

@implementation Salon

// Insert code here to add functionality to your managed object subclass

+(Salon * _Nullable)defaultSalon:(NSManagedObjectContext * _Nonnull)moc {
    Salon * salon = nil;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Salon" inManagedObjectContext:moc];
    [fetchRequest setEntity:entity];
    
    NSError *error = nil;
    NSArray *fetchedObjects = [moc executeFetchRequest:fetchRequest error:&error];
    if (fetchedObjects.count == 0) { return nil; }
    NSAssert(fetchedObjects.count == 1, @"Only one salon was expected");
    salon = (Salon*)fetchedObjects[0];
    if (salon.firstDayOfWeek.integerValue == 0) {
        salon.firstDayOfWeek = @(1);// I, developer, messed up - days of week are 1-based!
    }
    [salon addDefaultPaymentCategories];
    return salon;
}

+(Salon*)salonWithMoc:(NSManagedObjectContext*)moc {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Salon" inManagedObjectContext:moc];
    [fetchRequest setEntity:entity];
    
    NSError *error = nil;
    NSArray *fetchedObjects = [moc executeFetchRequest:fetchRequest error:&error];
    Salon * salon = nil;
    if (fetchedObjects.count == 0) {
        salon = [NSEntityDescription insertNewObjectForEntityForName:@"Salon" inManagedObjectContext:moc];
        salon.salonName = @"New Salon";
        salon.firstDayOfTrading = [NSDate date];
        salon.firstDayOfWeek = @(1);
        salon.startOfAccountingYear = salon.firstDayOfTrading;
        [salon addOpeningHoursWeekTemplate];
        [salon addDefaultAccounts];
    } else {
        salon = fetchedObjects[0];
        if (salon.firstDayOfWeek.integerValue == 0) {
            salon.firstDayOfWeek = @(1);// I, developer, messed up - days of week are 1-based!
        }
    }
    [salon addDefaultPaymentCategories];
    return salon;
}
-(void)addOpeningHoursWeekTemplate {
    OpeningHoursWeekTemplate * openingHoursWeekTemplate = [NSEntityDescription insertNewObjectForEntityForName:@"OpeningHoursWeekTemplate" inManagedObjectContext:self.managedObjectContext];
    openingHoursWeekTemplate.salon = self;
    for (int i = 0; i < 7; i++) {
        NSDate * day = [[[NSDate date] firstDayOfSalonWeek:self] dateByAddingTimeInterval:i*24*3600];
        OpeningHoursDayTemplate * openingHours = [NSEntityDescription insertNewObjectForEntityForName:@"OpeningHoursDayTemplate" inManagedObjectContext:self.managedObjectContext];
        openingHours.dayName = [day stringNamingDayOfWeek];
        IntervalDuringDay * interval = [NSEntityDescription insertNewObjectForEntityForName:@"IntervalDuringDay" inManagedObjectContext:self.managedObjectContext];
        interval.startTime = @(10 * 3600);
        interval.endTime = @(19 * 3600);
        openingHours.intervalDuringDay = interval;
        [openingHoursWeekTemplate addDayTemplatesObject:openingHours];
    }
}
-(void)addDefaultAccounts {
    NSArray * accounts = [Account allObjectsWithMoc:self.managedObjectContext];
    if (accounts.count == 0) {
        self.tillAccount = [Account newObjectWithMoc:self.managedObjectContext];
        self.cardPaymentAccount = [Account newObjectWithMoc:self.managedObjectContext];
        self.primaryBankAccount = [Account newObjectWithMoc:self.managedObjectContext];
        self.tillAccount.friendlyName = @"Till Account";
        self.cardPaymentAccount.friendlyName = @"Card Payment Account";
        self.primaryBankAccount.friendlyName = @"Primary bank account";
    }
}
-(void)addDefaultPaymentCategories {
    if (!self.defaultPaymentCategoryForSales) {
        self.defaultPaymentCategoryForSales = [PaymentCategory newObjectWithMoc:self.managedObjectContext];
        self.defaultPaymentCategoryForSales.categoryName = @"Sales";
        self.defaultPaymentCategoryForSales.isManagersBudgetItem = @NO;
        self.defaultPaymentCategoryForSales.isSale = @YES;
        self.defaultPaymentCategoryForSales.fullDescription = @"Payments from sales";
    }
    if (!self.defaultPaymentCategoryForPayments) {
        self.defaultPaymentCategoryForPayments = [PaymentCategory newObjectWithMoc:self.managedObjectContext];
        self.defaultPaymentCategoryForPayments.categoryName = @"Awaiting categorisation";
        self.defaultPaymentCategoryForPayments.isManagersBudgetItem = @NO;
        self.defaultPaymentCategoryForPayments.isDefault = @YES;
        self.defaultPaymentCategoryForPayments.fullDescription = @"These payments are waiting to be assigned to the correct category";
    }
    if (!self.defaultPaymentCategoryForMoneyTransfers) {
        self.defaultPaymentCategoryForMoneyTransfers = [PaymentCategory newObjectWithMoc:self.managedObjectContext];
        self.defaultPaymentCategoryForMoneyTransfers.categoryName = @"Money transfer";
        self.defaultPaymentCategoryForMoneyTransfers.isManagersBudgetItem = @NO;
        self.defaultPaymentCategoryForMoneyTransfers.isSale = @YES;
        self.defaultPaymentCategoryForMoneyTransfers.fullDescription = @"Transfer money between salon accounts";
    }
    if (!self.defaultPaymentCategoryForWages) {
        self.defaultPaymentCategoryForWages = [PaymentCategory newObjectWithMoc:self.managedObjectContext];
        self.defaultPaymentCategoryForWages.categoryName = @"Wages";
        self.defaultPaymentCategoryForWages.isManagersBudgetItem = @NO;
        self.defaultPaymentCategoryForWages.isSalary = @YES;
        self.defaultPaymentCategoryForWages.fullDescription = @"Remuneration for work or services provided by staff";
    }
}


@end
