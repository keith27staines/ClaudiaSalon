//
//  AMCBankStatementReconciliationViewController.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 06/04/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "AMCBankStatementReconciliationViewController.h"
#import "AMCStatementParser.h"

@interface AMCBankStatementReconciliationViewController () <NSTableViewDataSource, NSTableViewDelegate>
@property (weak) IBOutlet NSTextField *viewTitle;
@property (weak) IBOutlet NSTextField * pathLabel;
@property (weak) IBOutlet NSTableView *csvTable;
@property (weak) IBOutlet NSTextField *headerLinesCountField;

@property (weak) IBOutlet NSTextField *dateColumnField;

@property (weak) IBOutlet NSTextField *grossAmountColumnField;
@property (weak) IBOutlet NSTextField *feeColumnField;
@property (weak) IBOutlet NSTextField *netAmountColumnField;

@property (strong) IBOutlet NSViewController *configureCSVViewController;
@property (strong) IBOutlet NSViewController *reconcileTransactionsViewController;

@property (weak) IBOutlet NSView *containerView;
@property NSMutableArray * dynamicConstraints;

@property NSView * subview;
@property AMCStatementParser * parser;

@end

@implementation AMCBankStatementReconciliationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSInteger i = 0;
    for (NSTableColumn * column in self.csvTable.tableColumns) {
        column.title = [NSString stringWithFormat:@"Col%lu",i];
        column.identifier = [NSString stringWithFormat:@"Col%lu",i];
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
    otherConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(>=0)-[subview]-(>=0)-|" options:0 metrics:nil views:views];
    [self.dynamicConstraints addObjectsFromArray:otherConstraints];
    [containerView addConstraints:otherConstraints];
    otherConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(>=0)-[subview]-(>=0)-|" options:0 metrics:nil views:views];
    [self.dynamicConstraints addObjectsFromArray:otherConstraints];
    [containerView addConstraints:otherConstraints];
}
-(void)prepareForDisplayWithSalon:(AMCSalonDocument *)salonDocument {
    [super prepareForDisplayWithSalon:salonDocument];
    self.subview = self.configureCSVViewController.view;
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
        [self.csvTable reloadData];
    }
}
- (IBAction)headerLinesCountChanged:(id)sender {
    [self.csvTable deselectAll:self];
    NSInteger headerLines = self.headerLinesCountField.integerValue;
    if (headerLines >=0) {
        NSMutableIndexSet * indexSet = [NSMutableIndexSet indexSet];
        for (NSInteger i = 0; i < headerLines; i++) {
            [indexSet addIndex:i];
        }
        [self.csvTable selectRowIndexes:indexSet byExtendingSelection:NO];
        [self.csvTable scrollRowToVisible:0];
        [self.csvTable scrollRowToVisible:headerLines-1];
    }
}
- (IBAction)dateColumnChanged:(id)sender {
    [self.csvTable deselectAll:self];
    NSInteger dateColumn = self.dateColumnField.integerValue;
    if (dateColumn >=0) {
        NSIndexSet * indexSet = [NSIndexSet indexSetWithIndex:dateColumn];
        [self.csvTable selectColumnIndexes:indexSet byExtendingSelection:NO];
        [self.csvTable scrollColumnToVisible:dateColumn];
    }
}
- (IBAction)grossAmountColumnChanged:(id)sender {
    [self.csvTable deselectAll:self];
    NSInteger grossAmountColumn = self.grossAmountColumnField.integerValue;
    if (grossAmountColumn >=0) {
        NSIndexSet * indexSet = [NSIndexSet indexSetWithIndex:grossAmountColumn];
        [self.csvTable selectColumnIndexes:indexSet byExtendingSelection:NO];
        [self.csvTable scrollColumnToVisible:grossAmountColumn];
    }
}
- (IBAction)feeColumnChanged:(id)sender {
    [self.csvTable deselectAll:self];
    NSInteger feeColumn = self.feeColumnField.integerValue;
    if (feeColumn >=0) {
        NSIndexSet * indexSet = [NSIndexSet indexSetWithIndex:feeColumn];
        [self.csvTable selectColumnIndexes:indexSet byExtendingSelection:NO];
        [self.csvTable scrollColumnToVisible:feeColumn];
    }
}
- (IBAction)netAmountColumnChanged:(id)sender {
    [self.csvTable deselectAll:self];
    NSInteger netAmountColumn = self.netAmountColumnField.integerValue;
    if (netAmountColumn >=0) {
        NSIndexSet * indexSet = [NSIndexSet indexSetWithIndex:netAmountColumn];
        [self.csvTable selectColumnIndexes:indexSet byExtendingSelection:NO];
        [self.csvTable scrollColumnToVisible:netAmountColumn];
    }
}
-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    if (!self.parser) return 0;
    return self.parser.rowCount;
}

-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    return [self.parser objectForColumnWithIdentifier:tableColumn.identifier row:row];
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
