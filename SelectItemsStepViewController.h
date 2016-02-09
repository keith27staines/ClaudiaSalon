//
//  SelectItemsStepViewController.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 27/07/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

@class Sale, AMCQuickQuoteViewController;

#import "WizardStepViewController.h"
#import "AMCSalonDocument.h"
@interface SelectItemsStepViewController : WizardStepViewController <NSTableViewDataSource, NSTableViewDelegate, NSControlTextEditingDelegate,NSTextFieldDelegate>

@property (strong) IBOutlet AMCQuickQuoteViewController *quickQuoteViewController;

@property (weak) IBOutlet NSButton *quickQuoteButton;

@property (weak) IBOutlet NSPopUpButton *categoryPopup;

@property (weak) IBOutlet NSTableView *servicesListTable;

@property (weak) IBOutlet NSTableView *saleItemsTable;

@property (weak) IBOutlet NSButton *addSelectedServiceButton;

@property (weak) IBOutlet NSButton *removeSaleItemButton;

@property (weak) IBOutlet NSSlider *priceSlider;

@property (weak) IBOutlet NSTextField *chargePriceBeforeDiscount;

@property (weak) IBOutlet NSPopUpButton *discountPopup;

@property (weak) IBOutlet NSTextField *chargePriceAfterDiscount;
@property (weak) IBOutlet NSTextField *minimumPrice;

@property (weak) IBOutlet NSTextField *maximumPrice;

@property (weak) IBOutlet NSTextField *nameOfService;

@property (weak) IBOutlet NSTextField *hairLength;

@property (weak) IBOutlet NSTextField *nominalPriceOrPriceRange;

@property (weak) IBOutlet NSImageView *deluxeImage;
@property (weak) IBOutlet NSButton *discountInfoButton;

@property (weak) IBOutlet NSButton *productsInfoButton;

- (IBAction)categoryChanged:(id)sender;
- (IBAction)addSaleItemFromSelectedService:(id)sender;
- (IBAction)removeSaleItem:(id)sender;
- (IBAction)chargedPriceChanged:(id)sender;
- (IBAction)priceSliderChanged:(id)sender;
- (IBAction)showProductsInfo:(id)sender;
- (IBAction)showDiscountInfo:(id)sender;
- (IBAction)discountChanged:(id)sender;
@property (weak) IBOutlet NSSegmentedControl *discountTypeSegmentedControl;
//- (IBAction)discountTypeChanged:(id)sender;

@property (weak) IBOutlet NSBox *selectedSaleItemBox;
@property (weak) IBOutlet NSBox *servicesBox;
@property (weak) IBOutlet NSButton *refundButton;
- (IBAction)refundButtonClicked:(id)sender;
@property (weak) IBOutlet NSBox *selectServiceBox;
@property (weak) IBOutlet NSTextField *totalLabel;

@property (weak) IBOutlet NSNumberFormatter *numberFormatterForSelectedItemPriceBeforeDiscount;
@end
