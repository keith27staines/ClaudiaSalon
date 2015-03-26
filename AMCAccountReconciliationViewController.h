//
//  AMCAccountReconciliationViewController.h
//  ClaudiasSalon
//
//  Created by service on 17/09/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

@class Account;

#import <Cocoa/Cocoa.h>
#import "AMCSalonDocument.h"
@interface AMCAccountReconciliationViewController : AMCViewController <NSTableViewDataSource, NSTableViewDelegate, NSTextDelegate>

@property (weak) IBOutlet NSTextField *reconcileAccountLabel;

@property (weak) IBOutlet NSTextField *bankNameLabel;
@property (weak) IBOutlet NSTextField *sortCodeLabel;
@property (weak) IBOutlet NSTextField *accountNumberLabel;
@property (weak) IBOutlet NSTextField *expectedBalance;
@property Account * account;
@property (weak) IBOutlet NSButton *addReconciliationButton;
@property (weak) IBOutlet NSButton *removeReconciliationButton;

- (IBAction)addReconciliationButtonClicked:(id)sender;
- (IBAction)removeReconciliationButtonClicked:(id)sender;

@property (weak) IBOutlet NSTableView *reconciliationsTable;

@property (weak) IBOutlet NSPopUpButton *accountsPopupButton;

- (IBAction)accountChanged:(NSPopUpButton *)sender;
@property (weak) IBOutlet NSDatePicker *dateForBalance;
- (IBAction)dateForBalanceChanged:(id)sender;

@end
