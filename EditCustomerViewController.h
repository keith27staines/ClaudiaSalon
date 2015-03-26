//
//  EditCustomerWindowController.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 24/07/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "EditObjectViewController.h"
#import "AMCSalonDocument.h"
#import "AMCDayAndMonthPopupViewController.h"
@interface EditCustomerViewController : EditObjectViewController <AMCDayAndMonthPopupViewControllerDelegate, NSTableViewDataSource, NSTableViewDelegate>


@property (weak) IBOutlet NSTextField *firstName;

@property (weak) IBOutlet NSTextField *lastName;

@property (weak) IBOutlet NSTextField *phone;

@property (weak) IBOutlet NSTextField *email;

@property (weak) IBOutlet NSTextField *postcode;

@property (weak) IBOutlet NSTextField *addressLine1;

@property (weak) IBOutlet NSTextField *addressLine2;

@property (weak) IBOutlet NSTableView *previousVisitsTable;

@property (weak) IBOutlet NSTextField *previousVisitsLabel;

@property (strong) IBOutlet AMCDayAndMonthPopupViewController *dayAndMonthPopupButtonsController;










@end
