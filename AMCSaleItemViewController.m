//
//  AMCSaleItemViewController.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 02/09/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "AMCSaleItemViewController.h"
#import "AMCConstants.h"
#import "SaleItem.h"
#import "Sale.h"
#import "Service.h"
#import "Customer.h"
#import "Employee.h"
#import "AMCDiscountCalculator.h"

@interface AMCSaleItemViewController ()
{
    SaleItem * _saleItem;
    double actualAmount;
    double nominalAmount;
    AMCDiscountType discountType;
    long discountValue;
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
        discountValue = saleItem.discountValue.integerValue;
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
    NSPopUpButton * popup = self.discountPopupButton;
    [popup removeAllItems];
    for (int i = 0; i <= 100; i++) {
        [popup removeAllItems];
        NSString * currencySymbol = @"£";
        NSString * percentSymbol = @"%";
        NSString * discountString = @"";
        SaleItem * saleItem = [self saleItem];
        for (int i = 0; i <= 100; i++) {
            if (saleItem.discountType.integerValue == AMCDiscountTypePercentage) {
                // Percent
                discountString = [NSString stringWithFormat:@"%@ %@",@(i),percentSymbol];
            } else {
                // Absolute amount
                discountString = [NSString stringWithFormat:@"%@ %@",currencySymbol,@(i)];
            }
            [popup insertItemWithTitle:discountString atIndex:i];
        }
    }
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
    [self.discountPopupButton selectItemAtIndex:discountValue];
}
-(void)displayPriceAfterDiscount {
    actualAmount = [AMCDiscountCalculator calculateDiscountedPriceWithDiscountType:discountType discountValue:discountValue undiscountedPrice:nominalAmount];
    self.priceAfterDiscountLabel.stringValue = [NSString stringWithFormat:@"£%1.2f",actualAmount];
}
@end
