//
//  EditStockProductViewController.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 31/12/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "EditStockProductViewController.h"
#import "StockedProduct+Methods.h"
#import "StockedBrand+Methods.h"
#import "StockedCategory+Methods.h"
#import "AMCSalonDocument.h"

@interface EditStockProductViewController ()

@end

@implementation EditStockProductViewController

-(NSString *)nibName
{
    return @"EditStockProductViewController";
}
-(NSString *)objectTypeAndName {
    return @"Stocked Product";
}
-(void)viewDidAppear {
    [self.view.window makeFirstResponder:self.view.window];
}
-(void)prepareForDisplayWithSalon:(AMCSalonDocument *)salonDocument
{
    [super prepareForDisplayWithSalon:salonDocument];
    self.informUserLabel.stringValue = @"";
    [self populateCategoryPopup];
    [self populateBrandPopup];
    StockedProduct * product = (StockedProduct*)self.objectToEdit;
    NSMenu * menu;
    NSMenuItem * menuItem;
    if (product.stockedCategory) {
        menu = self.categoryPopupButton.menu;
        menuItem = [menu itemWithTitle:product.stockedCategory.categoryName];
        [self.categoryPopupButton selectItem:menuItem];
    } else {
        [self.categoryPopupButton selectItemAtIndex:0];
    }
    if (product.stockedBrand) {
        menu = self.brandPopupButton.menu;
        menuItem = [menu itemWithTitle:product.stockedBrand.shortBrandName];
        [self.brandPopupButton selectItem:menuItem];
    } else {
        [self.brandPopupButton selectItemAtIndex:0];
    }

    switch (self.editMode) {
        case EditModeView:
        {
            self.productTextField.stringValue = product.name;
            self.codeTextField.stringValue = (product.code)?product.code:@"";
            self.stockLevelTextField.stringValue = product.currentStockLevel.stringValue;
            self.lowStockWarningLevel.stringValue = product.minimumStockTrigger.stringValue;
            self.barcode.stringValue = (product.barcode)?product.barcode:@"";
            break;
        }
        case EditModeCreate:
        {
            self.productTextField.stringValue = @"";
            self.codeTextField.stringValue = @"";
            self.stockLevelTextField.stringValue = @"0";
            self.lowStockWarningLevel.stringValue = product.minimumStockTrigger.stringValue;
            self.barcode.stringValue = (product.barcode)?product.barcode:@"";
            break;
        }
        case EditModeEdit:
        {
            self.productTextField.stringValue = product.name;
            self.codeTextField.stringValue = (product.code)?product.code:@"";
            self.stockLevelTextField.stringValue = product.currentStockLevel.stringValue;
            self.lowStockWarningLevel.stringValue = product.minimumStockTrigger.stringValue;
            self.barcode.stringValue = (product.barcode)?product.barcode:@"";
            break;
        }
    }
    [self populateProductNamePopup];
}

-(NSArray *)editableControls
{
    return  @[self.codeTextField,
              self.productNamePopup,
              self.stockLevelTextField,
              self.lowStockWarningLevel,
              self.brandPopupButton,
              self.categoryPopupButton,
              self.barcode,
              self.add1ToStockButton,
              self.remove1FromStockButton];
}

#pragma mark - NSControlTextEditingDelegate

-(BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
    BOOL controlIsValid = NO;
    [self.doneButton setEnabled:NO];
    
    if (control == self.productTextField) {
        controlIsValid = self.productTextField.stringValue.length > 0;
    } else {
        controlIsValid = YES;
    }
    return controlIsValid;
}
-(void)controlTextDidEndEditing:(NSNotification *)obj
{
    [self.doneButton setEnabled:[self isValid]];
}
-(void)controlTextDidChange:(NSNotification *)obj {
    [self enableDoneButton];
}
-(BOOL)isValid
{
    self.informUserLabel.stringValue = @"";
    if (self.editMode == EditModeCreate) {
        BOOL isValid = self.categoryPopupButton.selectedItem.representedObject && self.brandPopupButton.selectedItem.representedObject;
        if (!isValid) {
            self.informUserLabel.stringValue = @"You must select a category and a brand";
            return NO;
        }
    }
    if (self.productTextField.stringValue.length == 0) {
        self.informUserLabel.stringValue = @"You must give the product a name";
        return NO;
    }
    if (![self isBarcodeUniqueOrEmpty]) {
        self.informUserLabel.stringValue = @"The barcode is already represents another product";
        return NO;
    }
    if (![self isProductUnique]) {
        self.informUserLabel.stringValue = @"This product already exists. Have you entered the right code?";
        return NO;
    }
    return YES;
}
-(BOOL)isBarcodeUniqueOrEmpty {
    if (!self.barcode.stringValue || self.barcode.stringValue.length == 0) {
        return YES;
    }
    StockedProduct * product = [StockedProduct fetchProductWithBarcode:self.barcode.stringValue withMoc:self.documentMoc];
    if (!product || product == self.objectToEdit) {
        return YES;
    }
    return NO;
}
-(BOOL)isProductUnique {
    NSManagedObjectContext * moc = self.documentMoc;
    StockedProduct * product = self.objectToEdit;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"StockedProduct" inManagedObjectContext:moc];
    [fetchRequest setEntity:entity];
    NSMutableArray * predicates = [NSMutableArray array];
    [predicates addObject:[NSPredicate predicateWithFormat:@"stockedCategory == %@",self.categoryPopupButton.selectedItem.representedObject]];
    [predicates addObject:[NSPredicate predicateWithFormat:@"stockedBrand == %@",self.brandPopupButton.selectedItem.representedObject]];
    [predicates addObject:[NSPredicate predicateWithFormat:@"name like[cd] %@",self.productTextField.stringValue]];
    if (self.codeTextField.stringValue && self.codeTextField.stringValue.length >0) {
        [predicates addObject:[NSPredicate predicateWithFormat:@"code like[cd] %@",self.codeTextField.stringValue]];
    } else {
        [predicates addObject:[NSPredicate predicateWithFormat:@"code == %@",nil]];
    }
    NSCompoundPredicate * compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
    [fetchRequest setPredicate:compoundPredicate];
    NSError *error = nil;
    NSArray *fetchedObjects = [moc executeFetchRequest:fetchRequest error:&error];
    if (fetchedObjects == nil) {
        NSLog(@"Unexpected error: %@",error);
    }
    NSAssert(fetchedObjects.count < 2, @"0 or 1 items expected");
    if (fetchedObjects.count == 0 || fetchedObjects[0]==product) {
        return YES;
    }
    return NO;
}
-(void)updateObject
{
    StockedProduct * product = self.objectToEdit;
    product.stockedCategory = self.categoryPopupButton.selectedItem.representedObject;
    product.stockedBrand = self.brandPopupButton.selectedItem.representedObject;
    product.code = self.codeTextField.stringValue;
    product.name = self.productTextField.stringValue;
    product.currentStockLevel = @(self.stockLevelTextField.stringValue.integerValue);
    product.minimumStockTrigger = @(self.lowStockWarningLevel.stringValue.integerValue);
    product.barcode = self.barcode.stringValue;
}
-(void)populateCategoryPopup {
    [self.categoryPopupButton removeAllItems];
    if (self.editMode == EditModeCreate) {
        [self.categoryPopupButton addItemWithTitle:@"Select category"];
        [self.categoryPopupButton selectItemAtIndex:0];
    }
    NSArray * categories = [StockedCategory allObjectsWithMoc:self.documentMoc];
    NSMenuItem * menuItem;
    for (StockedCategory * category in categories) {
        menuItem = [[NSMenuItem alloc] init];
        menuItem.representedObject = category;
        menuItem.title = category.categoryName;
        [self.categoryPopupButton.menu addItem:menuItem];
    }
}
-(void)populateBrandPopup {
    [self.brandPopupButton removeAllItems];
    if (self.editMode == EditModeCreate) {
        [self.brandPopupButton addItemWithTitle:@"Select brand"];
        [self.brandPopupButton selectItemAtIndex:0];
    }
    NSArray * brands = [StockedBrand allObjectsWithMoc:self.documentMoc];
    for (StockedBrand * brand in brands) {
        NSMenuItem * menuItem = [[NSMenuItem alloc] init];
        menuItem.representedObject = brand;
        menuItem.title = brand.shortBrandName;
        [self.brandPopupButton.menu addItem:menuItem];
    }
}
- (IBAction)stateAffectingValidityChanged:(id)sender {
    [self.doneButton setEnabled:[self isValid]];
}

- (IBAction)incrementStock:(id)sender {
    NSInteger stock = self.stockLevelTextField.stringValue.integerValue;
    stock++;
    self.stockLevelTextField.stringValue = @(stock).stringValue;
}

- (IBAction)decrementStock:(id)sender {
    NSInteger stock = self.stockLevelTextField.stringValue.integerValue;
    stock--;
    if (stock >= 0) {
        self.stockLevelTextField.stringValue = @(stock).stringValue;
    }
}
-(void)populateProductNamePopup {
    [self.productNamePopup removeAllItems];
    [self.productNamePopup addItemWithTitle:@"Add a new product name"];
    NSMenuItem * menuItem = [NSMenuItem separatorItem];
    [self.productNamePopup.menu addItem:menuItem];
    if (self.categoryPopupButton.selectedItem.representedObject && self.brandPopupButton.selectedItem.representedObject) {
        NSArray * products = [StockedProduct allProductsForCategory:self.categoryPopupButton.selectedItem.representedObject brand:self.brandPopupButton.selectedItem.representedObject withMoc:self.documentMoc];
        NSMutableSet * set = [[NSMutableSet alloc] init];
        for (StockedProduct * product in products) {
            [set addObject:product.name];
        }
        NSArray * names = [set allObjects];
        names = [names sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"" ascending:YES]]];
        for (NSString * name in names) {
            menuItem = [[NSMenuItem alloc] initWithTitle:name action:nil keyEquivalent:@""];
            menuItem.representedObject = name;
            [self.productNamePopup.menu addItem:menuItem];
            if ([name isEqualToString:self.productTextField.stringValue]) {
                [self.productNamePopup selectItem:menuItem];
            }
        }
    }
    [self enableProductNameAddControls];
}
-(void)enableProductNameAddControls {
    NSString * selectedProductName = self.productNamePopup.selectedItem.representedObject;
    if (selectedProductName) {
        [self.productTextField setHidden:YES];
        self.productTextField.stringValue = selectedProductName;
    } else {
        [self.productTextField setHidden:NO];
        self.productTextField.stringValue = @"";
    }
}
- (IBAction)categoryChanged:(id)sender {
    [self populateProductNamePopup];
    [self.doneButton setEnabled:[self isValid]];
}

- (IBAction)brandChanged:(id)sender {
    [self populateProductNamePopup];
    [self.doneButton setEnabled:[self isValid]];
}

- (IBAction)productNamePopupChanged:(id)sender {
    [self enableProductNameAddControls];
    if (![self.productTextField isHidden]) {
        [self.productTextField.window makeFirstResponder:self.productTextField];
    }
    [self.doneButton setEnabled:[self isValid]];
}

@end
