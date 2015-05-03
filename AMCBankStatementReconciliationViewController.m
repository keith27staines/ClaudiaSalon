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
#import "Payment+Methods.h"
#import "AMCMatchingPaymentSelectorViewController.h"
#import "AMCStatementItemComputerRecordMismatchCalculator.h"

@interface AMCBankStatementReconciliationViewController () <NSTableViewDataSource, NSTableViewDelegate, NSMenuDelegate>
{
    AMCStatementItemComputerRecordMismatchCalculator * _mismatchCalc;
}
@property (weak) IBOutlet NSView *containerView;
@property NSMutableArray * dynamicConstraints;
@property NSView * subview;
@property AMCStatementParser * parser;

@property (strong) IBOutlet NSViewController *configureCSVViewController;
@property (strong) IBOutlet NSViewController *reconcileTransactionsViewController;

@property (weak) IBOutlet NSTextField *viewTitle;
@property (weak) IBOutlet NSTextField *pathLabel;

@property (weak) IBOutlet NSButton *cancelButton;
@property (weak) IBOutlet NSButton *previousButton;
@property (weak) IBOutlet NSButton *nextButton;
@property (weak) IBOutlet NSButton *doneButton;
@property (strong) IBOutlet AMCMatchingPaymentSelectorViewController *viewBestMatchesController;

@property (weak) IBOutlet NSTextField *headerLinesCountField;
@property (weak) IBOutlet NSTextField *dateColumnField;
@property (weak) IBOutlet NSTextField *grossAmountColumnField;
@property (weak) IBOutlet NSTextField *feeColumnField;
@property (weak) IBOutlet NSTextField *netAmountColumnField;
@property (weak) IBOutlet NSTextField *noteColumnField;
@property (weak) IBOutlet NSTextField *statusColumnField;
@property (weak) IBOutlet NSTextField *includeStatesField;
@property (weak) IBOutlet NSTextField *excludeStatesField;

@property (weak) IBOutlet NSTableView *csvTable;
@property (weak) IBOutlet NSTableView *statementTransactionsTable;
@property (weak) IBOutlet NSTableView *documentTransactionsTable;
@property (weak) IBOutlet NSTableView *pairedTable;

@property NSArray * filteredBankStatementRows;
@property NSMutableSet * pairedComputerRecords;
@property NSMutableSet * pairedStatementTransactions;
@property NSMutableSet * pairedRecords;
@property NSMutableArray * pairedRecordsArray;
@property (readonly) AMCStatementItemComputerRecordMismatchCalculator * mismatchCalc;

@property (weak) IBOutlet NSMenu * statementTransactionsTableContextMenu;
@property (weak) IBOutlet NSMenu * computerRecordsTableContextMenu;
@property (weak) IBOutlet NSMenu * pairedTableContextMenu;
@property (weak) IBOutlet NSMenuItem *addPairedComputerRecordsMenuItem;
@property (weak) IBOutlet NSMenuItem *voidComputerRecordMenuItem;

@property (weak) IBOutlet NSMenuItem *UnpairStatementMenuItem;
@property (weak) IBOutlet NSMenuItem *unpairComputerRecordMenuItem;
@property (weak) IBOutlet NSMenuItem *unpairPairedRecordMenuItem;

@property (weak) IBOutlet NSMenuItem *pairWithBestMatch;

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
    self.statementTransactionsTable.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"paired" ascending:YES],
                                                        [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES]];
    self.documentTransactionsTable.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"paired" ascending:YES],
                                                       [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES]];
    self.pairedTable.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"leftDate" ascending:YES]];
}
-(void)dismissViewController:(NSViewController *)viewController {
    if (viewController == self.viewBestMatchesController) {
        AMCMatchingPaymentSelectorViewController * vc = (AMCMatchingPaymentSelectorViewController*)viewController;
        AMCAccountStatementItem * item = vc.computerRecord;
        if (item) {
            NSMutableDictionary * transactionDictionary = vc.transactionDictionary;
            [self pairStatementTransaction:transactionDictionary withComputerRecord:item];
            [self reloadPairingData];
        }
    }
    [super dismissViewController:viewController];
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
        self.viewTitle.stringValue = @"Select and configure the statement file";
        self.cancelButton.enabled = YES;
        self.previousButton.enabled = NO;
        self.nextButton.enabled = YES;
        self.doneButton.enabled = NO;
        [self.csvTable reloadData];
        [self.view setNeedsUpdateConstraints:YES];
        [self.containerView setNeedsDisplay:YES];
    }
    if (self.subview == self.reconcileTransactionsViewController.view) {
        self.viewTitle.stringValue = @"Reconcile transactions with statement";
        [self reloadPairingData];
        self.cancelButton.enabled = YES;
        self.previousButton.enabled = YES;
        self.nextButton.enabled = NO;
        self.doneButton.enabled = YES;
        for (AMCAccountStatementItem * item in self.computerRecords) {
            if (![self isComputerRecordPaired:item]) {
                item.pairingRecord = nil;
            }
            item.pairingRecord = nil;
        }
        [self.view setNeedsUpdateConstraints:YES];
        [self.containerView setNeedsDisplay:YES];
        [self reloadPairingData];
        [self autoPairAll:self];
    }
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
-(AMCStatementItemComputerRecordMismatchCalculator *)mismatchCalc {
    if (!_mismatchCalc) {
        _mismatchCalc = [[AMCStatementItemComputerRecordMismatchCalculator alloc] init];
    }
    return _mismatchCalc;
}
-(void)prepareForDisplayWithSalon:(AMCSalonDocument *)salonDocument {
    [super prepareForDisplayWithSalon:salonDocument];
    self.parser = nil;
    self.subview = self.configureCSVViewController.view;
    self.pathLabel.stringValue = @"";
    [self emplaceSubview];
    [self loadCSV:self];
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
            self.parser = [[AMCStatementParser alloc] initWithCSVString:csv account:self.account];
            self.headerLinesCountField.integerValue = self.parser.headerRows;
            self.dateColumnField.integerValue = self.parser.dateCol;
            self.grossAmountColumnField.integerValue = self.parser.grossAmountColumn;
            self.noteColumnField.integerValue = self.parser.noteColumn;
            self.feeColumnField.integerValue = self.parser.feeColumn;
            self.netAmountColumnField.integerValue = self.parser.netAmountColumn;
            self.statusColumnField.integerValue = self.parser.statusColumn;
            self.includeStatesField.stringValue = self.parser.statusInclude;
            self.excludeStatesField.stringValue = self.parser.statusExclude;
            self.pathLabel.stringValue = fileURL.path;
        } else {
            self.headerLinesCountField.integerValue = 0;
            self.dateColumnField.integerValue = -1;
            self.grossAmountColumnField.integerValue = -1;
            self.feeColumnField.integerValue = -1;
            self.netAmountColumnField.integerValue = -1;
            self.statusColumnField.integerValue = -1;
            self.includeStatesField.stringValue = @"";
            self.excludeStatesField.stringValue = @"";
            self.pathLabel.stringValue = fileURL.path;
        }
    }
    [self reloadData];
}

#pragma mark - Pairing operations
-(void)unpairStatementTransaction:(NSMutableDictionary*)transactionDictionary {
    NSMutableDictionary * pairedRecord = [self pairingRecordForStatementTransaction:transactionDictionary];
    [self unpairPairedRecord:pairedRecord];
}
-(void)unpairPairedRecord:(NSMutableDictionary*)pairedRecord {
    if (!pairedRecord) {return;}
    AMCAccountStatementItem * item = pairedRecord[@"computerRecord"];
    NSMutableDictionary * transactionDictionary = pairedRecord[@"statementTransaction"];
    
    [self.pairedStatementTransactions removeObject:transactionDictionary];
    [self.pairedComputerRecords removeObject:item];
    item.pairingRecord = nil;
    transactionDictionary[@"paired"] = @"";

    [self.pairedRecords removeObject:pairedRecord];
    [self.pairedRecordsArray removeObject:pairedRecord];
}
-(void)unpairComputerRecord:(AMCAccountStatementItem*)item {

    NSMutableDictionary * pairedRecord = [self pairingRecordForComputerRecord:item];
    [self unpairPairedRecord:pairedRecord];
}
-(NSInteger)pairStatementTransaction:(NSMutableDictionary*)transactionDictionary withComputerRecord:(AMCAccountStatementItem*)item {
    // Break existing pairings
    [self unpairStatementTransaction:transactionDictionary];
    [self unpairComputerRecord:item];
    
    // Create new pairingRecord
    double mismatch = [self.mismatchCalc mismatchBetweenTransactionDictionary:transactionDictionary item:item];
    double dateMismatch = [self.mismatchCalc mismatchFirstDate:transactionDictionary[@"date"] secondDate:item.date];
    double amountMismatch = [self.mismatchCalc mismatchFirstAmount:transactionDictionary[@"amount"] secondAmount:@(item.signedAmountGross)];
    NSDictionary * pairedRecord = @{@"statementTransaction":transactionDictionary,
                                    @"computerRecord":item,
                                    @"mismatch":@(mismatch),
                                    @"dateMismatch":@(dateMismatch),
                                    @"amountMismatch":@(amountMismatch)};
    [self.pairedRecords addObject:pairedRecord];
    [self.pairedRecordsArray addObject:pairedRecord];
    [self.pairedComputerRecords addObject:item];
    [self.pairedStatementTransactions addObject:transactionDictionary];
    item.pairingRecord = pairedRecord;
    transactionDictionary[@"paired"] = @"Y";
    return self.pairedRecords.count - 1;
}
-(BOOL)isComputerRecordPaired:(AMCAccountStatementItem*)item {
    return [self.pairedComputerRecords containsObject:item];
}
-(BOOL)isStatementTransactionPaired:(NSDictionary*)transactionDictionary {
    return [self.pairedStatementTransactions containsObject:transactionDictionary];
}
-(NSMutableDictionary*)pairingRecordForStatementTransaction:(NSDictionary*)statementTransaction {
    if ([self isStatementTransactionPaired:statementTransaction]) {
        for (NSMutableDictionary * pairing in self.pairedRecords) {
            if (pairing[@"statementTransaction"] == statementTransaction) {
                return pairing;
            }
        }
    }
    return nil;
}
-(NSMutableDictionary*)pairingRecordForComputerRecord:(AMCAccountStatementItem*)item {
    if ([self isComputerRecordPaired:item]) {
        for (NSMutableDictionary * pairing in self.pairedRecords) {
            if (pairing[@"computerRecord"] == item) {
                return pairing;
            }
        }
    }
    return nil;
}
-(AMCAccountStatementItem*)unpairedExactMatchForStatementTransaction:(NSMutableDictionary*)transactionDictionary {
    NSMutableArray * matches = [self computerRecordsMatchingDateAndAmount:transactionDictionary];
    for (NSDictionary * dictionary in matches) {
        NSNumber * mismatchNumber = dictionary[@"mismatch"];
        if (mismatchNumber.doubleValue == 0) {
            AMCAccountStatementItem * item = dictionary[@"item"];
            if (!item.pairingRecord) {
                return item;
            }
        }
    }
    return nil;
}
#pragma mark - Matching calculations
-(NSMutableArray*)computerRecordsMatchingDateAndAmount:(NSMutableDictionary*)transactionDictionary {
    NSDate * firstDate = transactionDictionary[@"date"];
    NSNumber * firstAmount = transactionDictionary[@"amount"];
    NSNumber * firstFee = transactionDictionary[@"fee"];
    NSNumber * firstAmountNet = transactionDictionary[@"amountNet"];
    NSMutableArray * matchingComputerRecords = [NSMutableArray array];
    for (AMCAccountStatementItem * item in self.computerRecords) {
        NSDate * secondDate = item.date;
        NSNumber * secondAmount = @(item.signedAmountGross);
        NSNumber * secondFee = @(item.transactionFee);
        NSNumber * secondAmountNet = @(item.signedAmountNet);
        double dateMismatch = [self.mismatchCalc mismatchFirstDate:firstDate secondDate:secondDate];
        double amountMismatch = [self.mismatchCalc mismatchFirstAmount:firstAmount secondAmount:secondAmount];
        double mismatch = [self.mismatchCalc mismatchBetweenTransactionDictionary:transactionDictionary item:item];
        NSMutableDictionary * dictionary = [NSMutableDictionary dictionary];
        dictionary[@"mismatch"] = @(mismatch);
        dictionary[@"dateMismatch"] = @(dateMismatch);
        dictionary[@"amountMismatch"] = @(amountMismatch);
        dictionary[@"item"] = item;
        if (firstFee) {
            dictionary[@"feeMismatch"] = @([self.mismatchCalc mismatchFirstFee:firstFee secondFee:secondFee]);
        }
        if (firstAmountNet) {
            dictionary[@"amountNetMismatch"] = @([self.mismatchCalc mismatchFirstNetAmount:firstAmountNet secondNetAmount:secondAmountNet]);
        }
        [matchingComputerRecords addObject:dictionary];
    }
    [matchingComputerRecords sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"mismatch" ascending:YES],
                                                    [NSSortDescriptor sortDescriptorWithKey:@"dateMismatch" ascending:YES],
                                                    [NSSortDescriptor sortDescriptorWithKey:@"amountMismatch" ascending:YES]]];
    return matchingComputerRecords;
}

#pragma mark - Actions for wizard steps

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

#pragma mark - Actions for CSV configuration
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
- (IBAction)statusColumnChanged:(id)sender {
    [self.csvTable deselectAll:self];
    NSInteger statusColumn = self.statusColumnField.integerValue;
    self.parser.statusColumn = statusColumn;
    if (statusColumn >=0) {
        NSIndexSet * indexSet = [NSIndexSet indexSetWithIndex:statusColumn];
        [self.csvTable selectColumnIndexes:indexSet byExtendingSelection:NO];
        [self.csvTable scrollColumnToVisible:statusColumn];
    }
}
- (IBAction)includeStatesChanged:(id)sender {
    self.parser.statusInclude = self.includeStatesField.stringValue;
}
- (IBAction)excludeStatesChanged:(id)sender {
    self.parser.statusExclude = self.excludeStatesField.stringValue;
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

#pragma mark - Actions for pairing
- (IBAction)viewBestMatches:(id)sender {
    NSMutableDictionary * transactionDictionary = [self actionItemsForTable:self.statementTransactionsTable];
    if (transactionDictionary) {
        // prepare controller for display
        self.viewBestMatchesController.transactionDictionary = transactionDictionary;
        self.viewBestMatchesController.pairingRecords = [self computerRecordsMatchingDateAndAmount:transactionDictionary];
        [self.viewBestMatchesController prepareForDisplayWithSalon:self.salonDocument];
        // figure out where to present it
        NSInteger row = [self.statementTransactionsTable clickedRow];
        NSInteger col = [self.statementTransactionsTable clickedColumn];
        NSRect cellFrame = [self.statementTransactionsTable frameOfCellAtColumn:row row:col];
        // Now we can present it
        [self presentViewController:self.viewBestMatchesController asPopoverRelativeToRect:cellFrame ofView:self.statementTransactionsTable preferredEdge:NSMaxXEdge behavior:NSPopoverBehaviorApplicationDefined];
    }
}
- (IBAction)unpairClickeditem:(id)sender {
    if (sender == self.UnpairStatementMenuItem) {
        // User was clicking on statement item
        NSMutableDictionary * transactionDictionary = [self actionItemsForTable:self.statementTransactionsTable];
        [self unpairStatementTransaction:transactionDictionary];
    } else if (sender == self.unpairComputerRecordMenuItem) {
        // User was clicking on a computer record
        AMCAccountStatementItem * item = [self actionItemsForTable:self.documentTransactionsTable];
        [self unpairComputerRecord:item];
    } else if (sender == self.unpairPairedRecordMenuItem) {
        // User was clicking on a paired record
        NSMutableDictionary * pairedRecord = [self actionItemsForTable:self.pairedTable];
        NSMutableDictionary * transactionDictionary = pairedRecord[@"statementTransaction"];
        [self unpairStatementTransaction:transactionDictionary];
    }
    [self reloadPairingData];
}
- (IBAction)addMatchingComputerRecord:(id)sender {
    NSAlert * alert = [[NSAlert alloc] init];
    alert.messageText = @"Add payment to match statement item";
    alert.informativeText = @"A payment will be added to exactly match the statement item";
    [alert addButtonWithTitle:@"Add payment"];
    [alert addButtonWithTitle:@"Cancel"];
    
    if ([alert runModal] == NSModalResponseCancel) {return;}
    
    NSInteger statementTransactionIndex = self.statementTransactionsTable.selectedRow;
    NSMutableDictionary * transactionDictionary = self.parser.transactionDictionaries[statementTransactionIndex];
    [self unpairStatementTransaction:transactionDictionary];
    Payment * payment = [Payment newObjectWithMoc:self.documentMoc];
    payment.paymentDate = transactionDictionary[@"date"];
    double amount = ((NSNumber*)transactionDictionary[@"amount"]).doubleValue;
    double fee = ((NSNumber*)transactionDictionary[@"fee"]).doubleValue;
    double netAmount = ((NSNumber*)transactionDictionary[@"amountNet"]).doubleValue;
    if (amount > 0) {
        payment.direction = kAMCPaymentDirectionIn;
    } else {
        payment.direction = kAMCPaymentDirectionOut;
    }
    payment.paymentCategory = self.salonDocument.salon.defaultPaymentCategoryForPayments;
    payment.amount = @(fabs(amount));
    payment.transactionFee = @(fabs(fee));
    payment.amountNet = @(fabs(netAmount));
    payment.account = self.account;
    payment.paymentCategory = nil;
    AMCAccountStatementItem * item = [[AMCAccountStatementItem alloc] initWithPayment:payment];
    [self.computerRecords addObject:item];
    [self pairStatementTransaction:transactionDictionary withComputerRecord:item];
    [self reloadPairingData];
}
- (IBAction)voidItem:(id)sender {
    AMCAccountStatementItem * item = [self actionItemsForTable:self.documentTransactionsTable];
    [self unpairComputerRecord:item];
    [item voidTransaction];
    [self.computerRecords removeObject:item];
    [self reloadPairingData];
}
- (IBAction)autoPairAll:(id)sender {
    for (NSMutableDictionary * transactionDictionary in self.parser.transactionDictionaries) {
        AMCAccountStatementItem * exactMatch = [self unpairedExactMatchForStatementTransaction:transactionDictionary];
        if (exactMatch) {
            [self pairStatementTransaction:transactionDictionary withComputerRecord:exactMatch];
        }
    }
    [self reloadPairingData];
}

#pragma mark - NSTableView

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
-(BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    return NO;
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
        if ([tableColumn.identifier isEqualToString:@"paired"]) {
            return (item.paired)?@"Y":@"";
        }
        if ([tableColumn.identifier isEqualToString:@"date"]) {
            return item.date;
        }
        if ([tableColumn.identifier isEqualToString:@"amount"]) {
            return @(item.signedAmountGross);
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
            return @(item.signedAmountGross);
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
    static BOOL entered = NO;
    if (entered) {
        return;
    }
    entered = YES;
    NSTableView * table = notification.object;
    NSInteger statementTransactionIndex = -1;
    NSInteger pairedIndex = -1;
    NSInteger computerRecordIndex = -1;
    NSMutableDictionary * transactionDictionary = nil;
    AMCAccountStatementItem * item = nil;
    NSMutableDictionary * pairedRecord = nil;
    if (notification.object == self.statementTransactionsTable) {
        statementTransactionIndex = self.statementTransactionsTable.selectedRow;
        if (statementTransactionIndex >=0) {
            transactionDictionary = self.parser.transactionDictionaries[statementTransactionIndex];
            pairedRecord = [self pairingRecordForStatementTransaction:transactionDictionary];
            pairedIndex = [self.pairedRecordsArray indexOfObject:pairedRecord];
            item = pairedRecord[@"computerRecord"];
            computerRecordIndex = [self.computerRecords indexOfObject:item];
        }
    }
    if (notification.object == self.documentTransactionsTable) {
        computerRecordIndex = [self.documentTransactionsTable selectedRow];
        if (computerRecordIndex >= 0) {
            item = self.computerRecords[computerRecordIndex];
            pairedRecord = [self pairingRecordForComputerRecord:item];
            pairedIndex = [self.pairedRecordsArray indexOfObject:pairedRecord];
            transactionDictionary = pairedRecord[@"statementTransaction"];
            statementTransactionIndex = [self.parser.transactionDictionaries indexOfObject:transactionDictionary];
        }
    }
    if (notification.object == self.pairedTable) {
        pairedIndex = self.pairedTable.selectedRow;
        if (pairedIndex >= 0) {
            pairedRecord = self.pairedRecordsArray[pairedIndex];
            pairedIndex = [self.pairedRecordsArray indexOfObject:pairedRecord];
            transactionDictionary = pairedRecord[@"statementTransaction"];
            statementTransactionIndex = [self.parser.transactionDictionaries indexOfObject:transactionDictionary];
            item = pairedRecord[@"computerRecord"];
            computerRecordIndex = [self.computerRecords indexOfObject:item];
        }
    }
    if (table != self.statementTransactionsTable) {
        if (statementTransactionIndex < 0 || statementTransactionIndex == NSNotFound) {
            [self.statementTransactionsTable deselectAll:self];
        } else {
            [self.statementTransactionsTable selectRowIndexes:[NSIndexSet indexSetWithIndex:statementTransactionIndex] byExtendingSelection:NO];
            [self.statementTransactionsTable scrollRowToVisible:statementTransactionIndex];
        }
    }
    if (table != self.documentTransactionsTable) {
        if (computerRecordIndex < 0  || computerRecordIndex == NSNotFound) {
            [self.documentTransactionsTable deselectAll:self];
        } else {
            [self.documentTransactionsTable selectRowIndexes:[NSIndexSet indexSetWithIndex:computerRecordIndex] byExtendingSelection:NO];
            [self.documentTransactionsTable scrollRowToVisible:computerRecordIndex];
        }
    }
    if (table != self.pairedTable) {
        if (pairedIndex < 0  || pairedIndex == NSNotFound) {
            [self.pairedTable deselectAll:self];
        } else {
            [self.pairedTable selectRowIndexes:[NSIndexSet indexSetWithIndex:pairedIndex] byExtendingSelection:NO];
            [self.pairedTable scrollRowToVisible:pairedIndex];
        }
    }
    entered = NO;
}
-(void)tableView:(NSTableView *)tableView sortDescriptorsDidChange:(NSArray *)oldDescriptors {
    if (tableView == self.statementTransactionsTable) {
        self.parser.sortDescriptorsForTransactionDictionaries = self.statementTransactionsTable.sortDescriptors;
        [self.statementTransactionsTable reloadData];
    }
    if (tableView == self.documentTransactionsTable) {
        [self.computerRecords sortUsingDescriptors:self.documentTransactionsTable.sortDescriptors];
        [self.documentTransactionsTable reloadData];
    }
    if (tableView == self.pairedTable) {
        [self.pairedRecordsArray sortUsingDescriptors:self.pairedTable.sortDescriptors];
        [self.pairedTable reloadData];
    }
}

#pragma mark - NSMenuDelegate

-(void)menuNeedsUpdate:(NSMenu *)menu {
    
}
-(void)menuWillOpen:(NSMenu*)menu {
    
}
#pragma mark - Menu validation
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
-(BOOL)validateMenuItem:(NSMenuItem *)menuItem {
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
        NSDictionary * paired = [self actionItemsForTable:self.pairedTable];
        if (paired) {
            return YES;
        }
        return NO;
    }
    if (menuItem == self.pairWithBestMatch) {
        NSMutableDictionary * statementDictionary = [self actionItemsForTable:self.statementTransactionsTable];
        if (statementDictionary) {
            if ([self isStatementTransactionPaired:statementDictionary]) {
                return NO;
            }
            return YES;
        }
        return NO;
    }
    return NO;
}
#pragma mark - Reload pairing tables
-(void)reloadPairingData {
    self.parser.sortDescriptorsForTransactionDictionaries = self.statementTransactionsTable.sortDescriptors;
    [self.computerRecords sortUsingDescriptors:self.documentTransactionsTable.sortDescriptors];
    [self.pairedRecordsArray sortUsingDescriptors:self.pairedTable.sortDescriptors];
    [self.statementTransactionsTable reloadData];
    [self.documentTransactionsTable reloadData];
    [self.pairedTable reloadData];
}
-(void)reloadData {
    [super reloadData];
    self.pairedStatementTransactions = [NSMutableSet set];
    self.pairedComputerRecords = [NSMutableSet set];
    self.pairedRecords = [NSMutableSet set];
    self.pairedRecordsArray = [NSMutableArray array];
    [self.csvTable reloadData];
}
@end
