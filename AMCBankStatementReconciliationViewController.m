//
//  AMCBankStatementReconciliationViewController.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 06/04/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "AMCBankStatementReconciliationViewController.h"
#import "AMCStatementParser.h"
#import "AMCAccountStatementItem.h"
#import "NSDate+AMCDate.h"

@interface AMCBankStatementReconciliationViewController () <NSTableViewDataSource, NSTableViewDelegate>
@property (weak) IBOutlet NSTextField *viewTitle;
@property (weak) IBOutlet NSTextField * pathLabel;
@property (weak) IBOutlet NSTableView *csvTable;
@property (weak) IBOutlet NSTextField *headerLinesCountField;

@property (weak) IBOutlet NSTextField *dateColumnField;

@property (weak) IBOutlet NSTextField *grossAmountColumnField;
@property (weak) IBOutlet NSTextField *feeColumnField;
@property (weak) IBOutlet NSTextField *netAmountColumnField;
@property (weak) IBOutlet NSTextField *noteColumnField;

@property (strong) IBOutlet NSViewController *configureCSVViewController;
@property (strong) IBOutlet NSViewController *reconcileTransactionsViewController;

@property (weak) IBOutlet NSView *containerView;
@property NSMutableArray * dynamicConstraints;

@property NSView * subview;
@property AMCStatementParser * parser;
@property (weak) IBOutlet NSTableView *statementTransactionsTable;
@property (weak) IBOutlet NSTableView *documentTransactionsTable;
@property NSArray * filteredBankStatementRows;

@end

@implementation AMCBankStatementReconciliationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSInteger i = 0;
    for (NSTableColumn * column in self.csvTable.tableColumns) {
        column.title = [NSString stringWithFormat:@"Column %lu",i];
        column.identifier = [NSString stringWithFormat:@"Column %lu",i];
        i++;
    }
}
-(void)emplaceSubview {
    for (NSView * view in self.containerView.subviews) {
        [view removeFromSuperviewWithoutNeedingDisplay];
    }
    self.subview.translatesAutoresizingMaskIntoConstraints = NO;
    [self.containerView addSubview:self.subview];
    [self.subview setNeedsUpdateConstraints:YES];
    [self.containerView setNeedsDisplay:YES];

    if (self.subview == self.configureCSVViewController.view) {
        self.viewTitle.stringValue = @"Open and configure the statement";
    }
    if (self.subview == self.reconcileTransactionsViewController.view) {
        self.viewTitle.stringValue = @"Reconcile transactions with statement";
    }
    [self.view setNeedsUpdateConstraints:YES];
    [self.containerView setNeedsDisplay:YES];
}

-(void)updateViewConstraints {
    [super updateViewConstraints];
    NSView * containerView = self.containerView;
    NSView * subview = self.subview;
    
    [self.containerView addSubview:self.subview];
    if (self.dynamicConstraints) {
        [containerView removeConstraints:self.dynamicConstraints];
    } else {
        self.dynamicConstraints = [NSMutableArray array];
    }
    [self.dynamicConstraints removeAllObjects];
    NSLayoutConstraint * constraint = nil;
    constraint = [NSLayoutConstraint constraintWithItem:containerView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:subview attribute:NSLayoutAttributeCenterX multiplier:1 constant:0];
    [containerView addConstraint:constraint];
    [self.dynamicConstraints addObject:constraint];
    constraint = [NSLayoutConstraint constraintWithItem:containerView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:subview attribute:NSLayoutAttributeCenterY multiplier:1 constant:0];
    [containerView addConstraint:constraint];
    [self.dynamicConstraints addObject:constraint];
    NSDictionary * views = NSDictionaryOfVariableBindings(containerView,subview);
    NSArray * otherConstraints = nil;
    otherConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[subview]|" options:0 metrics:nil views:views];
    [self.dynamicConstraints addObjectsFromArray:otherConstraints];
    [containerView addConstraints:otherConstraints];
    otherConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[subview]|" options:0 metrics:nil views:views];
    [self.dynamicConstraints addObjectsFromArray:otherConstraints];
    [containerView addConstraints:otherConstraints];
}
-(void)prepareForDisplayWithSalon:(AMCSalonDocument *)salonDocument {
    [super prepareForDisplayWithSalon:salonDocument];
    self.parser = nil;
    self.subview = self.configureCSVViewController.view;
    self.pathLabel.stringValue = @"";
    [self emplaceSubview];
}
- (IBAction)loadCSV:(id)sender {
    NSOpenPanel * openPanel = [NSOpenPanel openPanel];
    openPanel.allowedFileTypes = @[@"csv"];
    NSInteger result = [openPanel runModal];
    if (result == NSFileHandlingPanelOKButton) {
        NSURL * fileURL = openPanel.URL;
        NSError * error;
        NSString * csv = [NSString stringWithContentsOfURL:fileURL usedEncoding:nil error:&error];
        if (!csv && error) {
            error = nil;
            csv = [NSString stringWithContentsOfURL:fileURL encoding:NSASCIIStringEncoding error:&error];
            if (!csv && error) {
                [NSApp presentError:error];
            }
        }
        if (csv) {
            self.parser = [[AMCStatementParser alloc] initWithCSVString:csv];
            self.headerLinesCountField.integerValue = self.parser.headerRows;
            self.dateColumnField.integerValue = self.parser.dateCol;
            self.grossAmountColumnField.integerValue = self.parser.grossAmountColumn;
            self.feeColumnField.integerValue = self.parser.feeColumn;
            self.netAmountColumnField.integerValue = self.parser.netAmountColumn;
            self.pathLabel.stringValue = fileURL.path;
        } else {
            self.headerLinesCountField.integerValue = -1;
            self.dateColumnField.integerValue = -1;
            self.grossAmountColumnField.integerValue = -1;
            self.feeColumnField.integerValue = -1;
            self.netAmountColumnField.integerValue = -1;
            self.pathLabel.stringValue = fileURL.path;
        }
    }
    [self.csvTable reloadData];
}
- (IBAction)headerLinesCountChanged:(id)sender {
    [self.csvTable deselectAll:self];
    NSInteger headerRows = self.headerLinesCountField.integerValue;
    if (headerRows == self.parser.headerRows) {
        return;
    }
    self.parser.headerRows = headerRows;
    if (headerRows >=0) {
        NSMutableIndexSet * indexSet = [NSMutableIndexSet indexSet];
        for (NSInteger i = 0; i < headerRows; i++) {
            [indexSet addIndex:i];
        }
        [self.csvTable selectRowIndexes:indexSet byExtendingSelection:NO];
        [self.csvTable scrollRowToVisible:0];
        [self.csvTable scrollRowToVisible:headerRows-1];
    }
}
- (IBAction)dateColumnChanged:(id)sender {
    [self.csvTable deselectAll:self];
    NSInteger dateColumn = self.dateColumnField.integerValue;
    if (dateColumn == self.parser.dateCol) {
        return;
    }
    self.parser.dateCol = dateColumn;
    if (dateColumn >=0) {
        NSIndexSet * indexSet = [NSIndexSet indexSetWithIndex:dateColumn];
        [self.csvTable selectColumnIndexes:indexSet byExtendingSelection:NO];
        [self.csvTable scrollColumnToVisible:dateColumn];
    }
}
- (IBAction)grossAmountColumnChanged:(id)sender {
    [self.csvTable deselectAll:self];
    NSInteger grossAmountColumn = self.grossAmountColumnField.integerValue;
    self.parser.grossAmountColumn = grossAmountColumn;
    if (grossAmountColumn >=0) {
        NSIndexSet * indexSet = [NSIndexSet indexSetWithIndex:grossAmountColumn];
        [self.csvTable selectColumnIndexes:indexSet byExtendingSelection:NO];
        [self.csvTable scrollColumnToVisible:grossAmountColumn];
    }
}
- (IBAction)feeColumnChanged:(id)sender {
    [self.csvTable deselectAll:self];
    NSInteger feeColumn = self.feeColumnField.integerValue;
    self.parser.feeColumn = feeColumn;
    if (feeColumn >=0) {
        NSIndexSet * indexSet = [NSIndexSet indexSetWithIndex:feeColumn];
        [self.csvTable selectColumnIndexes:indexSet byExtendingSelection:NO];
        [self.csvTable scrollColumnToVisible:feeColumn];
    }
}
- (IBAction)netAmountColumnChanged:(id)sender {
    [self.csvTable deselectAll:self];
    NSInteger netAmountColumn = self.netAmountColumnField.integerValue;
    self.parser.netAmountColumn = netAmountColumn;
    if (netAmountColumn >=0) {
        NSIndexSet * indexSet = [NSIndexSet indexSetWithIndex:netAmountColumn];
        [self.csvTable selectColumnIndexes:indexSet byExtendingSelection:NO];
        [self.csvTable scrollColumnToVisible:netAmountColumn];
    }
}
- (IBAction)noteColumnChanged:(id)sender {
    [self.csvTable deselectAll:self];
    NSInteger noteColumn = self.noteColumnField.integerValue;
    self.parser.noteColumn = noteColumn;
    if (noteColumn >=0) {
        NSIndexSet * indexSet = [NSIndexSet indexSetWithIndex:noteColumn];
        [self.csvTable selectColumnIndexes:indexSet byExtendingSelection:NO];
        [self.csvTable scrollColumnToVisible:noteColumn];
    }
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    if (!self.parser) return 0;
    if (tableView == self.csvTable) {
        return self.parser.rowCount;
    }
    if (tableView == self.statementTransactionsTable) {
        return self.parser.transactionDictionaries.count;
    }
    if (tableView == self.documentTransactionsTable) {
        return self.computerRecords.count;
    }
    return 0;
}

-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (tableView == self.csvTable) {
        return [self.parser csvStringForIdentifier:tableColumn.identifier row:row];
    }
    if (tableView == self.statementTransactionsTable) {
        NSDictionary * dictionary = self.parser.transactionDictionaries[row];
        return dictionary[tableColumn.identifier];
    }
    if (tableView == self.documentTransactionsTable) {
        AMCAccountStatementItem * item = self.computerRecords[row];
        if ([tableColumn.identifier isEqualToString:@"reconciled"]) {
            return (item.isReconciled)?@"Y":@"";
        }
        if ([tableColumn.identifier isEqualToString:@"date"]) {
            return item.date;
        }
        if ([tableColumn.identifier isEqualToString:@"amount"]) {
            return @(item.amountGross);
        }
        if ([tableColumn.identifier isEqualToString:@"note"]) {
            return item.note;
        }
    }
    return nil;
}

-(void)tableViewSelectionDidChange:(NSNotification *)notification {
    if (notification.object == self.statementTransactionsTable) {
        [self highlightComputerRecordMatchingSelectedStatementTransaction];
    }
}
-(void)highlightComputerRecordMatchingSelectedStatementTransaction {
    NSInteger statementTransactionIndex = self.statementTransactionsTable.selectedRow;
    NSMutableDictionary * transactionDictionary = self.parser.transactionDictionaries[statementTransactionIndex];
    NSMutableArray * matches = [self computerRecordsMatchingDateAndAmount:transactionDictionary];
    NSMutableIndexSet * indexes = [NSMutableIndexSet indexSet];
    for (NSDictionary * dictionary in matches) {
        NSNumber * mismatchNumber = dictionary[@"mismatch"];
        if (mismatchNumber.doubleValue < 1) {
            AMCAccountStatementItem * item = dictionary[@"item"];
            [indexes addIndex:[self.computerRecords indexOfObject:item]];
        }
    }
    [self.documentTransactionsTable selectRowIndexes:indexes byExtendingSelection:NO];
    [self.documentTransactionsTable scrollRowToVisible:indexes.firstIndex];
}
-(NSMutableArray*)computerRecordsMatchingDateAndAmount:(NSMutableDictionary*)transactionDictionary {
    NSDate * date = transactionDictionary[@"date"];
    NSNumber * amount = transactionDictionary[@"amount"];
    NSMutableArray * matchingComputerRecords = [NSMutableArray array];
    for (AMCAccountStatementItem * item in self.computerRecords) {
        double dateMismatch = [self mismatchFirstDate:date secondDate:item.date];
        double amountMismatch = [self mismatchFirstAmount:amount secondAmount:@(item.amountGross)];
        NSDictionary * dictionary = @{@"mismatch" : @(dateMismatch+amountMismatch),
                                      @"dateMismatch" : @(dateMismatch),
                                      @"amountMismatch" : @(amountMismatch),
                                      @"item":item};
        [matchingComputerRecords addObject:dictionary];
    }
    [matchingComputerRecords sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"mismatch" ascending:YES],
                                                    [NSSortDescriptor sortDescriptorWithKey:@"dateMismatch" ascending:YES],
                                                    [NSSortDescriptor sortDescriptorWithKey:@"amountMismatch" ascending:YES]]];
    return matchingComputerRecords;
}
-(double)mismatchFirstDate:(NSDate*)firstDate secondDate:(NSDate*)secondDate {
    double seconds = fabs([[secondDate beginningOfDay]  timeIntervalSinceDate:[firstDate beginningOfDay]]);
    return seconds / 3600 / 24;
}
-(double)mismatchFirstAmount:(NSNumber*)firstAmount secondAmount:(NSNumber*)secondAmount {
    return round(fabs(firstAmount.doubleValue*100 - secondAmount.doubleValue*100));
}
- (IBAction)nextStep:(id)sender {
    if (self.subview == self.configureCSVViewController.view) {
        self.subview = self.reconcileTransactionsViewController.view;
        [self emplaceSubview];
    }
}
- (IBAction)previousStep:(id)sender {
    if (self.subview == self.reconcileTransactionsViewController.view) {
        self.subview = self.configureCSVViewController.view;
        [self emplaceSubview];
    }
}





@end
