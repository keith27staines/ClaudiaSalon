//
//  AMCQuickQuoteViewController.m
//  ClaudiasSalon
//
//  Created by service on 10/09/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "AMCQuickQuoteViewController.h"
#import "Sale.h"
#import "SaleItem.h"
#import "Service.h"
#import "Customer.h"
#import "AMCConstants.h"
#import "AMCSaleItemPriceSetterView.h"
#import "AMCSaleItemPriceSetterViewController.h"
#import "AMCDiscountCalculator.h"


@interface AMCQuickQuoteViewController()
{
    Sale * _sale;
}
@property (weak) IBOutlet NSSegmentedControl *discountTypeSegmentedControl;
@property NSArray * saleItemsArray;
@end

@implementation AMCQuickQuoteViewController

-(NSString *)nibName {
    return @"AMCQuickQuoteViewController";
}
- (IBAction)additionalDiscountTypeChanged:(id)sender {
    self.sale.discountType = @((self.discountTypeSegmentedControl.selectedSegment==0)?AMCDiscountTypePercentage:AMCDiscountTypeAbsoluteAmount);
    [self loadDiscountPopup];
    [self updateFromSale];
}

- (IBAction)additionalDiscountChanged:(id)sender {
    self.sale.discountType = @((self.discountTypeSegmentedControl.selectedSegment==0)?AMCDiscountTypePercentage:AMCDiscountTypeAbsoluteAmount);
    self.sale.discountValue = @(self.additionalDiscountPopupButton.indexOfSelectedItem);
    [self updateFromSale];
}
-(Sale *)sale {
    return _sale;
}
-(void)setSale:(Sale *)sale {
    _sale = sale;
}
-(void)prepareForDisplayWithSalon:(AMCSalonDocument *)salonDocument {
    [super prepareForDisplayWithSalon:salonDocument];
    [self loadDiscountPopup];
    [self reloadSaleItemsTable];
    [self updateFromSale];
    [self.cancelButton setHidden:self.hideCancelButton];
    [self.saleItemsTable setNeedsUpdateConstraints:YES];
    [self.saleItemsTable setNeedsLayout:YES];
    [self.saleItemsTable setNeedsDisplay:YES];
    self.cancelled = NO;
}
-(void)updateFromSale {
    Sale * sale = self.sale;
    [sale updatePriceFromSaleItems];
    self.priceBeforeDiscountLabel.stringValue = [NSString stringWithFormat:@"£%1.2f",sale.nominalCharge.doubleValue];
    self.priceAfterIndividualDiscountsLabel.stringValue = [NSString stringWithFormat:@"£%1.2f",sale.chargeAfterIndividualDiscounts.doubleValue];
    self.priceAfterAdditionalDiscountLabel.stringValue = [NSString stringWithFormat:@"£%1.2f",sale.actualCharge.doubleValue];
    self.totalSavingForCustomerLabel.stringValue = [NSString stringWithFormat:@"£%1.2f)",sale.discountAmount.doubleValue];
    [self.additionalDiscountPopupButton selectItemAtIndex:self.sale.discountValue.integerValue];
    self.discountTypeSegmentedControl.selectedSegment = (sale.discountType.integerValue == AMCDiscountTypePercentage)?0:1;
    BOOL isEditable = sale.isQuote.boolValue && !sale.voided.boolValue;
    [self.additionalDiscountPopupButton setEnabled:isEditable];
}
-(void)reloadSaleItemsTable {
    NSSortDescriptor * sort = [NSSortDescriptor sortDescriptorWithKey:@"createdDate" ascending:YES];
    self.saleItemsArray = [self.sale.saleItem allObjects];
    self.saleItemsArray = [self.saleItemsArray sortedArrayUsingDescriptors:@[sort]];
    [self.saleItemsTable reloadData];
}
-(void)loadDiscountPopup {
    NSPopUpButton * popup = self.additionalDiscountPopupButton;
    [popup removeAllItems];
    for (int i = 0; i <= 100; i++) {
        [popup removeAllItems];
        NSString * currencySymbol = @"£";
        NSString * percentSymbol = @"%";
        NSString * discountString = @"";
        Sale * sale = [self sale];
        for (int i = 0; i <= 100; i++) {
            if (sale.discountType.integerValue == AMCDiscountTypePercentage) {
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
- (IBAction)okButtonClicked:(id)sender {
    self.cancelled = NO;
    [self dismissController:sender];
}
- (IBAction)cancelButtonClicked:(id)sender {
    self.cancelled = YES;
    [self dismissController:sender];
}
-(void)dismissController:(id)sender {
    [self.delegate quickQuoteViewControllerDidFinish:self];
    [super dismissController:sender];
}
#pragma mark - NSTableViewDataSource and delegate
-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.saleItemsArray.count;
}
-(NSView*)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    SaleItem * saleItem = self.saleItemsArray[row];
    AMCSaleItemPriceSetterViewController * viewController = [[AMCSaleItemPriceSetterViewController alloc] init];
    AMCSaleItemPriceSetterView * view = (AMCSaleItemPriceSetterView*)[viewController view];
    view.delegate = self;
    view.saleItem = saleItem;
    return view;
}
#pragma mark - AMCSaleItemPriceSetterfViewController
-(void)saleItemPriceSetterView:(AMCSaleItemPriceSetterView*)view didUpdateSaleItem:(SaleItem*)saleItem {
    [self updateFromSale];
}

@end
