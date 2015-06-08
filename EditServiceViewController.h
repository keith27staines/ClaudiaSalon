//
//  EditServiceViewController.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 22/07/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "EditObjectViewController.h"
#import "AMCSalonDocument.h"
@interface EditServiceViewController : EditObjectViewController
@property (weak) IBOutlet NSTextField *nameField;
@property (weak) IBOutlet NSTextField *timeRequired;
@property (weak) IBOutlet NSTextField *nominalPrice;
@property (weak) IBOutlet NSImageView *deluxeBadge;
@property (weak) IBOutlet NSButton *deluxeCheckbox;

@property (weak) IBOutlet NSTextField *minimumPrice;
@property (weak) IBOutlet NSTextField *maximumPrice;
@property (weak) IBOutlet NSSlider *priceSlider;

- (IBAction)minimumPriceChanged:(id)sender;

- (IBAction)maximumPriceChanged:(id)sender;

- (IBAction)nominalPriceChanged:(id)sender;
- (IBAction)deluxeChanged:(id)sender;

@end
