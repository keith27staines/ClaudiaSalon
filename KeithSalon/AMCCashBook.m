//
//  AMCCashBook.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 17/03/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "AMCCashBook.h"
#import "Salon+Methods.h"
#import "NSDate+AMCDate.h"
#import "AMCAccountStatementItem.h"
#import "Payment+Methods.h"
#import "PaymentCategory+Methods.h"
#import "AMCCashBookRootNode.h"
#import "Account+Methods.h"

@interface AMCCashBook()
{
    NSMutableArray * _incomeDictionaries;
    NSMutableArray * _expenditureDictionaries;
    NSMutableDictionary * _incomeTotals;
    NSMutableDictionary * _expenditureTotals;
    AMCCashBookRootNode * _cashbookRootNode;
}
@property (copy, nonatomic) NSDate * firstDay;
@property (copy, nonatomic) NSDate * lastDay;
@property (readwrite, nonatomic) Salon * salon;
@property (readwrite, nonatomic) Account * account;

@property (readwrite,nonatomic) double balanceBroughtForward;
@property (readwrite,nonatomic) double receipts;
@property (readwrite,nonatomic) double expenses;
@property (readwrite,nonatomic) double balancePerBank;
@property (readwrite,nonatomic) double difference;
@property (nonatomic) NSMutableArray * statementItems;
@property (copy, nonatomic) NSArray * incomeHeaders;
@property (copy, nonatomic) NSArray * expenditureHeaders;
@property (nonatomic) NSMutableArray * incomeDictionaries;
@property (nonatomic) NSMutableArray * expenditureDictionaries;
@property (copy,nonatomic) NSMutableDictionary * incomeTotals;
@property (copy,nonatomic) NSMutableDictionary * expenditureTotals;
@property (nonatomic) double totalIncome;
@property (nonatomic) double totalFeesOnIncomings;
@property (nonatomic) double totalExpenses;
@property (nonatomic) double totalFeeOnExpenses;
@property NSDate * startDate;
@property NSDate * endDate;
@property (readonly) AMCCashBookRootNode * cashbookRootNode;
@property NSManagedObjectContext * moc;
@end

@implementation AMCCashBook

-(instancetype)initWithSalon:(Salon*)salon
        managedObjectContext:(NSManagedObjectContext*)moc
                     account:(Account*)account
              statementItems:(NSArray*)statementItems
                    firstDay:(NSDate*)firstDay
                     lastDay:(NSDate*)lastDay
       balanceBroughtForward:(double)balanceBroughtForward
              balancePerBank:(double)balancePerBank {
    self = [super init];
    if (self) {
        self.moc = moc;
        self.salon = salon;
        self.account = account;
        self.statementItems = [statementItems mutableCopy];
        self.balanceBroughtForward = balanceBroughtForward;
        self.balancePerBank = balancePerBank;
        self.firstDay = firstDay;
        self.lastDay = lastDay;
        self.startDate = [firstDay beginningOfDay];
        self.endDate = [lastDay endOfDay];
        [self configureHeaders];
        [self analyse];
    }
    return self;
}
-(AMCCashBookRootNode *)cashbookRootNode {
    if (!_cashbookRootNode) {
        _cashbookRootNode = [[AMCCashBookRootNode alloc] initWithSalon:self.salon];
    }
    return _cashbookRootNode;
}

-(void)analyse {
    // seperate into income and expenditure...
    _incomeDictionaries = [NSMutableArray array];
    _expenditureDictionaries = [NSMutableArray array];
    for (AMCAccountStatementItem * item in self.statementItems) {
        NSDictionary * dictionary = [self dictionaryForStatementItem:item];
        if ([item.direction isEqualToString:kAMCPaymentDirectionIn]) {
            [_incomeDictionaries addObject:dictionary];
        } else {
            [_expenditureDictionaries addObject:dictionary];
        }
    }
    // Calculate income totals
    _incomeTotals = [self transactionDictionaryFromHeaders:self.incomeHeaders];
    for (NSDictionary * incomeDictionary in self.incomeDictionaries) {
        [self addTransaction:incomeDictionary toTotals:_incomeTotals];
    }
    // Calculate expenditure totals
    _expenditureTotals = [self transactionDictionaryFromHeaders:self.expenditureHeaders];
    for (NSDictionary * expenditureDictionary in self.expenditureDictionaries) {
        [self addTransaction:expenditureDictionary toTotals:_expenditureTotals];
    }
    [self formatTotalsDictionary:_incomeTotals];
    [self formatTotalsDictionary:_expenditureTotals];
    self.totalIncome = ((NSNumber*)self.incomeTotals[@"Total"]).doubleValue;
    self.totalExpenses = ((NSNumber*)self.expenditureTotals[@"Total"]).doubleValue;
}
-(double)total {
    return self.balanceBroughtForward + self.totalIncome - self.totalExpenses;
}
-(double)difference {
    return self.total - self.balancePerBank;
}
-(void)formatTotalsDictionary:(NSMutableDictionary*)totalsDictionary {
    NSNumberFormatter * nf = [[NSNumberFormatter alloc] init];
    nf.minimumFractionDigits = 2;
    nf.maximumFractionDigits = 2;
    nf.minimumIntegerDigits = 1;
    NSArray * headers = [totalsDictionary allKeys];
    for (NSString * header in headers) {
        // Only format columns that contain sums of money
        if ([self isHeaderForMoneyColumn:header]) {
            // heading is for a money column
            NSNumber * number = totalsDictionary[header];
            totalsDictionary[header] = [nf stringFromNumber:number];
        }
    }
}
-(void)addTransaction:(NSDictionary*)transactionDictionary toTotals:(NSMutableDictionary*)totalsDictionary {
    for (NSString * header in [totalsDictionary allKeys]) {
        if ([self isHeaderForMoneyColumn:header]) {
            // Column is not a money column so don't sum it
            // Column is a money column so sum it
            NSNumber * totalNumber = totalsDictionary[header];
            double total = round(totalNumber.doubleValue * 100);
            NSNumber * addNumber = transactionDictionary[header];
            total += round(addNumber.doubleValue * 100);
            total /= 100.0;
            totalsDictionary[header] = @(total);
        } else {
            totalsDictionary[header] = @"";
        }
    }
}
-(BOOL)isHeaderForMoneyColumn:(NSString*)header {
    if ([header isEqualToString:@"Date"] ||
        [header isEqualToString:@"Details"] ||
        [header isEqualToString:@"Payee/Payer"]) {
        return NO;
    } else {
        return YES;
    }
}
-(NSMutableDictionary*)transactionDictionaryFromHeaders:(NSArray*)headers {
    NSMutableDictionary * totals = [NSMutableDictionary dictionary];
    for (NSString * key in headers) {
        totals[key] = @(0);
    }
    return totals;
}
-(void)configureHeaders {
    NSArray * commonHeaders = @[@"Date",@"Payee/Payer",@"Details",@"Total",@"Fee"];
    NSArray * incomeSpecificHeaders = [self.cashbookRootNode.incomeRoot childNodeNames];
    NSArray * expenditureSpecificHeaders = [self.cashbookRootNode.expenditureRoot childNodeNames];
    self.incomeHeaders = [commonHeaders arrayByAddingObjectsFromArray:incomeSpecificHeaders];
    self.expenditureHeaders = [commonHeaders arrayByAddingObjectsFromArray:expenditureSpecificHeaders];
}
-(NSDictionary*)dictionaryForStatementItem:(AMCAccountStatementItem*)item {
    NSDateFormatter * df = [[NSDateFormatter alloc] init];
    df.dateStyle = NSDateFormatterShortStyle;
    df.timeStyle = NSDateFormatterNoStyle;
    NSNumberFormatter * nf = [[NSNumberFormatter alloc] init];
    nf.minimumFractionDigits = 2;
    nf.maximumFractionDigits = 2;
    nf.minimumIntegerDigits = 1;
    NSMutableDictionary * dictionary = [@{@"Date":[df stringFromDate:item.date],
                                          @"Payee/Payer":item.payeeName,
                                          @"Details":item.note,
                                          @"Total":[nf stringFromNumber:@(fabs(item.amountNet))],
                                          @"Fee":[nf stringFromNumber:@(fabs(item.transactionFee))]} mutableCopy];
    NSString * heading = [self headingFromStatementItem:item];
    if ([heading isEqualToString:@"Other" ] && item.isPayment) {
        Payment * payment = item.payment;
        NSString * details = @"";
        if (payment.paymentCategory) {
            details = [payment.paymentCategory.categoryName stringByAppendingString:@": "];
        } else {
            NSLog(@"Category should be set on payment %@",payment);
        }
        details = [details stringByAppendingString:item.note];
        dictionary[@"Details"] = details;
    }
    dictionary[heading] = [nf stringFromNumber:@(fabs(item.amountGross))];
    return [dictionary copy];
}
-(NSString*)headingFromStatementItem:(AMCAccountStatementItem*)item {
    AMCTreeNode * directionNode;
    if (item.isPayment) {
        // item is a payment
        Payment * payment = item.payment;
        // Payments can be either income or expenditure, depending on direction
        if (payment.isIncoming) {
            // payment is income
            directionNode = self.cashbookRootNode.incomeRoot;
        } else {
            // payment is expenditure
            directionNode = self.cashbookRootNode.expenditureRoot;
        }
        NSString * categoryName = payment.paymentCategory.categoryName;
        AMCTreeNode * leaf = [directionNode leafWithName:categoryName];
        if (leaf) {
            return leaf.parentNode.name;
        }
        return @"Other";
    } else {
        // item is a sale, and sales are always income in the Sales category
        return @"Sales";
    }
}
-(BOOL)writeToFile:(NSString*)filename error:(NSError**)error {
    NSNumberFormatter * nf = [[NSNumberFormatter alloc] init];
    nf.numberStyle = NSNumberFormatterDecimalStyle;
    nf.minimumFractionDigits = 2;
    nf.maximumFractionDigits = 2;
    nf.hasThousandSeparators = NO;
    NSDateFormatter * df = [[NSDateFormatter alloc] init];
    df.dateStyle = NSDateFormatterMediumStyle;
    df.timeStyle = NSDateFormatterNoStyle;
    NSMutableString *csv = [NSMutableString stringWithString:@""];
    [csv appendFormat:@"Irina Enterprises LTD - Cashbook for %@ account\n",self.account.friendlyName];
    [csv appendFormat:@"start:%@,end:%@\n",[df stringFromDate:self.startDate],[df stringFromDate:self.endDate]];
    [csv appendFormat:@"\n"];
    [csv appendFormat:@"Bank Rec\n"];
    [csv appendFormat:@"Brought forward,%@\n",[nf stringFromNumber:@(self.balanceBroughtForward)]];
    [csv appendFormat:@"Add receipts,%@\n",[nf stringFromNumber:@(self.totalIncome)]];
    [csv appendFormat:@"Less expenses,%@\n",[nf stringFromNumber:@(self.totalExpenses)]];
    [csv appendFormat:@"Total,%@\n",[nf stringFromNumber:@(self.total)]];
    [csv appendFormat:@"Per statement,%@\n",[nf stringFromNumber:@(self.balancePerBank)]];
    [csv appendFormat:@"Difference,%@\n",[nf stringFromNumber:@(self.difference)]];
    [csv appendFormat:@"\n"];
    [csv appendFormat:@"\n"];
    [csv appendFormat:@"\n"];
    [csv appendFormat:@"Income\n"];
    [csv appendString:[self stringFromHeadersArray:self.incomeHeaders]];
    [csv appendString:[self tableStringForTable:@"INCOME"]];
    [csv appendFormat:@"\n"];
    [csv appendFormat:@"\n"];
    [csv appendFormat:@"Expenditure\n"];
    [csv appendString:[self stringFromHeadersArray:self.expenditureHeaders]];
    [csv appendString:[self tableStringForTable:@"EXPENDITURE"]];
    return [csv writeToFile:filename atomically:YES encoding:NSUTF8StringEncoding error:error];
}
-(NSString*)tableStringForTable:(NSString*)table {
    NSArray * transactionDictionaries = nil;
    if ([table isEqualToString:@"INCOME"]) {
        transactionDictionaries = self.incomeDictionaries;
    } else {
        transactionDictionaries = self.expenditureDictionaries;
    }
    NSMutableString * csv = [NSMutableString stringWithString:@""];
    for (NSInteger row = 0; row < transactionDictionaries.count+1; row++) {
        [csv appendString:[self rowStringForTable:table row:row]];
    }
    return csv;
}
-(NSString*)rowStringForTable:(NSString*)tableName row:(NSInteger)row {
    NSMutableString * csv = [NSMutableString stringWithString:@""];
    NSArray * headers;
    if ([tableName isEqualToString:@"INCOME"]) {
        headers = self.incomeHeaders;
    } else {
        headers = self.expenditureHeaders;
    }
    for (NSString * header in headers) {
        NSString * string = [self cellStringForTable:tableName columnHeader:header row:row];
        [csv appendString:string];
    }
    return [csv stringByAppendingString:@"\n"];
}
-(NSString*)cellStringForTable:(NSString*)table columnHeader:(NSString*)header row:(NSInteger)row {
    NSNumberFormatter * nf = [[NSNumberFormatter alloc] init];
    nf.numberStyle = NSNumberFormatterDecimalStyle;
    nf.minimumFractionDigits = 2;
    nf.maximumFractionDigits = 2;
    nf.hasThousandSeparators = NO;
    NSDateFormatter * df = [[NSDateFormatter alloc] init];
    df.dateStyle = NSDateFormatterMediumStyle;
    df.timeStyle = NSDateFormatterNoStyle;
    NSDictionary * dictionary = nil;
    if ([table isEqualToString:@"INCOME"]) {
        if (row < self.incomeDictionaries.count) {
            dictionary = self.incomeDictionaries[row];
        } else {
            dictionary = self.incomeTotals;
        }
    } else {
        if (row < self.expenditureDictionaries.count) {
            dictionary = self.expenditureDictionaries[row];
        } else {
            dictionary = self.expenditureTotals;
        }
    }
    id value = dictionary[header];
    NSString * string = nil;
    if ([value isKindOfClass:[NSDate class]]) {
        string = [df stringFromDate:value];
    }
    if ([value isKindOfClass:[NSString class]]) {
        string = value;
    }
    if ([value isKindOfClass:[NSNumber class]]) {
        string = [nf stringFromNumber:value];
    }
    if (!string) {
        string = @"";
    }
    string = [string stringByReplacingOccurrencesOfString:@"," withString:@" "];
    return [string stringByAppendingString:@","];
}
-(NSString*)stringFromHeadersArray:(NSArray*)headers {
    NSMutableString * csv = [NSMutableString stringWithString:@""];
    for (NSString * heading in headers) {
        [csv appendFormat:@"%@,",heading];
    }
    [csv appendString:@"\n"];
    return csv;
}
@end
