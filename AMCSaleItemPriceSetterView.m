//
//  AMCSaleItemPriceSetterView.m
//  ClaudiasSalon
//
//  Created by service on 10/09/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "AMCSaleItemPriceSetterView.h"
#import "SaleItem+Methods.h"
#import "Service+Methods.h"
#import "Sale+Methods.h"
#import "AMCDiscountCalculator.h"
#import "AMCSalonDocument.h"

@interface AMCSaleItemPriceSetterView()
{
    SaleItem * _saleItem;
}

@end

@implementation AMCSaleItemPriceSetterView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}
-(void)awakeFromNib {
    
}
- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}
- (IBAction)discountTypeChanged:(id)sender {
    long index = self.discountTypeSegmentedControl.selectedSegment;
    self.saleItem.discountType = @((index == 0)?AMCDiscountTypePercentage:AMCDiscountTypeAbsoluteAmount);
    [self loadDiscountPopup];
    [self.discountPopup selectItemAtIndex:self.saleItem.discountValue.integerValue];
    [self.saleItem updatePrice];
    [self updateFromSaleItem];
    self.saleItem.bqNeedsCoreDataExport = @YES;
    self.saleItem.sale.bqNeedsCoreDataExport = @YES;
    [self.delegate saleItemPriceSetterView:self didUpdateSaleItem:self.saleItem];
}

- (IBAction)discountChanged:(id)sender {
    long index = self.discountTypeSegmentedControl.selectedSegment;
    self.saleItem.discountType = @((index == 0)?AMCDiscountTypePercentage:AMCDiscountTypeAbsoluteAmount);
    self.saleItem.discountValue = @(self.discountPopup.indexOfSelectedItem);
    [self.saleItem updatePrice];
    [self updateFromSaleItem];
    self.saleItem.bqNeedsCoreDataExport = @YES;
    self.saleItem.sale.bqNeedsCoreDataExport = @YES;
    [self.delegate saleItemPriceSetterView:self didUpdateSaleItem:self.saleItem];
}

- (IBAction)priceChanged:(id)sender {
    double price = round(self.priceSlider.doubleValue);
    self.priceSlider.doubleValue = price;
    self.saleItem.nominalCharge = @(price);
    [self.saleItem updatePrice];
    self.nominalPriceLabel.stringValue = [NSString stringWithFormat:@"Price before discount: £%1.2f",price];
    [self.delegate saleItemPriceSetterView:self didUpdateSaleItem:self.saleItem];
}
-(SaleItem *)saleItem {
    return _saleItem;
}
-(void)setSaleItem:(SaleItem *)saleItem {
    if (saleItem == _saleItem) {
        return;
    }
    _saleItem = saleItem;
    [self loadDiscountPopup];
    [self updateFromSaleItem];
}
-(void)updateFromSaleItem {
    SaleItem * saleItem = self.saleItem;
    self.serviceNameLabel.stringValue = saleItem.service.name;
    double minPrice = saleItem.minimumCharge.doubleValue;
    double maxPrice = saleItem.maximumCharge.doubleValue;
    double nominalPrice = saleItem.nominalCharge.doubleValue;
    self.priceSlider.minValue = minPrice;
    self.priceSlider.maxValue = maxPrice;
    self.priceSlider.doubleValue = nominalPrice;
    [self.priceSlider setEnabled:(maxPrice > minPrice)];
    self.minimumPriceLabel.stringValue = [NSString stringWithFormat:@"£%1.2f",minPrice];
    self.maximumPriceLabel.stringValue = [NSString stringWithFormat:@"£%1.2f",maxPrice];
    self.nominalPriceLabel.stringValue = [NSString stringWithFormat:@"Price before discount: £%1.2f",saleItem.nominalCharge.doubleValue];
    self.actualPriceLabel.stringValue  = [NSString stringWithFormat:@"Price after discount: £%1.2f",saleItem.actualCharge.doubleValue];
    [self.discountPopup selectItemAtIndex:saleItem.discountValue.integerValue];
    self.discountTypeSegmentedControl.selectedSegment = (saleItem.discountType.integerValue==AMCDiscountTypePercentage)?0:1;
    BOOL isEditable = !saleItem.sale.voided.boolValue && saleItem.sale.isQuote.boolValue & !saleItem.sale.voided.boolValue;
    [self.discountPopup setEnabled:isEditable];
    [self.priceSlider setEnabled:isEditable];
}
-(void)viewDidMoveToSuperview {
    [self setNeedsLayout:YES];
    [self setNeedsDisplay:YES];
}
-(void)loadDiscountPopup {
    NSPopUpButton * popup = self.discountPopup;
    [popup removeAllItems];
    for (int i = 0; i <= 100; i++) {
        NSString * currencySymbol = @"£";
        NSString * percentSymbol = @"%";
        NSString * discountString = @"";
        SaleItem * saleItem = self.saleItem;
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
@end
