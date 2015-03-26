//
//  AMCRefundViewController.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 09/08/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

@class SaleItem;
#import <Cocoa/Cocoa.h>
#import "AMCSalonDocument.h"
@interface AMCRefundViewController : AMCViewController <NSControlTextEditingDelegate>

@property (weak) IBOutlet NSTextField *saleitemToRefundLabel;

@property (weak) IBOutlet NSTextField *amountPaidLabel;

@property (weak) IBOutlet NSTextField *actualSumToRefund;

@property (weak) IBOutlet NSNumberFormatter *amountToRefundFormatter;

@property (weak) SaleItem * saleItem;

@property BOOL cancelled;

@property (weak) IBOutlet NSButton *cancelButtonClicked;

- (IBAction)refundButtonClicked:(id)sender;
@property (weak) IBOutlet NSMatrix *refundTypeSelected;

@property (weak) IBOutlet NSTextField *refundReason;

@property (weak) IBOutlet NSButton *repayButton;
@property (weak) IBOutlet NSTextField *titleField;

@property (weak) IBOutlet NSTextField *sumToRefundField;
@end
