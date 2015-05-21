//
//  AMCStockControlViewController.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 28/12/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "AMCStockControlViewController.h"
#import "NSDate+AMCDate.h"
#import "StockedCategory+Methods.h"
#import "StockedItem+Methods.h"
#import "StockedBrand+Methods.h"
#import "StockedProduct+Methods.h"
#import "AMCStockedCategoryMaintenanceWindowController.h"
#import "AMCStockedBrandMaintenanceWindowController.h"
#import "AMCShoppingListPrintViewController.h"
#import "AMCBarcodeScanningViewController.h"
#import "AMCSalonDocument.h"

NSString * const kCategoryNameHairColourTube    = @"Hair Colour - Tube";
NSString * const kCategoryNameHairColourOxydent = @"Hair Colour - Oxydent/Developer/Peroxide";
NSString * const kCategoryNameHairColourBleach  = @"Hair Colour - Lightener/Bleaching powder";
NSString * const kCategoryNameHairTreatment     = @"Hair Treatment";
NSString * const kCategoryNameHairStylingMousse = @"Hair Styling Mousse";
NSString * const kCategoryNameHairSpray         = @"Hairspray";
NSString * const kCategoryNameMiscellaneous     = @"Miscellaneous";

@interface AMCStockControlViewController ()
{

}
@property (nonatomic, readonly) StockedProduct * selectedStockedProduct;
@end

@implementation AMCStockControlViewController
- (NSString*)entityName {
    return @"StockedProduct";
}
-(NSPredicate*)filtersPredicate {
    NSMutableArray * predicates = [NSMutableArray array];
    StockedCategory * category = self.stockedCategoryPopupButton.selectedItem.representedObject;
    if (category) {
        [predicates addObject:[NSPredicate predicateWithFormat:@"stockedCategory = %@",category]];
    }
    StockedBrand * brand = self.brandPopupButton.selectedItem.representedObject;
    if (brand) {
        [predicates addObject:[NSPredicate predicateWithFormat:@"stockedBrand = %@",brand]];
    }
    
    NSNumber * stockLevel = self.stockLevelPopupButton.selectedItem.representedObject;
    if (stockLevel) {
        NSPredicate * p = [NSPredicate predicateWithFormat:@"currentStockLevel == %@",stockLevel];
        [predicates addObject:p];
    }
    return [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
}
-(void)applySearchField {
    NSString * search = self.searchField.stringValue;
    if (!search || search.length == 0) {
        self.displayedObjects = [self.filteredObjects copy];
        return;
    }
    NSPredicate * searchPredicate = [NSPredicate predicateWithFormat:@"code contains[cd] %@ or name contains[cd] %@ or stockedBrand.shortBrandName contains[cd] %@ or barcode = %@",search, search,search,search];
    self.displayedObjects = [self.filteredObjects filteredArrayUsingPredicate:searchPredicate];
}
#pragma mark - NSViewController Overrides
-(NSString *)nibName {
    return @"AMCStockControlViewController";
}
- (void)viewDidLoad {
    [super viewDidLoad];
    [self createDefaultLists];
    [self populateStockCategories];
    [self populateBrands];
    [self populateStockLevelPopupButton];
    NSSortDescriptor* brandSort = [[NSSortDescriptor alloc] initWithKey: @"stockedBrand.shortBrandName" ascending:YES];
    NSSortDescriptor* productSort = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    NSSortDescriptor* codeSort = [[NSSortDescriptor alloc] initWithKey:@"code" ascending:YES];
    [self.dataTable setSortDescriptors:@[brandSort,productSort,codeSort]];
    [self reloadData];
}
#pragma mark - NSTextFieldDelegate
-(void)controlTextDidChange:(NSNotification *)obj {

}

#pragma mark - NSTableViewDelegate
-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    StockedProduct * product = self.displayedObjects[row];
    NSString * columnID = tableColumn.identifier;
    NSTableCellView * view = [tableView makeViewWithIdentifier:columnID owner:self];
    if ([columnID isEqualToString:@"barcode"]) {
        view.textField.stringValue = (product.barcode)?product.barcode:@"";
        return view;
    }
    if ([columnID isEqualToString:@"includeInShopping"]) {
        view.textField.stringValue = product.numberToBuy.stringValue;
        return view;
    }
    if ([columnID isEqualToString:@"brand"]) {
        view.textField.stringValue = product.stockedBrand.shortBrandName;
        return view;
    }
    if ([columnID isEqualToString:@"product"]) {
        view.textField.stringValue = product.name;
        return view;
    }
    if ([columnID isEqualToString:@"code"]) {
        view.textField.stringValue = product.code;
        return view;
    }
    if ([columnID isEqualToString:@"stockLevel"]) {
        view.textField.stringValue = product.currentStockLevel.stringValue;
        return view;
    }
    if ([columnID isEqualToString:@"lastUpdatedDate"]) {
        NSDate * lastUpdated = product.lastUpdatedDate;
        if (!product.lastUpdatedDate) {
            lastUpdated = product.createdDate;
        }
        view.textField.stringValue = [lastUpdated dateStringWithMediumDateFormatShortTimeFormat];
        return view;
    }
    return nil;
}
-(BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row {
    return YES;
}
-(void)tableViewSelectionIsChanging:(NSNotification *)notification {
}
-(void)tableViewSelectionDidChange:(NSNotification *)notification {
    self.selectedItemStockLevel = self.selectedStockedProduct.currentStockLevel.integerValue;
    self.selectedItemNumberToBuy = self.selectedStockedProduct.numberToBuy.integerValue;
}
#pragma mark - private implementation
-(NSInteger)selectedItemNumberToBuy {
    return self.selectedStockedProduct.numberToBuy.integerValue;
}
-(void)setSelectedItemNumberToBuy:(NSInteger)selectedItemNumberToBuy {
    StockedProduct * stockedProduct = self.selectedStockedProduct;
    if (stockedProduct.numberToBuy.integerValue != selectedItemNumberToBuy) {
        stockedProduct.numberToBuy = @(selectedItemNumberToBuy);
        NSInteger row = self.dataTable.selectedRow;
        if (row >= 0) {
            NSTableCellView * view = [self.dataTable viewAtColumn:5 row:row makeIfNecessary:NO];
            NSTextField * textField = view.textField;
            textField.stringValue = stockedProduct.numberToBuy.stringValue;
            [self updateLastUpdatedDate:stockedProduct row:row];
        }
    }
}
-(NSInteger)selectedItemStockLevel {
    return self.selectedStockedProduct.currentStockLevel.integerValue;
}
-(void)setSelectedItemStockLevel:(NSInteger)selectedItemStockLevel {
    StockedProduct * stockedProduct = self.selectedStockedProduct;
    if (stockedProduct.currentStockLevel.integerValue != selectedItemStockLevel) {
        stockedProduct.currentStockLevel = @(selectedItemStockLevel);
        NSInteger row = self.dataTable.selectedRow;
        if (row >= 0) {
            NSTableCellView * view = [self.dataTable viewAtColumn:4 row:row makeIfNecessary:NO];
            NSTextField * textField = view.textField;
            textField.stringValue = stockedProduct.currentStockLevel.stringValue;
            [self updateLastUpdatedDate:stockedProduct row:row];
        }
    }
}
-(void)updateLastUpdatedDate:(StockedProduct*)stockedProduct row:(NSInteger)row {
    stockedProduct.lastUpdatedDate = [NSDate date];
    NSInteger col = [self.dataTable columnWithIdentifier:@"lastUpdatedDate"];
    NSTableCellView * view = [self.dataTable viewAtColumn:col row:row makeIfNecessary:NO];
    view.textField.stringValue = [stockedProduct.lastUpdatedDate dateStringWithMediumDateFormatShortTimeFormat];
}
-(StockedProduct*)selectedStockedProduct {
    if (self.dataTable.selectedRow >=0) {
        return self.displayedObjects[self.dataTable.selectedRow];
    } else {
        return nil;
    }
}
-(void)populateStockCategories {
    NSMenu * menu = self.stockedCategoryPopupButton.menu;
    [menu removeAllItems];
    
    NSMenuItem * menuItem = [[NSMenuItem alloc] init];
    menuItem.representedObject = nil;
    menuItem.title = @"All categories";
    [menu addItem:menuItem];
    [self.stockedCategoryPopupButton selectItem:menuItem];
    menuItem = [NSMenuItem separatorItem];
    [menu addItem:menuItem];
    
    NSArray * categories = [StockedCategory allObjectsWithMoc:self.documentMoc];
    for (StockedCategory * category in categories) {
        menuItem = [[NSMenuItem alloc] init];
        menuItem.representedObject = category;
        menuItem.title = category.categoryName;
        [menu addItem:menuItem];
    }
}
-(void)populateBrands {
    NSMenu * menu = self.brandPopupButton.menu;
    [menu removeAllItems];
    
    NSMenuItem * menuItem = [[NSMenuItem alloc] init];
    menuItem.representedObject = nil;
    menuItem.title = @"All brands";
    [menu addItem:menuItem];
    [self.brandPopupButton selectItem:menuItem];
    menuItem = [NSMenuItem separatorItem];
    [menu addItem:menuItem];

    NSArray * brands = [StockedBrand allObjectsWithMoc:self.documentMoc];
    for (StockedBrand * brand in brands) {
        menuItem = [[NSMenuItem alloc] init];
        menuItem.representedObject = brand;
        menuItem.title = brand.brandName;
        [menu addItem:menuItem];
    }
}
-(void)populateStockLevelPopupButton {
    NSMenu * menu = self.stockLevelPopupButton.menu;
    [menu removeAllItems];
    
    NSMenuItem * menuItem;
    menuItem = [[NSMenuItem alloc] init];
    menuItem.title = @"Any stock level";
    [menu addItem:menuItem];
    [self.stockLevelPopupButton selectItem:menuItem];

    menuItem = [[NSMenuItem alloc] init];
    menuItem.title = @"0";
    menuItem.representedObject = @(0);
    [menu addItem:menuItem];

    menuItem = [[NSMenuItem alloc] init];
    menuItem.title = @"1";
    menuItem.representedObject = @(1);
    [menu addItem:menuItem];
    
    menuItem = [[NSMenuItem alloc] init];
    menuItem.title = @"2";
    menuItem.representedObject = @(2);
    [menu addItem:menuItem];
    
    menuItem = [[NSMenuItem alloc] init];
    menuItem.title = @"3";
    menuItem.representedObject = @(3);
    [menu addItem:menuItem];

    menuItem = [[NSMenuItem alloc] init];
    menuItem.title = @"4";
    menuItem.representedObject = @(4);
    [menu addItem:menuItem];

    menuItem = [[NSMenuItem alloc] init];
    menuItem.title = @"5";
    menuItem.representedObject = @(5);
    [menu addItem:menuItem];

}

-(void)createDefaultLists {
    NSArray * categories = [StockedCategory allObjectsWithMoc:self.documentMoc];
    if (categories.count > 0) return;
    [self createDefaultStockedCategories];
    [self createDefaultStockedBrands];
    [self createDefaultStockedProducts];
}
-(void)createDefaultStockedCategories {
    NSArray * categories = [StockedCategory allObjectsWithMoc:self.documentMoc];
    if (categories.count == 0) {
        StockedCategory * category;
        category = [StockedCategory newObjectWithMoc:self.documentMoc];
        category.categoryName = kCategoryNameHairColourTube;
        category = [StockedCategory newObjectWithMoc:self.documentMoc];
        category.categoryName = kCategoryNameHairColourOxydent;
        category = [StockedCategory newObjectWithMoc:self.documentMoc];
        category.categoryName = kCategoryNameHairColourBleach;
        category = [StockedCategory newObjectWithMoc:self.documentMoc];
        category.categoryName = kCategoryNameHairTreatment;

        category = [StockedCategory newObjectWithMoc:self.documentMoc];
        category.categoryName = kCategoryNameHairStylingMousse;

        category = [StockedCategory newObjectWithMoc:self.documentMoc];
        category.categoryName = kCategoryNameHairSpray;
        
        category = [StockedCategory newObjectWithMoc:self.documentMoc];
        category.categoryName = kCategoryNameMiscellaneous;
    }
}
-(void)createDefaultStockedBrands {
    NSArray * brands = [StockedBrand allObjectsWithMoc:self.documentMoc];
    if (brands.count > 0) return; // some brands already exist
    
    // create a basic set of default brands
    StockedBrand * brand;
    // NXT
    brand = [StockedBrand newObjectWithMoc:self.documentMoc];
    brand.brandName = @"Next Generation";
    brand.shortBrandName = @"NXT";
    // L'Oreal
    brand = [StockedBrand newObjectWithMoc:self.documentMoc];
    brand.brandName = @"L'Oreal Paris";
    brand.shortBrandName = @"L'Oreal";
    // OPI
    brand = [StockedBrand newObjectWithMoc:self.documentMoc];
    brand.brandName = @"OPI";
    brand.shortBrandName = @"OPI";
    // Wella
    brand = [StockedBrand newObjectWithMoc:self.documentMoc];
    brand.brandName = @"Wella";
    brand.shortBrandName = @"Wella";
    // Unique
    brand = [StockedBrand newObjectWithMoc:self.documentMoc];
    brand.brandName = @"Unique";
    brand.shortBrandName = @"Unique";
    // TrueZone
    brand = [StockedBrand newObjectWithMoc:self.documentMoc];
    brand.brandName = @"TrueZone";
    brand.shortBrandName = @"TrueZone";
}
-(void)createDefaultStockedProducts {

}

-(StockedProduct*)makeProductWithName:(NSString*)name
                             category:(StockedCategory*)category
                                brand:(StockedBrand*)brand
                                 code:(NSString*)code
                           consumable:(BOOL)consumable
                       reorderTrigger:(NSInteger)triggerlevel
                    currentStockLevel:(NSInteger)currentStock
{
    StockedProduct * product = [StockedProduct newObjectWithMoc:self.documentMoc];
    product.name = name;
    product.stockedBrand = brand;
    product.stockedCategory = category;
    product.code = code;
    product.isConsumable = @(consumable);
    product.minimumStockTrigger = @(triggerlevel);
    product.currentStockLevel = @(currentStock);
    product.createdDate = [NSDate date];
    return product;
}
#pragma mark - NSWindowDelegate

#pragma mark - Actions
- (IBAction)filtersChanged:(id)sender {
    [self reloadData];
}
- (IBAction)editBrandListClicked:(id)sender {
    self.stockedBrandMaintenanceWindowController.document = self.salonDocument;
    NSWindow * sheet = self.stockedBrandMaintenanceWindowController.window;
    sheet.delegate = self;
    self.stockedBrandMaintenanceWindowController.sourceWindow = self.view.window;
    [self.view.window beginSheet:sheet completionHandler:^(NSModalResponse returnCode) {
        [self populateBrands];
        [self reloadData];
    }];
}
-(void)brandListEditorDidEnd:(id)context {
    [self populateBrands];
    [self reloadData];
}
- (IBAction)editCategoryList:(id)sender {
    self.stockedCategoryMaintenanceWindowController.document = self.salonDocument;
    NSWindow * sheet = self.stockedCategoryMaintenanceWindowController.window;
    sheet.delegate = self;
    self.stockedCategoryMaintenanceWindowController.sourceWindow = self.view.window;
    [self.view.window beginSheet:sheet completionHandler:^(NSModalResponse returnCode) {
        [self populateStockCategories];
        [self reloadData];
    }];
}

-(IBAction)addNewProductClicked:(id)sender {
    self.objectSelectedBeforeEditorInvoked = self.selectedObject;
    StockedProduct * product = [StockedProduct newObjectWithMoc:self.documentMoc];
    [self editObject:product forSalon:self.salonDocument inMode:EditModeCreate withViewController:self.editObjectViewController];
}
- (IBAction)searchFieldChanged:(id)sender {
    [self reloadData];
}

- (IBAction)clearShoppingList:(id)sender {
    NSAlert * alert = [[NSAlert alloc] init];
    alert.messageText = @"Clear the shopping list?";
    alert.informativeText = @"This will reset the 'buy' number of every item to 0";
    [alert addButtonWithTitle:@"Clear list"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSAlertFirstButtonReturn) {
            [self clearShoppingList];
        }
    }];
}
-(void)clearShoppingList {
    NSArray * allItems = [StockedProduct allObjectsWithMoc:self.documentMoc];
    for (StockedProduct * product in allItems) {
        product.numberToBuy = @(0);
    }
    [self reloadData];
}

- (IBAction)printShoppingList:(id)sender {
    [self.shoppingListPrintViewController prepareForDisplayWithSalon:self.salonDocument];
    [self presentViewControllerAsSheet:self.shoppingListPrintViewController];
}
- (IBAction)makeQuickShoppingList:(id)sender {
    NSAlert * alert = [[NSAlert alloc] init];
    alert.messageText = @"Create shopping list?";
    alert.informativeText = @"This will set the 'buy' level of every item so that when the shopping is complete, the stock level of that item will be one more than the minimum allowed stock level for that item.";
    [alert addButtonWithTitle:@"Make list"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSAlertFirstButtonReturn) {
            [self makeQuickShoppingList];
        }
    }];
}

- (IBAction)completeShoppingList:(id)sender {
    NSAlert * alert = [[NSAlert alloc] init];
    alert.messageText = @"Complete the shopping";
    alert.informativeText = @"This will update the stock level of every item with the number bought. Furthermore, a payment will be created. You will need to visit the payment's tab to update the amount.";
    [alert addButtonWithTitle:@"Complete shopping"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSAlertFirstButtonReturn) {
            [self completeShopping];
        }
    }];
}
-(void)completeShopping {
    NSArray * allItems = [StockedProduct allObjectsWithMoc:self.documentMoc];
    for (StockedProduct * product in allItems) {
        NSInteger bought = product.numberToBuy.integerValue;
        NSInteger updatedStock = product.currentStockLevel.integerValue + bought;
        product.currentStockLevel = @(updatedStock);
        product.numberToBuy = @(0);
    }
    [self reloadData];
}
-(void)makeQuickShoppingList {
    NSArray * allItems = [StockedProduct allObjectsWithMoc:self.documentMoc];
    for (StockedProduct * product in allItems) {
        NSInteger stock = product.currentStockLevel.integerValue;
        NSInteger trigger = product.minimumStockTrigger.integerValue;
        NSInteger updatedBuy = trigger - stock + 1;
        if (updatedBuy < 0) updatedBuy = 0;
        product.numberToBuy = @(updatedBuy);
    }
    [self reloadData];
}
- (IBAction)enterBarcodeScanningMode:(id)sender {
    [self.barcodeScanningViewController prepareForDisplayWithSalon:self.salonDocument];
    [self.barcodeScanningViewController prepareForScan];
    [self presentViewControllerAsSheet:self.barcodeScanningViewController];
}
-(void)dismissViewController:(NSViewController *)viewController {
    if (viewController == self.barcodeScanningViewController) {
        [self.enterBarcodeModeButton setState:NSOffState];
    }
    [super dismissViewController:viewController];
    [self reloadData];
}
@end
