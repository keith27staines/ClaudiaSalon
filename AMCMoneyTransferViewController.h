//
//  AMCMoneyTransferViewController.h
//  ClaudiasSalon
//
//  Created by service on 28/09/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AMCSalonDocument.h"

@interface AMCMoneyTransferViewController : AMCViewController <NSTextDelegate>

@property (weak) IBOutlet NSPopUpButton *fromAccountPopupButton;
@property (weak) IBOutlet NSPopUpButton *toAccountPopupButton;
@property (weak) IBOutlet NSTextField *amountToTransfer;
@property (weak) IBOutlet NSButton *okButton;
@property (weak) IBOutlet NSButton *cancelButton;
@property (weak) IBOutlet NSTextField * reason;

- (IBAction)fromAccountChanged:(NSPopUpButton *)sender;

- (IBAction)toAccountChanged:(id)sender;

- (IBAction)okButonClicked:(id)sender;

- (IBAction)cancelButtonClicked:(id)sender;

@end
