//
//  AMCBarcodeScanningViewController.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 10/01/2015.
//  Copyright (c) 2015 Keith Staines. All rights reserved.
//

#import "AMCBarcodeScanningViewController.h"
#import "StockedProduct+Methods.h"
#import "StockedBrand+Methods.h"
#import "EditStockProductViewController.h"
#import "AMCProductSelectorWindowController.h"
#import "AMCSalonDocument.h"

@interface AMCBarcodeScanningViewController ()
{

}
@property StockedProduct * product;
@property BOOL scanningEnabled;
@end

@implementation AMCBarcodeScanningViewController

-(NSString *)nibName {
    return @"AMCBarcodeScanningViewController";
}
-(void)dismissController:(id)sender {
    self.scanningEnabled = NO;
    [super dismissController:sender];
}
- (IBAction)barcodeScanned:(id)sender {
    if (!self.scanningEnabled || self.barcode.stringValue.length == 0) {
        return;
    }
    if ([self isBarcodeRecognised]) {
        [self barcodeRecognised];
    } else {
        [self barcodeUnrecognised];
    }
}
-(BOOL)isBarcodeRecognised {
    NSString * barcode = self.barcode.stringValue;
    self.product = [StockedProduct fetchProductWithBarcode:barcode withMoc:self.documentMoc];
    return (self.product!=nil);
}
-(void)prepareForScan {
    [self view];
    self.barcode.stringValue = @"";
    self.scanningEnabled = YES;
    [self removeActionView];
    [self.scanResultImage setHidden:YES];
    [self.barcodeRecognisedLabel setHidden:YES];
}
-(void)removeActionView {
    NSView * view = self.actionViewController.view;
    if (view.superview) {
        [view removeFromSuperview];
    }
}
-(void)addActionView {
    NSView * containerView = self.actionContainerView;
    NSView * actionView = [self.actionViewController view];
    actionView.translatesAutoresizingMaskIntoConstraints = NO;
    [containerView addSubview:actionView];
    NSDictionary * views = NSDictionaryOfVariableBindings(actionView,containerView);
    NSArray * constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[actionView]|" options:0 metrics:nil views:views];
    [containerView addConstraints:constraints];
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[actionView]|" options:0 metrics:nil views:views];
    [containerView addConstraints:constraints];
}
-(void)barcodeRecognised {
    [self.scanResultImage setHidden:NO];
    [self.barcodeRecognisedLabel setHidden:NO];
    self.barcodeRecognisedLabel.stringValue = @"Barcode recognised!";
    [self.scanResultImage setImage:[[NSBundle mainBundle] imageForResource:@"GreenTickIcon"]];
    [self removeActionView];
    [self editProduct];
}
-(void)barcodeUnrecognised {
    [self.scanResultImage setHidden:NO];
    [self.barcodeRecognisedLabel setHidden:NO];
    self.barcodeRecognisedLabel.stringValue = @"Barcode not recognised!";
    [self.scanResultImage setImage:[[NSBundle mainBundle] imageForResource:@"RedCrossIcon"]];
    [self addActionView];
}
-(void)editObject:(id)object inMode:(EditMode)editMode withViewController:(EditObjectViewController*)viewController
{
    if (object) {
        viewController.delegate = self;
        viewController.editMode = editMode;
        [viewController clear];
        viewController.objectToEdit = object;
        [viewController prepareForDisplayWithSalon:self.salonDocument];
        [self presentViewControllerAsSheet:viewController];
    }
}
-(void)editProduct {
    [self editObject:self.product inMode:EditModeEdit withViewController:self.stockedProductEditor];
}
-(void)viewProduct {
    [self editObject:self.product inMode:EditModeView withViewController:self.stockedProductEditor];
}
- (IBAction)createProduct:(id)sender {
    self.product = [StockedProduct createObjectInMoc:self.documentMoc];
    self.product.barcode = self.barcode.stringValue;
    [self editObject:self.product inMode:EditModeCreate withViewController:self.stockedProductEditor];
}

- (IBAction)associateBarcode:(id)sender {
    self.productSelectorWindowController.callingWindow = self.view.window;
    self.productSelectorWindowController.document = self.salonDocument;
    NSWindow * window = [self.productSelectorWindowController window];
    [self.view.window beginSheet:window completionHandler:^(NSModalResponse returnCode) {
        self.product = self.productSelectorWindowController.product;
        StockedProduct * product = self.product;
        if (product) {
            product.barcode = self.barcode.stringValue;
            NSAlert * alert = [[NSAlert alloc] init];
            alert.messageText = @"Barcode assigned to product";
            alert.informativeText = [NSString stringWithFormat:@"The barcode %@ is now associated with %@ %@ %@",self.product.barcode,self.product.stockedBrand.shortBrandName,product.name,product.code];
            [alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
                [self editProduct];
                [self prepareForScan];
            }];
        } else {
            [self prepareForScan];
        }
    }];
}

- (IBAction)ignoreBarcode:(id)sender {
    [self prepareForScan];
}
-(void)editObjectViewController:(EditObjectViewController *)controller didCancelCreationOfObject:(id)object {
    if (object) {
        if (object == self.product) {
            [self.documentMoc deleteObject:object];
        }
    }
    [self prepareForScan];
}
-(void)editObjectViewController:(EditObjectViewController *)controller didCompleteCreationOfObject:(id)object {
    [self prepareForScan];
}
-(void)editObjectViewController:(EditObjectViewController *)controller didEditObject:(id)object {
    [self prepareForScan];
}


@end
