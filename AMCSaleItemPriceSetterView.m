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
- (IBAction)discountChanged:(id)sender {
    self.saleItem.discountType = @(self.discountPopup.indexOfSelectedItem);
    [self.saleItem updatePrice];
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
    _saleItem = saleItem;
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
    [self.discountPopup selectItemAtIndex:saleItem.discountType.integerValue];
    BOOL isEditable = !saleItem.sale.voided.boolValue && saleItem.sale.isQuote.boolValue & !saleItem.sale.voided.boolValue;
    [self.discountPopup setEnabled:isEditable];
    [self.priceSlider setEnabled:isEditable];
}


@end
