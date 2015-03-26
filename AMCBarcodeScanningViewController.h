//
//  AMCBarcodeScanningViewController.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 10/01/2015.
//  Copyright (c) 2015 Keith Staines. All rights reserved.
//
@class EditStockProductViewController, AMCProductSelectorWindowController;
#import <Cocoa/Cocoa.h>
#import "AMCSalonDocument.h"
#import "EditStockProductViewController.h"

@interface AMCBarcodeScanningViewController : AMCViewController <EditObjectViewControllerDelegate>

@property (weak) IBOutlet NSView *actionContainerView;

@property (strong) IBOutlet NSViewController *actionViewController;
@property (weak) IBOutlet NSTextField *barcode;
- (IBAction)barcodeScanned:(id)sender;
-(void)prepareForScan;
@property (weak) IBOutlet NSTextField *barcodeRecognisedLabel;
@property (weak) IBOutlet NSImageView *scanResultImage;
- (IBAction)createProduct:(id)sender;

- (IBAction)associateBarcode:(id)sender;

- (IBAction)ignoreBarcode:(id)sender;

@property (strong) IBOutlet EditStockProductViewController *stockedProductEditor;
@property (strong) IBOutlet AMCProductSelectorWindowController *productSelectorWindowController;


@end
