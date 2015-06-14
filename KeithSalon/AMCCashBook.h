//
//  AMCCashBook.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 17/03/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//
@class Salon,Account, AMCAccountStatementItem;
#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface AMCCashBook : NSObject

-(instancetype)initWithSalon:(Salon*)salon
        managedObjectContext:(NSManagedObjectContext*)moc
                     account:(Account*)account
              statementItems:(NSArray*)statementItems
                    firstDay:(NSDate*)firstDay
                     lastDay:(NSDate*)lastDay
       balanceBroughtForward:(double)balanceBroughtForward
              balancePerBank:(double)balancePerBank;

@property (copy, readonly, nonatomic) NSDate * firstDay;
@property (copy, readonly, nonatomic) NSDate * lastDay;
@property (readonly, nonatomic) Salon * Salon;
@property (readonly, nonatomic) Account * account;

@property (readonly, nonatomic) double balanceBroughtForward;
@property (readonly, nonatomic) double receipts;
@property (readonly, nonatomic) double expenses;
@property (readonly, nonatomic) double balancePerBank;
@property (copy, readonly, nonatomic) NSMutableArray * statementItems;
@property (copy, readonly, nonatomic) NSArray * incomeHeaders;
@property (copy, readonly, nonatomic) NSArray * expenditureHeaders;
@property (copy, readonly, nonatomic) NSMutableArray * incomeDictionaries;
@property (copy, readonly, nonatomic) NSMutableArray * expenditureDictionaries;
@property (copy, readonly, nonatomic) NSMutableDictionary * incomeTotals;
@property (copy, readonly, nonatomic) NSMutableDictionary * expenditureTotals;
@property (readonly, nonatomic) double totalIncome;
@property (readonly, nonatomic) double totalExpenses;
@property (readonly, nonatomic) double total;
@property (readonly, nonatomic) double difference;

-(BOOL)writeToFile:(NSString*)filename error:(NSError**)error;

@end
