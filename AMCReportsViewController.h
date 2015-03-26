//
//  AMCReportsViewController.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 21/08/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AMCReportsView.h"
#import "AMCSalonDocument.h"
@interface AMCReportsViewController : AMCViewController <AMCRecportsViewDelegate, NSTableViewDataSource, NSTableViewDelegate>

@property (weak) IBOutlet NSPopUpButtonCell *reportPeriodPopup;

@property (weak) IBOutlet NSDatePicker * yearStartStepper;

- (IBAction)reportPeriodChanged:(id)sender;

@property (weak) IBOutlet NSTableView *reportTable;
@property (weak) IBOutlet NSPopUpButton *monthStartPopup;
@property (weak) IBOutlet NSPopUpButton *weekStartPopop;
- (IBAction)monthStartChanged:(id)sender;
- (IBAction)weekStartChanged:(id)sender;
- (IBAction)yearStartChanged:(id)sender;

@end
