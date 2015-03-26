//
//  AMCAccountReconciliationViewController.m
//  ClaudiasSalon
//
//  Created by service on 17/09/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "AMCAccountReconciliationViewController.h"
#import "Account+Methods.h"
#import "AccountReconciliation+Methods.h"
#import "NSDate+AMCDate.h"

@interface AMCAccountReconciliationViewController ()
{
    Account * _account;
}
@property NSMutableArray * reconciliations;

@end

@implementation AMCAccountReconciliationViewController

-(NSString *)nibName {
    return @"AMCAccountReconciliationViewController";
}

-(void)setAccount:(Account *)account {
    _account = account;
    self.reconcileAccountLabel.stringValue = @"Balance for account:";
}
-(void)prepareForDisplayWithSalon:(AMCSalonDocument *)salonDocument {
    [super prepareForDisplayWithSalon:salonDocument];
    self.dateForBalance.dateValue = [[[NSDate date] endOfDay] dateByAddingTimeInterval:-1];
    [self reloadData];
}
-(void)reloadData {
    self.bankNameLabel.stringValue = self.account.bankName;
    self.sortCodeLabel.stringValue = self.account.sortCode;
    self.accountNumberLabel.stringValue = self.account.accountNumber;
    [self displayBalance:self.account];
    [self reloadReconciliationTable];
    [self loadAccountsPopup];
}
-(Account *)account {
    return _account;
}
-(void)loadAccountsPopup {
    NSArray * accounts = [Account allObjectsWithMoc:self.documentMoc];
    [self.accountsPopupButton removeAllItems];
    for (Account * account in accounts) {
        NSMenuItem * menuItem = [[NSMenuItem alloc] init];
        menuItem.representedObject = account;
        menuItem.title = account.friendlyName;
        [self.accountsPopupButton.menu addItem:menuItem];
        if (account == self.account) {
            [self.accountsPopupButton selectItem:menuItem];
        }
    }
}
-(void)displayBalance:(Account*)account {
    AccountReconciliation * latest = [account lastAccountReconcilliationBeforeDate:self.dateForBalance.dateValue];
    self.expectedBalance.stringValue = [NSString stringWithFormat:@"Closing balance should be: £%1.2f",[account expectedBalanceFromReconciliation:latest toDate:self.dateForBalance.dateValue]];
}
- (IBAction)addReconciliationButtonClicked:(id)sender {
    [self.reconciliationsTable.window endEditingFor:self.reconciliationsTable];
    AccountReconciliation * reconciliation = [AccountReconciliation newObjectWithMoc:self.documentMoc];
    [self addReconciliation:reconciliation];
    [self displayBalance:self.account];
    [self.reconciliationsTable reloadData];
    [self.removeReconciliationButton setEnabled:(self.reconciliations.count>0)];
}
- (IBAction)removeReconciliationButtonClicked:(id)sender {
    [self.reconciliationsTable.window endEditingFor:self.reconciliationsTable];
    AccountReconciliation * reconciliation = [self selectedReconciliation];
    [self removeReconciliation:reconciliation];
    [self displayBalance:self.account];
    [self.reconciliationsTable reloadData];
    [self.removeReconciliationButton setEnabled:(self.reconciliations.count>0)];
}
-(void)addReconciliation:(AccountReconciliation*)reconciliation {
    if (reconciliation) {
        [self.account addReconciliationsObject:reconciliation];
        [self.reconciliations addObject:reconciliation];
        [self sortReconcilationsArray];
        NSUInteger index = [self.reconciliations indexOfObject:reconciliation];
        [self.reconciliationsTable selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
    }
}
-(void)removeReconciliation:(AccountReconciliation*)reconciliation {
    if (reconciliation) {
        [self.account removeReconciliationsObject:reconciliation];
        [self.reconciliations removeObject:reconciliation];
    }
}
-(AccountReconciliation*)selectedReconciliation {
    if (self.reconciliationsTable.selectedRow < 0) return nil;
    NSUInteger index = self.reconciliationsTable.selectedRow;
    return self.reconciliations[index];
}
-(void)sortReconcilationsArray {
    NSSortDescriptor * sort = [NSSortDescriptor sortDescriptorWithKey:@"reconciliationDate" ascending:YES];
    self.reconciliations = [[self.reconciliations sortedArrayUsingDescriptors:@[sort]] mutableCopy];
    [self.reconciliationsTable reloadData];
}
-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    NSUInteger number = self.reconciliations.count;
    return number;
}
-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (tableView == self.reconciliationsTable) {
        AccountReconciliation * reconciliation = self.reconciliations[row];
        if ([tableColumn.identifier isEqualToString:@"date"]) {
            return reconciliation.reconciliationDate;
        }
        if ([tableColumn.identifier isEqualToString:@"time"]) {
            return reconciliation.reconciliationDate;
        }
        if ([tableColumn.identifier isEqualToString:@"actualAmount"]) {
            return reconciliation.actualBalance;
        }
    }
    return nil;
}
-(void)controlTextDidBeginEditing:(NSNotification *)obj {
    [self.addReconciliationButton setEnabled:NO];
    [self.removeReconciliationButton setEnabled:NO];
}
-(void)controlTextDidEndEditing:(NSNotification *)obj {
    if (obj.object == self.reconciliationsTable) {
        NSUInteger editedRow = self.reconciliationsTable.editedRow;
        NSUInteger editedCol = self.reconciliationsTable.editedColumn;
        NSDate * day;
        NSDate * time;
        NSDate * date;
        AccountReconciliation * reconciliation = self.reconciliations[editedRow];
        if (editedCol == 0) {
            day = (NSDate*)self.reconciliationsTable.objectValue;
            time = reconciliation.reconciliationDate;
            date = [self dateFromDayDate:day timeDate:time];
            [self updateReconciliation:reconciliation withDate:date];
        }
        if (editedCol == 1) {
            day = reconciliation.reconciliationDate;
            time = (NSDate*)self.reconciliationsTable.objectValue;
            date = [self dateFromDayDate:day timeDate:time];
            [self updateReconciliation:reconciliation withDate:date];
        }
        if (editedCol == 2) {
            NSNumber * number = self.reconciliationsTable.objectValue;
            double total = number.doubleValue;
            [self updateReconciliation:reconciliation withAmount:total];
        }
    }
    [self displayBalance:self.account];
    [self.addReconciliationButton setEnabled:YES];
    [self.removeReconciliationButton setEnabled:(self.reconciliations.count>0)];
}
-(NSDate*)dateFromDayDate:(NSDate*)day timeDate:(NSDate*)time {
    day = [day beginningOfDay];
    NSCalendar * gregorian = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents * components = [gregorian components:NSCalendarUnitHour | NSCalendarUnitMinute fromDate:time];
    NSDate * newDate = [gregorian dateByAddingComponents:components toDate:day options:0];
    return newDate;
}
-(void)updateReconciliation:(AccountReconciliation*)reconciliation withDate:(NSDate*)date {
    reconciliation.reconciliationDate = date;
}
-(void)updateReconciliation:(AccountReconciliation*)reconciliation withAmount:(double)amount {
    reconciliation.actualBalance = @(amount);
}
-(void)reloadReconciliationTable {
    self.reconciliations = [[self.account.reconciliations allObjects] mutableCopy];
    [self sortReconcilationsArray];
    [self.removeReconciliationButton setEnabled:(self.reconciliations.count>0)];
}

- (IBAction)accountChanged:(NSPopUpButton *)sender {
    Account * account = self.accountsPopupButton.selectedItem.representedObject;
    self.account = account;
    [self reloadData];
}
- (IBAction)dateForBalanceChanged:(id)sender {
    [self displayBalance:self.account];
}
@end
