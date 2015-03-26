//
//  AMCSaleItemViewController.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 02/09/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

@class SaleItem, AMCSaleItemViewController;

#import <Cocoa/Cocoa.h>
#import "AMCSalonDocument.h"
@protocol AMCSaleItemViewControllerDelegate <NSObject>

-(void)saleItemViewControllerDidFinish:(AMCSaleItemViewController*)vc;

@end

@interface AMCSaleItemViewController : AMCViewController

@property SaleItem * saleItem;
@property id<AMCSaleItemViewControllerDelegate>delegate;
@property (weak) IBOutlet NSTextField *serviceNameLabel;
@property (weak) IBOutlet NSTextField *minPriceLabel;
@property (weak) IBOutlet NSTextField *maxPriceLabel;

@property (weak) IBOutlet NSTextField *priceBeforeDiscountLabel;
@property (weak) IBOutlet NSTextField *priceAfterDiscountLabel;
@property (weak) IBOutlet NSPopUpButton *discountPopupButton;
@property (weak) IBOutlet NSButton *doneButton;

@property (weak) IBOutlet NSSlider *priceBeforeDiscountSlider;

@property (weak) IBOutlet NSButton *cancelButton;

- (IBAction)priceBeforeDiscountChanged:(id)sender;

- (IBAction)discountChanged:(id)sender;

- (IBAction)cancelButtonClicked:(id)sender;
- (IBAction)doneButtonClicked:(id)sender;

@property BOOL cancelled;

@end
