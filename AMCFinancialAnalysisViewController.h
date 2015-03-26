//
//  AMCFinancialAnalysisWindowController.h
//  ClaudiasSalon
//
//  Created by service on 18/01/2015.
//  Copyright (c) 2015 Keith Staines. All rights reserved.
//


@class AMCDateRangeSelectorViewController, EditPaymentViewController;
#import <Cocoa/Cocoa.h>
#import "AMCSalonDocument.h"
#import "AMCDateRangeSelectorViewController.h"

@interface AMCFinancialAnalysisViewController : AMCViewController <NSTableViewDataSource, NSTableViewDelegate, AMCDateRangeSelectorViewControllerDelegate>

@property (strong) IBOutlet NSViewController *analysisViewController;
@property (weak) IBOutlet NSView *containerView;


@property (weak) IBOutlet NSPopUpButton *categoryPopup;

@property (weak) IBOutlet NSTableView *dataTable;

@property (weak) IBOutlet NSTextField *moneyInLabel;
@property (weak) IBOutlet NSTextField *moneyOutLabel;
@property (weak) IBOutlet NSTextField * balanceLable;

@property (weak) IBOutlet NSTextField *balanceLabel;

- (IBAction)categoryChanged:(id)sender;

@property (weak) IBOutlet NSSegmentedCell *viewSelector;

- (IBAction)viewSelectorChanged:(id)sender;

@property (strong) IBOutlet NSViewController *summaryViewController;

@property (weak) IBOutlet NSTextField *startupCostLabel;

@property (weak) IBOutlet NSTextField *directorsLoanLabel;
@property (strong) IBOutlet NSArrayController *summaryArrayController;

@property (strong) IBOutlet AMCDateRangeSelectorViewController *summaryDateRangeViewController;
@property (weak) IBOutlet NSBox *summaryDateRangeBox;
@property (weak) IBOutlet AMCDateRangeSelectorViewController *categoryDateRangeViewController;
@property (weak) IBOutlet NSBox * categoryDateRangeBox;

@property (weak) IBOutlet NSTextField *salesInPeriodLabel;

@property (weak) IBOutlet NSTextField *expenditureInPeriodLabel;

@property (weak) IBOutlet NSTextField *profitInPeriodLabel;

@property (strong) IBOutlet EditPaymentViewController *editPaymentWindowController;
@property (weak) IBOutlet NSButton *viewPaymentDetailsButton;
- (IBAction)viewPaymentsButtonClicked:(id)sender;

@end
