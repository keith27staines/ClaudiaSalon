//
//  EditStockProductViewController.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 31/12/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//
#import "AMCSalonDocument.h"
#import "EditObjectViewController.h"

@interface EditStockProductViewController : EditObjectViewController
@property (weak) IBOutlet NSPopUpButton *categoryPopupButton;
@property (weak) IBOutlet NSPopUpButton *brandPopupButton;
@property (weak) IBOutlet NSPopUpButton *productNamePopup;

@property (weak) IBOutlet NSTextField *productTextField;
@property (weak) IBOutlet NSTextField *codeTextField;
@property (weak) IBOutlet NSTextField *stockLevelTextField;
@property (weak) IBOutlet NSTextField *lowStockWarningLevel;
- (IBAction)stateAffectingValidityChanged:(id)sender;
@property (weak) IBOutlet NSTextField * barcode;

@property (weak) IBOutlet NSButton *add1ToStockButton;

@property (weak) IBOutlet NSButton *remove1FromStockButton;

@property (weak) IBOutlet NSTextField *informUserLabel;


@end
