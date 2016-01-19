//
//  AMCSaleItemPriceSetterView.h
//  ClaudiasSalon
//
//  Created by service on 10/09/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

@class SaleItem, AMCSaleItemPriceSetterView;

#import <Cocoa/Cocoa.h>
#import "AMCSalonDocument.h"
@protocol AMCSaleItemPriceSetterViewDelegate <NSObject>

-(void)saleItemPriceSetterView:(AMCSaleItemPriceSetterView*)view didUpdateSaleItem:(SaleItem*)saleItem;

@end

@interface AMCSaleItemPriceSetterView : NSTableCellView
@property (weak) IBOutlet NSTextField *serviceNameLabel;
@property (weak) IBOutlet NSTextField *minimumPriceLabel;
@property (weak) IBOutlet NSTextField *maximumPriceLabel;
@property (weak) IBOutlet NSTextField *nominalPriceLabel;
@property (weak) IBOutlet NSTextField *actualPriceLabel;

@property (weak) IBOutlet NSSlider *priceSlider;
@property (weak) IBOutlet NSPopUpButton *discountPopup;
@property (weak) IBOutlet NSSegmentedControl *discountTypeSegmentedControl;
- (IBAction)discountTypeChanged:(id)sender;


- (IBAction)discountChanged:(id)sender;
- (IBAction)priceChanged:(id)sender;

@property SaleItem * saleItem;
@property id<AMCSaleItemPriceSetterViewDelegate>delegate;
@end
