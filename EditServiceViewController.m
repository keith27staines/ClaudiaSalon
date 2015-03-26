//
//  EditServiceViewController.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 22/07/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "EditServiceViewController.h"
#import "AMCConstants.h"
#import "Service+Methods.h"
#import "Product+Methods.h"
#import "ObjectSelectorViewController.h"
#import "ServiceCategory+Methods.h"
#import "AMCSalonDocument.h"

@interface EditServiceViewController ()
{
    NSMutableArray * _products;
    NSMutableArray * _categories;
}
@property NSMutableArray * products;
@property (readonly) Service * service;
@property NSMutableArray * categories;
@end

@implementation EditServiceViewController

-(NSString *)nibName
{
    return @"EditServiceViewController";
}
-(NSString *)objectName
{
    return @"Service";
}
-(void)viewDidLoad
{
    [self loadHairLengthPopup];
    [self loadCategoryPopup];
}
-(Service*)service
{
    return (Service*)self.objectToEdit;
}
-(void)clear
{
    [self setObjectToEdit:self.objectToEdit];
}
-(void)setObjectToEdit:(id)objectToEdit
{
    [super setObjectToEdit:objectToEdit];
    Service * service = objectToEdit;
    self.products = [[service.product allObjects] mutableCopy];
    [self.productsTable reloadData];
    [self deluxeChanged:self.deluxeCheckbox];
    [self.view.window makeFirstResponder:nil];
}
-(void)prepareForDisplayWithSalon:(AMCSalonDocument *)salonDocument
{
    [super prepareForDisplayWithSalon:salonDocument];
    [self loadProductTable];
    Service * service = self.service;
    self.nameField.stringValue = (service.name)?service.name : @"";
    self.timeRequired.stringValue = (service.expectedTimeRequired.stringValue)?service.expectedTimeRequired.stringValue:@"";
    self.nominalPrice.stringValue = (service.nominalCharge.stringValue)?service.nominalCharge.stringValue:@"";
    [self.hairLengthPopup selectItemAtIndex:service.hairLength.integerValue];
    [self.categoryPopup selectItemWithTitle:service.serviceCategory.name];
    [self.deluxeCheckbox setState:((service.deluxe.boolValue)?NSOnState:NSOffState)];
    switch (self.editMode) {
        case EditModeView:
        {
            [self.hairLengthPopup setEnabled:NO];
            [self.categoryPopup setEnabled:NO];
            [self.deluxeCheckbox setEnabled:NO];
            [self.priceSlider setEnabled:NO];
            break;
        }
        case EditModeCreate:
        {
            [self.hairLengthPopup selectItemAtIndex:0];
            [self.categoryPopup selectItemAtIndex:0];
            [self.deluxeCheckbox setEnabled:YES];
            [self.priceSlider setEnabled:YES];
            [self.hairLengthPopup setEnabled:YES];
            [self.categoryPopup setEnabled:YES];
            break;
        }
        case EditModeEdit:
        {
            [self.deluxeCheckbox setEnabled:YES];
            [self.priceSlider setEnabled:YES];
            [self.hairLengthPopup setEnabled:YES];
            [self.categoryPopup setEnabled:YES];
            break;
        }
    }
    [self setPriceControls];
    [self enableProductTableButtons];
    [self deluxeChanged:self];
}
-(void)setPriceControls
{
    Service * service = self.service;
    self.minimumPrice.stringValue = [NSString stringWithFormat:@"£%@",service.minimumCharge];
    self.nominalPrice.stringValue = [NSString stringWithFormat:@"£%@",service.nominalCharge];
    self.maximumPrice.stringValue = [NSString stringWithFormat:@"£%@",service.maximumCharge];
    self.priceSlider.doubleValue = service.nominalCharge.doubleValue;
    self.priceSlider.minValue = service.minimumCharge.doubleValue;
    self.priceSlider.maxValue = service.maximumCharge.doubleValue;
    self.minimumPrice.stringValue = [NSString stringWithFormat:@"£%@",service.minimumCharge];
    self.maximumPrice.stringValue = [NSString stringWithFormat:@"£%@",service.maximumCharge];
    self.nominalPrice.stringValue = [NSString stringWithFormat:@"£%@",service.nominalCharge];
}
-(void)enableProductTableButtons
{
    if (self.editMode == EditModeView) {
        [self.addProduct setEnabled:NO];
        [self.removeProduct setEnabled:NO];
        return;
    }
    [self.addProduct setEnabled:YES];
    if (self.productsTable.selectedRow >=0 ) {
        [self.removeProduct setEnabled:YES];
    } else {
        [self.removeProduct setEnabled:NO];
    }
}
-(NSArray *)editableControls
{
    return  @[self.nameField,
              self.hairLengthPopup,
              self.timeRequired,
              self.minimumPrice,
              self.nominalPrice,
              self.maximumPrice];
}

#pragma mark - NSControlTextEditingDelegate
-(void)controlTextDidBeginEditing:(NSNotification *)obj
{
    [self.doneButton setEnabled:NO];
}
-(BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
    BOOL controlIsValid = NO;
    [self.doneButton setEnabled:NO];
    
    if (control == self.nameField) {
        controlIsValid = [self validateName:fieldEditor.string];
    }
    if (control == self.timeRequired) {
        controlIsValid = YES;
    }
    if (control == self.nominalPrice || control == self.minimumPrice || control == self.maximumPrice) {
        controlIsValid = YES;
    }
    [self.doneButton setEnabled:[self isValid]];
    return controlIsValid;
}
-(void)controlTextDidEndEditing:(NSNotification *)obj
{
    [self.doneButton setEnabled:[self isValid]];
}
-(BOOL)isValid
{
    if (![self validateName:self.nameField.stringValue]) return NO;
    double nominal = self.nominalPrice.doubleValue;
    double minimum = self.minimumPrice.doubleValue;
    double maximum = self.maximumPrice.doubleValue;
    BOOL named = self.nameField.stringValue.length;
    if (named && nominal > 0.01 & nominal >= minimum && nominal <= maximum) {
        return YES;
    }
    return NO;
}
-(void)updateObject
{
    Service * service = self.objectToEdit;
    service.name = self.nameField.stringValue;
    service.hairLength = @([self.hairLengthPopup indexOfSelectedItem]);
    service.nominalCharge = @(self.nominalPrice.integerValue);
    service.expectedTimeRequired = @(self.timeRequired.integerValue);
    service.product = [NSSet setWithArray:self.products];
    NSInteger i = self.categoryPopup.indexOfSelectedItem;
    if (i==0) {
        service.serviceCategory = nil;
    } else {
        service.serviceCategory = self.categories[i-1];
    }
    [self.salonDocument commitAndSave:nil];
}

- (IBAction)addProduct:(id)sender {
    ObjectSelectorViewController * vc = [ObjectSelectorViewController new];
    [self presentViewController:vc asPopoverRelativeToRect:self.addProduct.bounds ofView:self.addProduct preferredEdge:NSMaxXEdge behavior:NSPopoverBehaviorTransient];
}

- (IBAction)removeProduct:(id)sender {
    [self.products removeObjectAtIndex:self.productsTable.selectedRow];
    [self.productsTable reloadData];
}

-(void)loadHairLengthPopup
{
    [self.hairLengthPopup removeAllItems];
    [self.hairLengthPopup insertItemWithTitle:@"Not applicable" atIndex:0];
    [self.hairLengthPopup insertItemWithTitle:@"Short" atIndex:1];
    [self.hairLengthPopup insertItemWithTitle:@"Medium" atIndex:2];
    [self.hairLengthPopup insertItemWithTitle:@"Long" atIndex:3];
    [self.hairLengthPopup selectItemAtIndex:0];
}
-(void)loadCategoryPopup
{
    NSManagedObjectContext * moc = self.documentMoc ;
    NSEntityDescription * entityDescription = [NSEntityDescription entityForName:@"ServiceCategory" inManagedObjectContext:moc];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    
    // Set predicate and sort orderings...
    NSSortDescriptor * sort = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"selectable == %@",@(YES)];
    [request setPredicate:predicate];
    [request setSortDescriptors:@[sort]];
    NSError *error = nil;
    self.categories = [[moc executeFetchRequest:request error:&error] mutableCopy];
    
    if (!self.categories) {
        self.categories = [@[] mutableCopy];
    }
    [self.categoryPopup removeAllItems];
    [self.categoryPopup insertItemWithTitle:@"All Categories" atIndex:0];
    NSUInteger i = 1;
    for (ServiceCategory * category in self.categories) {
        NSString * title = category.name;
        [self.categoryPopup insertItemWithTitle:title atIndex:i];
        i++;
    }
    [self categoryChanged:self.categoryPopup];
}
-(void)loadProductTable
{
    [self.productsTable reloadData];
    if (self.editMode == EditModeView) {
        [self.removeProduct setEnabled:NO];
        [self.addProduct setEnabled:NO];
        return;
    }
    [self.productsTable deselectAll:nil];
    [self.removeProduct setEnabled:NO];
    [self.addProduct setEnabled:YES];
}

#pragma mark - NSTableViewDelegate/Datasource
-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    if (tableView == self.productsTable) {
        return self.products.count;
    }
    return 0;
}
-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if (tableView == self.productsTable) {
        Product * product = self.products[row];
        if ([tableColumn.identifier isEqualToString:@"brandName"]) {
            return product.brandName;
        } else {
            return product.productType;
        }
    }
    return nil;
}
-(void)tableViewSelectionDidChange:(NSNotification *)notification
{
    [self enableProductTableButtons];
}

#pragma mark - NSPopoverDelegate
-(void)popoverDidClose:(NSNotification *)notification
{
//    if (notification.object == self.productSelectorPopover) {
//        ObjectSelectorViewController * vc = (ObjectSelectorViewController*)self.productSelectorPopover.contentViewController;
//        if (!vc.isCancelled) {
//            Product * selectedProduct = vc.selectedObject;
//            [self.products addObject:selectedProduct];
//            [self.productsTable reloadData];
//        }
//    }
}
- (IBAction)minimumPriceChanged:(id)sender {
    double minPrice = self.minimumPrice.doubleValue;
    double maxPrice = self.maximumPrice.doubleValue;
    double nominalPrice = self.nominalPrice.doubleValue;
    minPrice = floor(minPrice);
    if (minPrice < 0) {
        minPrice = 0;
    }
    if (minPrice > maxPrice) {
        maxPrice = minPrice;
    }
    if (minPrice > nominalPrice) {
        nominalPrice = minPrice;
    }

    self.service.minimumCharge = @(minPrice);
    self.service.maximumCharge = @(maxPrice);
    self.service.nominalCharge = @(nominalPrice);
    [self setPriceControls];
    [self.doneButton setEnabled:[self isValid]];
}

- (IBAction)maximumPriceChanged:(id)sender {
    double minPrice = self.minimumPrice.doubleValue;
    double maxPrice = self.maximumPrice.doubleValue;
    double nominalPrice = self.nominalPrice.doubleValue;
    maxPrice = ceil(maxPrice);
    if (maxPrice < 0) {
        maxPrice = 0;
    }
    if (maxPrice < minPrice) {
        minPrice = maxPrice;
    }
    if (maxPrice < nominalPrice) {
        nominalPrice = maxPrice;
    }

    self.service.minimumCharge = @(minPrice);
    self.service.maximumCharge = @(maxPrice);
    self.service.nominalCharge = @(nominalPrice);
    [self setPriceControls];
}

- (IBAction)nominalPriceChanged:(id)sender {
    double minPrice = self.minimumPrice.doubleValue;
    double maxPrice = self.maximumPrice.doubleValue;
    double nominalPrice = ((NSControl*)(sender)).doubleValue;
    nominalPrice = round(nominalPrice);
    if (nominalPrice < minPrice) {
        nominalPrice = minPrice;
    }
    if (nominalPrice > maxPrice) {
        nominalPrice = maxPrice;
    }
    self.service.minimumCharge = @(minPrice);
    self.service.maximumCharge = @(maxPrice);
    self.service.nominalCharge = @(nominalPrice);
    [self setPriceControls];
}

- (IBAction)deluxeChanged:(id)sender {
    if (self.deluxeCheckbox.state == NSOnState) {
        [self.deluxeBadge setHidden:NO];
    } else {
        [self.deluxeBadge setHidden:YES];
    }
}
- (IBAction)categoryChanged:(id)sender {
}
@end
