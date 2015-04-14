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

@interface AMCBankStatementReconciliationViewController () <NSTableViewDataSource, NSTableViewDelegate, NSMenuDelegate>
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
@property (weak) IBOutlet NSTableView *pairedTable;

@property NSArray * filteredBankStatementRows;
@property NSMutableSet * pairedRecords;
@property NSMutableArray * pairedRecordsArray;
@property NSMutableSet * pairedComputerRecords;
@property NSMutableSet * pairedStatementTransactions;

@property (weak) IBOutlet NSMenu * statementTransactionsTableContextMenu;

@property (weak) IBOutlet NSMenu * computerRecordsTableContextMenu;

@property (weak) IBOutlet NSMenu * pairedTableContextMenu;

@property (weak) IBOutlet NSMenuItem *pairStatementMenuItem;

@property (weak) IBOutlet NSMenuItem *UnpairStatementMenuItem;
@property (weak) IBOutlet NSMenuItem *addPairedComputerRecordsMenuItem;

@property (weak) IBOutlet NSMenuItem *pairComputerRecordMenuItem;
@property (weak) IBOutlet NSMenuItem *unpairComputerRecordMenuItem;
@property (weak) IBOutlet NSMenuItem *voidComputerRecordMenuItem;
@property (weak) IBOutlet NSMenuItem *unpairPairedRecordMenuItem;

@end

@implementation AMCBankStatementReconciliationViewController
-(instancetype)init {
    self = [super init];
    if (self) {
        self.pairedRecords = [NSMutableSet set];
        self.pairedStatementTransactions = [NSMutableSet set];
        self.pairedComputerRecords = [NSMutableSet set];
        self.pairedRecordsArray = [NSMutableArray array];
    }
    return self;
}
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
    self.pairedRecords = [NSMutableSet set];
    self.pairedStatementTransactions = [NSMutableSet set];
    self.pairedComputerRecords = [NSMutableSet set];
    self.pairedRecordsArray = [NSMutableArray array];
    [self updateTransactionTables];
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
    [self.pairedStatementTransactions removeAllObjects];
    [self.pairedComputerRecords removeAllObjects];
    [self.pairedRecords removeAllObjects];
    [self.pairedRecordsArray removeAllObjects];
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
    if (tableView == self.pairedTable) {
        return self.pairedRecordsArray.count;
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
            return (item.pairingRecord)?@"Y":@"";
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
    if (tableView == self.pairedTable) {
        NSDictionary * pairing = self.pairedRecordsArray[row];
        NSDictionary * transactionDictionary = pairing[@"statementTransaction"];
        AMCAccountStatementItem * item = pairing[@"computerRecord"];
        if ([tableColumn.identifier isEqualToString:@"leftDate"]) {
            return transactionDictionary[@"date"];
        }
        if ([tableColumn.identifier isEqualToString:@"rightDate"]) {
            return item.date;
        }
        if ([tableColumn.identifier isEqualToString:@"leftAmount"]) {
            return transactionDictionary[@"amount"];
        }
        if ([tableColumn.identifier isEqualToString:@"rightAmount"]) {
            return @(item.amountGross);
        }
        if ([tableColumn.identifier isEqualToString:@"leftNote"]) {
            return transactionDictionary[@"note"];
        }
        if ([tableColumn.identifier isEqualToString:@"rightNote"]) {
            return item.note;
        }
        if ([tableColumn.identifier isEqualToString:@"mismatch"]) {
            return pairing[@"mismatch"];
        }
    }
    return nil;
}
-(void)tableViewSelectionDidChange:(NSNotification *)notification {
    if (notification.object == self.statementTransactionsTable) {
        [self highlightComputerRecordMatchingSelectedStatementTransaction];
    }
    if (notification.object == self.pairedTable) {
        NSInteger pairedIndex = self.pairedTable.selectedRow;
        if (pairedIndex >= 0) {
            NSDictionary * pairing = self.pairedRecordsArray[pairedIndex];
            NSDictionary * transactionDictionary = pairing[@"statementTransaction"];
            [self highlightComputerRecordMatchingSelectedStatementTransaction:transactionDictionary];
        }
    }
}
-(void)highlightComputerRecordMatchingSelectedStatementTransaction:(NSDictionary*)transactionDictionary {
    NSInteger statementIndex = [self.parser.transactionDictionaries indexOfObject:transactionDictionary];
    if (statementIndex != NSNotFound) {
        [self.statementTransactionsTable selectRowIndexes:[NSIndexSet indexSetWithIndex:statementIndex] byExtendingSelection:NO];
        [self.statementTransactionsTable scrollRowToVisible:statementIndex];

        NSDictionary * pairing = [self pairingRecordForStatementTransaction:transactionDictionary];
        AMCAccountStatementItem * item = pairing[@"computerRecord"];
        NSInteger computerRecordIndex = [self.computerRecords indexOfObject:item];
        if (computerRecordIndex != NSNotFound) {
            [self.documentTransactionsTable selectRowIndexes:[NSIndexSet indexSetWithIndex:computerRecordIndex] byExtendingSelection:NO];
            [self.documentTransactionsTable scrollRowToVisible:computerRecordIndex];
        }
    }
    
}
-(void)highlightComputerRecordMatchingSelectedStatementTransaction {
    NSInteger statementTransactionIndex = self.statementTransactionsTable.selectedRow;
    NSMutableDictionary * transactionDictionary = self.parser.transactionDictionaries[statementTransactionIndex];
    [self highlightComputerRecordMatchingSelectedStatementTransaction:transactionDictionary];
}
-(void)unpairStatementTransaction:(NSMutableDictionary*)transactionDicitonary {
    if (![self isStatementTransactionPaired:transactionDicitonary]) {
        return;
    }
    NSDictionary * pairedRecord = [self pairingRecordForStatementTransaction:transactionDicitonary];
    [self.pairedRecords removeObject:pairedRecord];
    [self.pairedStatementTransactions removeObject:transactionDicitonary];
    AMCAccountStatementItem * item = pairedRecord[@"computerRecord"];
    [self.pairedComputerRecords removeObject:item];
    item.pairingRecord = nil;
    transactionDicitonary[@"reconciled"] = @"";
    [self updateTransactionTables];
}
-(void)updateTransactionTables {
    self.pairedRecordsArray = [[self.pairedRecords allObjects] mutableCopy];
    [self.statementTransactionsTable reloadData];
    [self.documentTransactionsTable reloadData];
    [self.pairedTable reloadData];
}
-(void)unpairComputerRecord:(AMCAccountStatementItem*)item {
    if (![self isComputerRecordPaired:item]) {
        return;
    }
    NSDictionary * pairedRecord = [self pairingRecordForComputerRecord:item];
    NSMutableDictionary * statementTransaction = pairedRecord[@"statementTransaction"];
    [self unpairStatementTransaction:statementTransaction];
}
-(NSInteger)pairStatementTransaction:(NSMutableDictionary*)transactionDictionary withComputerRecord:(AMCAccountStatementItem*)item {
    [self unpairStatementTransaction:transactionDictionary];
    [self unpairComputerRecord:item];
    NSDictionary * pairedRecord = @{@"statementTransaction":transactionDictionary,
             @"computerRecord":item};
    [self.pairedRecords addObject:pairedRecord];
    [self.pairedComputerRecords addObject:item];
    [self.pairedStatementTransactions addObject:transactionDictionary];
    item.pairingRecord = pairedRecord;
    transactionDictionary[@"reconciled"] = @"Y";
    [self updateTransactionTables];
    return self.pairedRecords.count - 1;
}
-(BOOL)isComputerRecordPaired:(AMCAccountStatementItem*)item {
    return [self.pairedComputerRecords containsObject:item];
}
-(BOOL)isStatementTransactionPaired:(NSDictionary*)transactionDictionary {
    return [self.pairedStatementTransactions containsObject:transactionDictionary];
}
-(NSDictionary*)pairingRecordForStatementTransaction:(NSDictionary*)statementTransaction {
    if ([self isStatementTransactionPaired:statementTransaction]) {
        for (NSDictionary * pairing in self.pairedRecords) {
            if (pairing[@"statementTransaction"] == statementTransaction) {
                return pairing;
            }
        }
    }
    return nil;
}
-(NSDictionary*)pairingRecordForComputerRecord:(AMCAccountStatementItem*)item {
    if ([self isComputerRecordPaired:item]) {
        for (NSDictionary * pairing in self.pairedRecords) {
            if (pairing[@"computerRecord"] == item) {
                return pairing;
            }
        }
    }
    return nil;
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

- (IBAction)pair:(id)sender {
    NSInteger statementTransactionIndex = self.statementTransactionsTable.selectedRow;
    NSMutableDictionary * transactionDictionary = self.parser.transactionDictionaries[statementTransactionIndex];
    NSInteger computerRecordIndex = self.documentTransactionsTable.selectedRow;
    AMCAccountStatementItem * item = self.computerRecords[computerRecordIndex];
    NSInteger pairedIndex = [self pairStatementTransaction:transactionDictionary withComputerRecord:item];
    [self.pairedTable selectRowIndexes:[NSIndexSet indexSetWithIndex:pairedIndex] byExtendingSelection:NO];
}
- (IBAction)unpair:(id)sender {
    NSInteger statementTransactionIndex = self.statementTransactionsTable.selectedRow;
    NSMutableDictionary * transactionDictionary = self.parser.transactionDictionaries[statementTransactionIndex];
    [self unpairStatementTransaction:transactionDictionary];
}

- (IBAction)pairClickedItem:(id)sender {
}

- (IBAction)unpairClickeditem:(id)sender {
}
- (IBAction)addMatchingComputerRecord:(id)sender {
}
- (IBAction)voidItem:(id)sender {
}
- (IBAction)autoPairAll:(id)sender {
    for (NSMutableDictionary * transactionDictionary in self.parser.transactionDictionaries) {
        AMCAccountStatementItem * bestMatch = [self bestMatchForStatementTransaction:transactionDictionary];
        if (bestMatch) {
            [self pairStatementTransaction:transactionDictionary withComputerRecord:bestMatch];
        }
    }
}
-(AMCAccountStatementItem*)bestMatchForStatementTransaction:(NSMutableDictionary*)transactionDictionary {
    NSMutableArray * matches = [self computerRecordsMatchingDateAndAmount:transactionDictionary];
    for (NSDictionary * dictionary in matches) {
        NSNumber * mismatchNumber = dictionary[@"mismatch"];
        if (mismatchNumber.doubleValue < 1) {
            AMCAccountStatementItem * item = dictionary[@"item"];
            if (!item.pairingRecord) {
                return item;
            }
        }
    }
    return nil;
}
-(id)actionItemsForTable:(NSTableView*)table {
    NSInteger row = [table clickedRow];
    if (row < 0) return nil;
    if (table == self.statementTransactionsTable) {
        return self.parser.transactionDictionaries[row];
    }
    if (table == self.documentTransactionsTable) {
        return self.computerRecords[row];
    }
    if (table == self.pairedTable) {
        return self.pairedRecordsArray[row];
    }
    return nil;
}
#pragma mark - NSMenuDelegate
-(void)menuNeedsUpdate:(NSMenu *)menu {
    
}
-(void)menuWillOpen:(NSMenu*)menu {
    
}
-(BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    if (menuItem == self.pairStatementMenuItem) {
        NSMutableDictionary * statementDictionary = [self actionItemsForTable:self.statementTransactionsTable];
        if (statementDictionary) {
            return YES;
        }
        return NO;
    }
    if (menuItem == self.UnpairStatementMenuItem) {
        NSMutableDictionary * statementDictionary = [self actionItemsForTable:self.statementTransactionsTable];
        if (statementDictionary) {
            if ([self isStatementTransactionPaired:statementDictionary]) {
                return YES;
            }
            return NO;
        }
        return NO;
    }
    if (menuItem == self.addPairedComputerRecordsMenuItem) {
        NSMutableDictionary * statementDictionary = [self actionItemsForTable:self.statementTransactionsTable];
        if (statementDictionary) {
            return YES;
        }
        return NO;
    }

    if (menuItem == self.pairComputerRecordMenuItem) {
        AMCAccountStatementItem * item = [self actionItemsForTable:self.documentTransactionsTable];
        if (item) {
            return YES;
        }
        return NO;
    }
    if (menuItem == self.unpairComputerRecordMenuItem) {
        AMCAccountStatementItem * item = [self actionItemsForTable:self.documentTransactionsTable];
        if (item.pairingRecord) {
            return YES;
        }
        return NO;
    }
    if (menuItem == self.voidComputerRecordMenuItem) {
        AMCAccountStatementItem * item = [self actionItemsForTable:self.documentTransactionsTable];
        if (item) {
            return YES;
        }
        return NO;
    }
    
    if (menuItem == self.unpairPairedRecordMenuItem) {
        NSDictionary * paired = [self actionItemsForTable:self.documentTransactionsTable];
        if (paired) {
            return YES;
        }
        return NO;
    }
    return NO;
}
@end