//
//  AMCManagersBudgetWindowController.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 17/02/2015.
//  Copyright (c) 2015 Keith Staines. All rights reserved.
//

#import "AMCManagersBudgetWindowController.h"
#import "NSDate+AMCDate.h"
#import "Payment+Methods.h"
#import "Sale+Methods.h"
#import "PaymentCategory+Methods.h"
#import "PaymentCategory+Methods.h"
#import "Account+Methods.h"
#import "AMCConstants.h"

@interface AMCManagersBudgetWindowController () <NSTableViewDataSource, NSTableViewDelegate>
{
    NSDate * _startDate;
    NSArray * _payments;
    NSArray * _sales;
}
@property (weak) IBOutlet NSTableView *overviewTable;
@property (weak) IBOutlet NSTableView *selectedWeekTable;
@property (weak) IBOutlet NSTextField *title;
@property (weak) IBOutlet NSTextField *overviewSpendingSinceLabel;
@property (weak) IBOutlet NSTextField *totalSalesLabel;
@property (weak) IBOutlet NSTextField *totalSpendLabel;
@property (weak) IBOutlet NSTextField *managersSpendLabel;
@property (weak) IBOutlet NSTextField *rentAndBillsLabel;
@property (weak) IBOutlet NSTextField *salesTargetLabel;
@property (weak) IBOutlet NSTextField *amountRemainingInManagersBudgetLabel;

@property (weak) IBOutlet NSTextField *spendingThisWeekLabel;

@property (weak) IBOutlet NSTextField *salesThisWeekLabel;

@property (weak) IBOutlet NSTextField *spendThisWeekLabel;
@property (weak) IBOutlet NSTextField *managersSpendThisWeekLabel;
@property (weak) IBOutlet NSTextField *rentAndBillsThisWeekLabel;
@property (weak) IBOutlet NSTextField *salesTargetThisWeek;
@property (weak) IBOutlet NSButton *fromManagersBudgetCheckbox;

@property (readonly) NSArray *payments;
@property (readonly) NSArray *sales;

@property (copy) NSDate * startDate;
@property double totalSpend;
@property double totalBillsSpend;
@property double totalManagersSpend;
@property double totalSales;
@property double weeksSpend;
@property double weeksBillsSpend;
@property double weeksManagersSpend;
@property double weeksSales;

@property NSMutableArray * periodData;
@property NSMutableArray * weeksData;
@end

@implementation AMCManagersBudgetWindowController
-(NSString *)windowNibName {
    return @"AMCManagersBudgetWindowController";
}
- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    NSDateComponents * components = [[NSDateComponents alloc] init];
    components.year = 2015;
    components.month = 1;
    components.day = 31;
    NSCalendar * gregorian = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    self.startDate = [[gregorian dateFromComponents:components] beginningOfDay];
}
-(void)reloadData {
    [self analyzeWeeks];
    [self.overviewTable reloadData];
    [self displaySelectedWeek];
    [self displaySelectedPayment];
}
-(void)setStartDate:(NSDate *)startDate {
    _startDate = startDate;
    [self reloadData];
}
-(NSDate *)startDate {
    return _startDate;
}
-(NSArray *)payments {
    if (!_payments) {
        _payments = [Payment paymentsBetweenStartDate:self.startDate endDate:[[NSDate date] endOfDay] withMoc:self.documentMoc];
    }
    return _payments;
}
-(NSArray *)sales {
    if (!_sales) {
        _sales = [Sale salesBetweenStartDate:self.startDate endDate:[[NSDate date] endOfDay] withMoc:self.documentMoc];
    }
    return _sales;
}
-(NSDate*)endOfWeekFromDate:(NSDate*)date {
    return [[date lastDayOfWeek] endOfDay];
}
-(NSDate*)startOfWeekFromDate:(NSDate*)date {
    return [[self endOfWeekFromDate:date] dateByAddingTimeInterval:-7*24*3600];
}
-(void)analyzeWeeks {
    self.overviewSpendingSinceLabel.stringValue = [NSString stringWithFormat:@"Sales and Spending since %@ %@",[self.startDate stringNamingDayOfWeek],[self.startDate dateStringWithMediumDateFormat]];
    self.periodData = [NSMutableArray array];
    NSDate * weekEnding = [self.startDate lastDayOfWeek];
    NSDictionary * weeksDictionary;
    double totalSales = 0;
    double totalSpend = 0;
    double totalManagersSpend = 0;
    double totalBillsSpend = 0;
    double totalSalesTarget = 0;
    NSInteger row = 0;
    while ( [weekEnding isLessThanOrEqualTo:[[NSDate date] lastDayOfWeek]] ) {
        NSDate * weekStarting = [[weekEnding dateByAddingTimeInterval:-10] firstDayOfWeek];
        weeksDictionary = [self analyzePeriodBeginning:[weekStarting beginningOfDay] ending:[weekEnding endOfDay]];
        totalSpend += ((NSNumber*)(weeksDictionary[@"totalSpend"])).doubleValue;
        totalBillsSpend += ((NSNumber*)(weeksDictionary[@"billsSpend"])).doubleValue;;
        totalManagersSpend += ((NSNumber*)(weeksDictionary[@"managersSpend"])).doubleValue;
        totalSales += ((NSNumber*)(weeksDictionary[@"sales"])).doubleValue;
        totalSalesTarget += ((NSNumber*)(weeksDictionary[@"salesTarget"])).doubleValue;
        self.periodData[row] = weeksDictionary;
        row++;
        weekEnding = [[weekEnding beginningOfDay] dateByAddingTimeInterval:6*24*3600];
        weekEnding = [weekEnding lastDayOfWeek];
    }
    self.totalSpendLabel.doubleValue = totalSpend;
    self.rentAndBillsLabel.doubleValue = totalBillsSpend;
    self.managersSpendLabel.doubleValue = totalManagersSpend;
    self.totalSalesLabel.doubleValue = totalSales;
    self.salesTargetLabel.doubleValue = [self salestargetForPeriodStarting:self.startDate ending:[NSDate date]];
    self.amountRemainingInManagersBudgetLabel.doubleValue = 3000 - totalManagersSpend;
}
-(NSDictionary*)analyzePeriodBeginning:(NSDate*)starting ending:(NSDate*)ending {
    NSMutableDictionary * results = [@{@"startDate"    :starting,
                                       @"endDate"      :ending,
                                       @"totalSpend"   :@0 ,
                                       @"billsSpend"   :@0 ,
                                       @"managersSpend":@0 ,
                                       @"sales"        :@0 ,
                                       @"salesTarget"  :@0
                                      } mutableCopy];
    NSArray * paymentsArray = [Payment paymentsBetweenStartDate:starting endDate:ending withMoc:self.documentMoc];
    NSArray * salesArray = [Sale salesBetweenStartDate:starting endDate:ending withMoc:self.documentMoc];
    double totalSpend = 0;
    double billsSpend = 0;
    double managersSpend = 0;
    double sales = 0;
    double salesTarget = [self salestargetForPeriodStarting:starting ending:ending];
    for (Payment * payment in paymentsArray) {
        double paymentAmount = 0;
        if (payment.voided.boolValue) {
            paymentAmount = 0;
        } else {
            if ([payment.direction isEqualToString:kAMCPaymentDirectionOut]) {
                paymentAmount = payment.amount.doubleValue;
            } else {
                paymentAmount = -payment.amount.doubleValue;
            }
        }
        if (!payment.voided.boolValue) {
            totalSpend += paymentAmount;
            if ([self isPaymentInManagersBudget:payment]) {
                managersSpend += paymentAmount;
            } else {
                billsSpend += paymentAmount;
            }
        }
    }

    for (Sale * sale in salesArray) {
        if (!sale.voided.boolValue && !sale.isQuote.boolValue) {
            sales += sale.actualCharge.doubleValue;
        }
    }
    results[@"totalSpend"] = @(totalSpend);
    results[@"billsSpend"] = @(billsSpend);
    results[@"managersSpend"] = @(managersSpend);
    results[@"sales"] = @(sales);
    results[@"salesTarget"] = @(salesTarget);
    return [results copy];
}
-(double)salestargetForPeriodStarting:(NSDate*)starting ending:(NSDate*)ending {
    double t = [ending timeIntervalSinceDate:starting];
    double weeks = t / (7.0 * 24.0 * 3600.0);
    return weeks * 700.0;
}
-(BOOL)isPaymentInManagersBudget:(Payment*)payment {
    if (payment.isManagersBudgetStatusManuallyChanged.boolValue) {
        if (payment.isManagersBudgetItem.boolValue) {
            return YES;
        } else {
            return NO;
        }
    } else {
        if (payment.paymentCategory.isManagersBudgetItem.boolValue) {
            return YES;
        } else {
            return NO;
        }
    }
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    if (tableView == self.overviewTable) {
        return self.periodData.count;
    } else {
        return self.weeksData.count;
    }
}
-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSString * identifier = tableColumn.identifier;
    if (tableView == self.overviewTable) {
        NSDictionary * weekDataDictionary = self.periodData[row];
        if ([identifier isEqualToString:@"startDate"]) {
            NSDate * date = weekDataDictionary[@"startDate"];
            return [NSString stringWithFormat:@"%@ %@",[date stringNamingDayOfWeek], [date dayAndMonthString]];
        }
        if ([identifier isEqualToString:@"totalSpend"]) {
            NSNumber * amount = weekDataDictionary[@"totalSpend"];
            return amount;
        }
        if ([identifier isEqualToString:@"managersSpend"]) {
            NSNumber * amount = weekDataDictionary[@"managersSpend"];
            return amount;
        }
        if ([identifier isEqualToString:@"billsSpend"]) {
            NSNumber * amount = weekDataDictionary[@"billsSpend"];
            return amount;
        }
        if ([identifier isEqualToString:@"sales"]) {
            NSNumber * amount = weekDataDictionary[@"sales"];
            return amount;
        }
    } else {
        Payment * payment = self.weeksData[row];
        if ([identifier isEqualToString:@"date"]) {
            return [NSString stringWithFormat:@"%@ %@",[payment.paymentDate stringNamingDayOfWeek], [payment.paymentDate dayAndMonthString]];
        }
        if ([identifier isEqualToString:@"payee"]) {
            return payment.payeeName;
        }
        if ([identifier isEqualToString:@"account"]) {
            return payment.account.friendlyName;
        }
        if ([identifier isEqualToString:@"amount"]) {
            if ([payment.direction isEqualToString:kAMCPaymentDirectionOut]) {
                return payment.amount;
            } else {
                return @(-(payment.amount.doubleValue));
            }
        }
        if ([identifier isEqualToString:@"paymentCategory"]) {
            return payment.paymentCategory.categoryName;
        }
        if ([identifier isEqualToString:@"isManagersBudget"]) {
            if ([self isPaymentInManagersBudget:payment]) {
                return @"Y";
            } else {
                return @"N";
            }
        }
    }
    return nil;
}
-(void)tableViewSelectionDidChange:(NSNotification *)notification {
    if (notification.object == self.overviewTable) {
        [self displaySelectedWeek];
    } else {
        [self displaySelectedPayment];
    }
}
-(BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    return NO;
}
-(void)displaySelectedPayment {
    Payment * payment = [self selectedPayment];
    self.fromManagersBudgetCheckbox.state = NSOffState;
    self.fromManagersBudgetCheckbox.enabled = NO;
    if (payment) {
        self.fromManagersBudgetCheckbox.state = ([self isPaymentInManagersBudget:payment])?YES:NO;
        self.fromManagersBudgetCheckbox.enabled = YES;
    }
}
-(Payment*)selectedPayment {
    NSInteger row = self.selectedWeekTable.selectedRow;
    if (row >= 0) {
        return self.weeksData[row];
    }
    return nil;
}
-(void)displaySelectedWeek {
    NSInteger row = self.overviewTable.selectedRow;
    self.spendingThisWeekLabel.stringValue = @"Summary of spending for week";
    self.spendThisWeekLabel.stringValue = @"";
    self.rentAndBillsThisWeekLabel.stringValue = @"";
    self.managersSpendThisWeekLabel.stringValue = @"";
    self.salesThisWeekLabel.stringValue = @"";
    self.salesTargetThisWeek.stringValue = @"";
    if (row >= 0) {
        NSDictionary * weekDataDictionary = self.periodData[row];
        NSDate * startDate = weekDataDictionary[@"startDate"];
        NSDate * endDate = weekDataDictionary[@"endDate"];
        NSString * begins = [NSString stringWithFormat:@"%@ %@",[startDate stringNamingDayOfWeek],[startDate dayAndMonthString]] ;
        self.spendingThisWeekLabel.stringValue = [NSString stringWithFormat:@"Summary of spending for week starting %@",begins] ;
        self.weeksData = [[Payment paymentsBetweenStartDate:startDate endDate:endDate withMoc:self.documentMoc] mutableCopy];
        self.spendThisWeekLabel.doubleValue = ((NSNumber*)(weekDataDictionary[@"totalSpend"])).doubleValue;
        self.rentAndBillsThisWeekLabel.doubleValue =  ((NSNumber*)(weekDataDictionary[@"billsSpend"])).doubleValue;
        self.managersSpendThisWeekLabel.doubleValue =  ((NSNumber*)(weekDataDictionary[@"managersSpend"])).doubleValue;
        self.salesThisWeekLabel.doubleValue = ((NSNumber*)(weekDataDictionary[@"sales"])).doubleValue;
        self.salesTargetThisWeek.doubleValue = ((NSNumber*)(weekDataDictionary[@"salesTarget"])).doubleValue;
    }
    [self.selectedWeekTable reloadData];
}
-(void)dismissController:(id)sender {
    [self.window.parentWindow endSheet:self.window];
}
- (IBAction)fromManagersBudgetCheckbox:(NSButton *)sender {
    Payment * payment = [self selectedPayment];
    payment.isManagersBudgetItem = (self.fromManagersBudgetCheckbox.state == NSOnState)?@YES:@NO;
    payment.isManagersBudgetStatusManuallyChanged = @YES;
    [self reloadData];
}

@end
