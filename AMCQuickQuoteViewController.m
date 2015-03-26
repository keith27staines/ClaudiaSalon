//
//  AMCQuickQuoteViewController.m
//  ClaudiasSalon
//
//  Created by service on 10/09/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "AMCQuickQuoteViewController.h"
#import "Sale+Methods.h"
#import "SaleItem+Methods.h"
#import "Service+Methods.h"
#import "Customer+Methods.h"
#import "AMCConstants.h"
#import "AMCSaleItemPriceSetterView.h"
#import "AMCSaleItemPriceSetterViewController.h"
#import "AMCDiscountCalculator.h"
#import "AMCReceiptWindowController.h"

@interface AMCQuickQuoteViewController()
{
    Sale * _sale;
}
@property (readwrite) BOOL cancelled;
@property NSArray * saleItemsArray;
@end

@implementation AMCQuickQuoteViewController

-(NSString *)nibName {
    return @"AMCQuickQuoteViewController";
}

- (IBAction)additionalDiscountChanged:(id)sender {
    self.sale.discountType = @(self.additionalDiscountPopupButton.indexOfSelectedItem);
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
    [self loadDiscountPopup:self.additionalDiscountPopupButton];
    [self updateFromSale];
    [self.cancelButton setHidden:self.hideCancelButton];
    BOOL isQuote = self.sale.isQuote.boolValue;
    if (isQuote) {
        self.printButton.title = @"Print quote";
    } else {
        self.printButton.title = @"Print receipt";
    }
}
-(void)updateFromSale {
    Sale * sale = self.sale;
    [self reloadSaleItemsTable];
    [sale updatePriceFromSaleItems];
    self.priceBeforeDiscountLabel.stringValue = [NSString stringWithFormat:@"£%1.2f",sale.nominalCharge.doubleValue];
    self.priceAfterIndividualDiscountsLabel.stringValue = [NSString stringWithFormat:@"£%1.2f",sale.chargeAfterIndividualDiscounts.doubleValue];
    self.priceAfterAdditionalDiscountLabel.stringValue = [NSString stringWithFormat:@"£%1.2f",sale.actualCharge.doubleValue];
    self.totalSavingForCustomerLabel.stringValue = [NSString stringWithFormat:@"£%1.2f)",sale.discountAmount.doubleValue];
    [self.additionalDiscountPopupButton selectItemAtIndex:self.sale.discountType.integerValue];
    BOOL isEditable = sale.isQuote.boolValue && !sale.voided.boolValue;
    [self.additionalDiscountPopupButton setEnabled:isEditable];
}
-(void)reloadSaleItemsTable {
    NSSortDescriptor * sort = [NSSortDescriptor sortDescriptorWithKey:@"createdDate" ascending:YES];
    self.saleItemsArray = [self.sale.saleItem allObjects];
    self.saleItemsArray = [self.saleItemsArray sortedArrayUsingDescriptors:@[sort]];
    [self.saleItemsTable reloadData];
}
-(void)loadDiscountPopup:(NSPopUpButton*)popup {
    [popup removeAllItems];
    for (int i = AMCDiscountMinimum; i<=AMCDiscountMaximum; i++) {
        NSString * discountDescription = [AMCDiscountCalculator discountDescriptionforDiscount:i];
        [popup insertItemWithTitle:discountDescription atIndex:i];
    }
    
}
- (IBAction)okButtonClicked:(id)sender {
    self.cancelled = NO;
    [self.delegate quickQuoteViewControllerDidFinish:self];
    [self dismissController:sender];
}

- (IBAction)printQuoteButtonClicked:(id)sender {
    self.receiptPrinterWindowController.sale = self.sale;
    [self.receiptPrinterWindowController showWindow:self];
}

- (IBAction)cancelButtonClicked:(id)sender {
    self.cancelled = YES;
    [self.delegate quickQuoteViewControllerDidFinish:self];
    [self dismissController:sender];
}

- (IBAction)addSaleItemButtonClicked:(id)sender {
}

- (IBAction)removeSaleItemButtonClicked:(id)sender {
}
#pragma mark - NSTableViewDataSource and delegate
-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.saleItemsArray.count;
}
-(NSView*)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    SaleItem * saleItem = self.saleItemsArray[row];
    AMCSaleItemPriceSetterViewController * viewController = [[AMCSaleItemPriceSetterViewController alloc] init];
    AMCSaleItemPriceSetterView * view = (AMCSaleItemPriceSetterView*)[viewController view];
    [self loadDiscountPopup:view.discountPopup];
    view.delegate = self;
    view.saleItem = saleItem;
    return view;
}
#pragma mark - AMCSaleItemPriceSetterfViewController
-(void)saleItemPriceSetterView:(AMCSaleItemPriceSetterView*)view didUpdateSaleItem:(SaleItem*)saleItem {
    [self updateFromSale];
}

@end
