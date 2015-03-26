//
//  AMCStockedCategoryMaintenanceViewController.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 02/01/2015.
//  Copyright (c) 2015 Keith Staines. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AMCConstants.h"
#import "AMCSalonDocument.h"
@interface AMCStockedCategoryMaintenanceViewController : AMCViewController

@property (weak) IBOutlet NSPopUpButton *stockedCategoryPopup;


@property (weak) IBOutlet NSTextField *categoryNameTextField;

@property (weak) IBOutlet NSTextField *errorLabel;

- (IBAction)categoryChanged:(id)sender;

- (IBAction)categoryNameChanged:(NSTextField *)sender;
@property (weak) IBOutlet NSButton *okButton;
@property (weak) IBOutlet NSButton *cancelButton;

@end
