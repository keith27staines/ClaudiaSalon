//
//  AMCSaleItemViewController.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 02/09/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "AMCSaleItemViewController.h"
#import "AMCConstants.h"
#import "SaleItem+Methods.h"
#import "Sale+Methods.h"
#import "Service+Methods.h"
#import "Customer+Methods.h"
#import "Employee+Methods.h"
#import "AMCDiscountCalculator.h"

@interface AMCSaleItemViewController ()
{
    SaleItem * _saleItem;
    double actualAmount;
    double nominalAmount;
    AMCDiscount discountType;
    double minAmount;
    double maxAmount;
}
@end

@implementation AMCSaleItemViewController

-(NSString *)nibName {
    return @"AMCSaleItemViewController";
}

-(SaleItem *)saleItem {
    return _saleItem;
}
-(void)setSaleItem:(SaleItem *)saleItem {
    _saleItem = saleItem;
    [self view];
    [self loadDiscountPopup];
    [self resetToSaleItem];
}
-(void)resetToSaleItem {
    SaleItem * saleItem = self.saleItem;
    if (saleItem) {
        // load view from sale item
        self.serviceNameLabel.stringValue = saleItem.service.name;
        nominalAmount = saleItem.nominalCharge.doubleValue;
        actualAmount = round(saleItem.actualCharge.doubleValue);
        minAmount = floor(saleItem.minimumCharge.doubleValue);
        maxAmount = ceil(saleItem.maximumCharge.doubleValue);
        discountType = saleItem.discountType.integerValue;
        [self displayAllPriceInformation];
    }
}
-(void)displayAllPriceInformation {
    [self displayPriceBeforeDiscount];
    [self displayPriceAfterDiscount];
    [self displayDiscountType];

}
-(void)updateSaleItem {
    SaleItem * saleItem = self.saleItem;
    saleItem.nominalCharge = @(nominalAmount);
    saleItem.discountType = @(discountType);
    saleItem.actualCharge = @(actualAmount);
}
- (IBAction)priceBeforeDiscountChanged:(id)sender {
    nominalAmount = round(self.priceBeforeDiscountSlider.doubleValue);
    [self displayAllPriceInformation];
}

- (IBAction)discountChanged:(id)sender {
    discountType = self.discountPopupButton.indexOfSelectedItem;
    [self displayDiscountType];
    [self displayPriceAfterDiscount];
}

- (IBAction)cancelButtonClicked:(id)sender {
    [self.delegate saleItemViewControllerDidFinish:self];
}
- (IBAction)doneButtonClicked:(id)sender {
    [self updateSaleItem];
    [self.delegate saleItemViewControllerDidFinish:self];
}
-(void)loadDiscountPopup {
    [self.discountPopupButton removeAllItems];
    for (int i = AMCDiscountMinimum; i<=AMCDiscountMaximum; i++) {
        NSString * discountDescription = [AMCDiscountCalculator discountDescriptionforDiscount:i];
        [self.discountPopupButton insertItemWithTitle:discountDescription atIndex:i];
    }
    [self.discountPopupButton selectItemAtIndex:0];
}
-(void)displayPriceBeforeDiscount
{
    self.minPriceLabel.stringValue = [@"£" stringByAppendingFormat:@"%@",@(minAmount)];
    self.maxPriceLabel.stringValue = [@"£" stringByAppendingFormat:@"%@",@(maxAmount)];
    [self.priceBeforeDiscountSlider setMinValue:minAmount];
    [self.priceBeforeDiscountSlider setMaxValue:maxAmount];
    [self.priceBeforeDiscountSlider setDoubleValue:nominalAmount];
    self.priceBeforeDiscountLabel.stringValue = [@"£" stringByAppendingFormat:@"%@",@(nominalAmount)];
}
-(void)displayDiscountType {
    [self.discountPopupButton selectItemAtIndex:discountType];
}
-(void)displayPriceAfterDiscount {
    actualAmount = [AMCDiscountCalculator calculateDiscountedPriceWithDiscountType:discountType undiscountedPrice:nominalAmount];
    self.priceAfterDiscountLabel.stringValue = [NSString stringWithFormat:@"£%1.2f",actualAmount];
}
@end
