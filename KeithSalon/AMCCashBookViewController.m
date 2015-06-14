//
//  AMCCashBookViewController.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 18/03/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "AMCCashBookViewController.h"
#import "Account+Methods.h"
#import "AMCCashBook.h"

@interface AMCCashBookViewController () <NSTableViewDataSource, NSTableViewDelegate>
@property (weak) IBOutlet NSTextField *accountNameLabel;
@property (weak) IBOutlet NSTextField *balanceBroughtForwardField;
@property (weak) IBOutlet NSTextField *addReceiptsLabel;
@property (weak) IBOutlet NSTextField *lessExpensesLabel;
@property (weak) IBOutlet NSTextField *totalLabel;
@property (weak) IBOutlet NSTextField *perStatementLabel;
@property (weak) IBOutlet NSTextField *differenceLabel;
@property (weak) IBOutlet NSTableView *incomeTable;
@property (weak) IBOutlet NSTableView *expenditureTable;
@property AMCCashBook * cashbook;
@end

@implementation AMCCashBookViewController


-(NSString *)nibName {
    return @"AMCCashBookViewController";
}

-(void)prepareForDisplayWithSalon:(AMCSalonDocument *)salonDocument {
    [super prepareForDisplayWithSalon:salonDocument];
    self.cashbook = [[AMCCashBook alloc] initWithSalon:salonDocument.salon managedObjectContext:self.documentMoc account:self.account statementItems:self.statementItems firstDay:self.firstDay lastDay:self.lastDay balanceBroughtForward:self.balanceBroughtForward balancePerBank:self.balancePerBank];
    [self addColumnsToIncomeTable];
    [self addColumnsToExpenditureTable];
    self.incomeTable.delegate = self;
    self.incomeTable.dataSource = self;
    self.expenditureTable.delegate = self;
    self.expenditureTable.dataSource = self;
    [self.incomeTable reloadData];
    [self.expenditureTable reloadData];
    self.accountNameLabel.stringValue = self.account.friendlyName;
    self.balanceBroughtForwardField.doubleValue = self.balanceBroughtForward;
    self.addReceiptsLabel.doubleValue  = self.cashbook.totalIncome;
    self.lessExpensesLabel.doubleValue = self.cashbook.totalExpenses;
    self.totalLabel.doubleValue = self.cashbook.total;
    self.perStatementLabel.doubleValue = self.cashbook.balancePerBank;
    self.differenceLabel.doubleValue = self.cashbook.difference;
}
-(void)addColumnsToIncomeTable {
    [self removeAllTableColumns:self.incomeTable];
    NSArray * headers = self.cashbook.incomeHeaders;
    for (NSString * header in headers) {
        NSTableColumn * column = [[NSTableColumn alloc] initWithIdentifier:header];
        column.width = 150;
        column.title = column.identifier;
        [self.incomeTable addTableColumn:column];
    }
}
-(void)addColumnsToExpenditureTable {
    [self removeAllTableColumns:self.expenditureTable];
    NSArray * headers = self.cashbook.expenditureHeaders;
    for (NSString * header in headers) {
        NSTableColumn * column = [[NSTableColumn alloc] initWithIdentifier:header];
        column.width = 75;
        column.title = column.identifier;
        [self.expenditureTable addTableColumn:column];
    }
}
-(void)removeAllTableColumns:(NSTableView*)tableView {
    while (tableView.tableColumns.count > 0) {
        NSTableColumn * column = tableView.tableColumns[0];
        [tableView removeTableColumn:column];
    }
}
- (IBAction)balanceBroughtForwardChanged:(id)sender {
}
- (IBAction)exportToCSV:(id)sender {
    NSSavePanel* savePanel = [NSSavePanel savePanel];
    savePanel.title = @"Export cashbook";
    savePanel.extensionHidden = YES;
    savePanel.prompt = @"Export cashbook as CSV file";
    NSString * appName = [[NSRunningApplication currentApplication] localizedName];
    savePanel.nameFieldStringValue = [NSString stringWithFormat:@"%@ %@ cashbook.csv",appName,self.account.friendlyName];
    savePanel.allowedFileTypes = @[@"csv"];
    savePanel.allowsOtherFileTypes = NO;
    [savePanel beginWithCompletionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            NSURL *saveURL = [savePanel URL];
            NSError * error;
            [self writeCashbookToFile:[saveURL path] error:&error];
        }
    }];
}
-(BOOL)writeCashbookToFile:(NSString*)filename error:(NSError**)error {
    AMCCashBook * cashBook = [[AMCCashBook alloc] initWithSalon:self.salonDocument.salon managedObjectContext:self.documentMoc account:self.account statementItems:self.statementItems firstDay:self.firstDay lastDay:self.lastDay balanceBroughtForward:self.balanceBroughtForward balancePerBank:self.balancePerBank];
    return [cashBook writeToFile:filename error:error];
}
-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    NSInteger rows = 0;
    if (tableView == self.incomeTable) {
        rows = self.cashbook.incomeDictionaries.count+1;
    }
    if (tableView == self.expenditureTable) {
        rows = self.cashbook.expenditureDictionaries.count+1;
    }
    return rows;
}
-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSDictionary * dictionary;
    if (tableView == self.incomeTable) {
        if (row == self.cashbook.incomeDictionaries.count) {
            // totals row
            dictionary = self.cashbook.incomeTotals;
        } else {
            // data rows
            dictionary = self.cashbook.incomeDictionaries[row];
        }
    }
    if (tableView == self.expenditureTable) {
        if (row == self.cashbook.expenditureDictionaries.count) {
            // totals row
            dictionary = self.cashbook.expenditureTotals;
        } else {
            // data rows
            dictionary = self.cashbook.expenditureDictionaries[row];
        }
    }
    return dictionary[tableColumn.identifier];
}

@end
