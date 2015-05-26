//
//  AMCQuickQuoteViewController.h
//  ClaudiasSalon
//
//  Created by service on 10/09/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

@class Sale, AMCQuickQuoteViewController;

#import <Cocoa/Cocoa.h>
#import "AMCSaleItemPriceSetterView.h"
#import "AMCSalonDocument.h"
@protocol AMCQuickQuoteViewControllerDelegate 
-(void)quickQuoteViewControllerDidFinish:(AMCQuickQuoteViewController*)quickQuoteViewController;
@end

@interface AMCQuickQuoteViewController : AMCViewController <NSTableViewDataSource, NSTableViewDelegate, AMCSaleItemPriceSetterViewDelegate>

@property Sale * sale;
@property id<AMCQuickQuoteViewControllerDelegate>delegate;

@property (weak) IBOutlet NSTableView *saleItemsTable;

@property (weak) IBOutlet NSTextField *priceBeforeDiscountLabel;

@property (weak) IBOutlet NSTextField *priceAfterIndividualDiscountsLabel;

@property (weak) IBOutlet NSTextField *priceAfterAdditionalDiscountLabel;

@property (weak) IBOutlet NSTextField *totalSavingForCustomerLabel;
@property (weak) IBOutlet NSPopUpButton *additionalDiscountPopupButton;

- (IBAction)okButtonClicked:(id)sender;
- (IBAction)cancelButtonClicked:(id)sender;
- (IBAction)additionalDiscountChanged:(id)sender;
@property BOOL hideCancelButton;
@property (weak) IBOutlet NSButton *cancelButton;

@end
