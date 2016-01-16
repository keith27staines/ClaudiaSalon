//
//  SelectItemsStepViewController.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 27/07/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "SelectItemsStepViewController.h"
#import "ServiceCategory+Methods.h"
#import "Service+Methods.h"
#import "Sale+Methods.h"
#import "SaleItem+Methods.h"
#import "Employee+Methods.h"
#import "AMCConstants.h"
#import "AMCDiscountCalculator.h"
#import "AMCRefundViewController.h"
#import "AMCEmployeeForServiceSelector.h"
#import "AMCJobsColumnViewController.h"
#import "AMCJobsColumnView.h"
#import "AMCQuickQuoteViewController.h"

@interface SelectItemsStepViewController() <AMCJobsColumnViewDelegate>
{
    NSMutableArray * _services;
    NSMutableArray * _categories;
    NSMutableArray * _saleItemsArray;
    AMCEmployeeForServiceSelector * _employeeForServiceViewController;
}
@property NSMutableArray * categories;
@property NSMutableArray * services;
@property (weak,readonly) Sale * sale;
@property (readonly) NSMutableArray * saleItemsArray;
@property (readonly) BOOL enabled;
@property (readonly) AMCEmployeeForServiceSelector * employeeForServiceViewController;
@end

@implementation SelectItemsStepViewController

-(NSString *)nibName
{
    return @"SelectItemsStepViewController";
}
#pragma mark popup loaders
-(void)loadPopups
{
    [self loadCategoryPopup];
    [self loadDiscountPopup];
}
-(void)applyEditMode:(EditMode)editMode
{
    [super applyEditMode:editMode];
    [self clear];
    [self.saleItemsTable reloadData];
    switch (editMode) {
        case EditModeCreate:
        {
            [self.selectServiceBox setHidden:NO];
            [self.selectedSaleItemBox setHidden:YES];
            [self.refundButton setHidden:YES];
            break;
        }
        case EditModeView:
        {
            [self.selectServiceBox setHidden:NO];
            [self.selectedSaleItemBox setHidden:NO];
            [self.refundButton setHidden:YES];
            [self.delegate wizardStep:self isValid:self.isValid];
            [self.saleItemsTable selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
            [self.refundButton setHidden:self.sale.isQuote.boolValue];
            [self saleItemWasSelected];
            break;
        }
        case EditModeEdit:
        {
            [self.selectServiceBox setHidden:NO];
            [self.selectedSaleItemBox setHidden:NO];
            [self.delegate wizardStep:self isValid:self.isValid];
            [self.saleItemsTable selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
            [self.refundButton setHidden:self.sale.isQuote.boolValue];
            [self saleItemWasSelected];
            break;
        }
    }
}
-(AMCEmployeeForServiceSelector *)employeeForServiceViewController {
    if (!_employeeForServiceViewController) {
        _employeeForServiceViewController = [AMCEmployeeForServiceSelector new];
    }
    return _employeeForServiceViewController;
}
-(BOOL)enabled
{
    return (self.editMode == EditModeCreate || self.editMode == EditModeEdit);
}
-(void)loadCategoryPopup
{
    NSManagedObjectContext * moc = self.documentMoc;
    NSEntityDescription * entityDescription = [NSEntityDescription entityForName:@"ServiceCategory" inManagedObjectContext:moc];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    
    // Set predicate and sort orderings...
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"selectable == %@",@(YES)];
    NSSortDescriptor * sort = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
    [request setSortDescriptors:@[sort]];
    [request setPredicate:predicate];
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
-(void)loadDiscountPopup
{
    [self.discountPopup removeAllItems];
    for (int i = AMCDiscountMinimum; i<=AMCDiscountMaximum; i++) {
        NSString * discountDescription = [AMCDiscountCalculator discountDescriptionforDiscount:i];
        [self.discountPopup insertItemWithTitle:discountDescription atIndex:i];
    }
}

#pragma mark - NSTableViewDataSource
-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    if (tableView == self.servicesListTable) {
        return self.services.count;
    } else {
        return self.saleItemsArray.count;
    }
}
-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (tableView == self.saleItemsTable) {
        if ([tableColumn.identifier isEqualToString:@"serviceName"]) {
            SaleItem * saleItem = self.saleItemsArray[row];
            AMCJobsColumnViewController * vc = [[AMCJobsColumnViewController alloc] init];
            AMCJobsColumnView * view = (AMCJobsColumnView*)vc.view;
            view.delegate = self;
            view.representedObject = saleItem;
            view.textField.stringValue = saleItem.service.displayText;
            [self loadEmployeePopup:view.stylistPopup forSaleItem:saleItem];
            return view;
        }
    }
    if (tableView == self.servicesListTable) {
        if ([tableColumn.identifier isEqualToString:@"serviceName"]) {
            Service * service = self.services[row];
            NSTableCellView * view = [tableView makeViewWithIdentifier:@"serviceView" owner:self];
            view.textField.stringValue = service.displayText;
            return view;
        }
    }
    return nil;
}
-(void)jobsColumnView:(AMCJobsColumnView *)view selectedStylist:(id)stylist {
    SaleItem * saleItem = view.representedObject;
    saleItem.performedBy = stylist;
}
-(void)loadEmployeePopup:(NSPopUpButton*)popup forSaleItem:(SaleItem*)saleItem {
    [popup removeAllItems];
    Service * service = saleItem.service;
    for (Employee * employee in service.canBeDoneBy) {
        if (employee.isActive.boolValue) {
            NSMenuItem * menuItem = [[NSMenuItem alloc] init];
            menuItem.representedObject = employee;
            menuItem.title = employee.fullName;
            [popup.menu addItem:menuItem];
            if (saleItem.performedBy == employee) {
                [popup selectItem:menuItem];
                [popup setNeedsDisplay:YES];
            }
        }
    }
}
#pragma mark - NSTableViewDelegate
-(void)tableView:(NSTableView *)tableView sortDescriptorsDidChange:(NSArray *)oldDescriptors
{
    NSArray * newDescriptors = [tableView sortDescriptors];
    if (tableView == self.servicesListTable) {
        [self.services sortUsingDescriptors:newDescriptors];
        [self.servicesListTable reloadData];
    } else {
        [self.saleItemsArray sortUsingDescriptors:newDescriptors];
        [self.saleItemsTable reloadData];
    }
}
#pragma mark - NSTableViewDelegate
-(void)tableViewSelectionDidChange:(NSNotification *)notification
{
    if (notification.object == self.servicesListTable) {
        [self serviceListItemWasSelected];
    } else {
        [self saleItemWasSelected];
    }
    [self.addSelectedServiceButton setEnabled:(self.servicesListTable.selectedRow >=0) && self.enabled];
    [self.removeSaleItemButton setEnabled:(self.saleItemsTable.selectedRow >=0) && self.enabled];
}
-(BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    return NO;
}
#pragma mark - NSViewController
-(NSView *)view
{
    NSView * view = [super view];
    static BOOL isLoaded = NO;
    if (!isLoaded) {
        isLoaded = YES;
        [self clear];
        [self.saleItemsTable reloadData];
        [self updateTotal];
    }
    return view;
}
-(void)controlTextDidChange:(NSNotification *)obj
{
    if (obj.object == self.chargePriceBeforeDiscount) {
        [self.delegate wizardStep:self isValid:self.isValid];
    }
}
#pragma mark - WizardStepViewController
-(void)clear {
    if (!self.documentMoc) {
        return;
    }
    [self loadPopups];
    [self.servicesListTable deselectAll:self];
    [self.saleItemsTable deselectAll:self];
    _saleItemsArray = nil;
    [self.saleItemsTable reloadData];
    [self.categoryPopup selectItemAtIndex:0];
    [self categoryChanged:self];
    [self.addSelectedServiceButton setEnabled:NO];
    [self.removeSaleItemButton setEnabled:NO];
    [self.discountPopup setEnabled:NO];
    [self.nameOfService setEditable:NO];
    [self.priceSlider setEnabled:NO];
    [self.chargePriceBeforeDiscount setEnabled:NO];
    [self.hairLength setEditable:NO];
    [self.maximumPrice setEditable:NO];
    [self.nominalPriceOrPriceRange setEditable:NO];
    [self.chargePriceAfterDiscount setEditable:NO];
    [self clearPriceAndDiscount];
    [self.selectedSaleItemBox setHidden:YES];
    if (!self.enabled) {
        [self.delegate wizardStep:self isValid:self.isValid];
    }
    [self updateTotal];
}
-(id)objectForWizardStep
{
    return [NSSet setWithArray:self.saleItemsArray];
}
#pragma mark - WizardStepViewDelegate
-(void)viewRevisited:(NSView *)view
{
    NSInteger row = self.servicesListTable.selectedRow;
    if (row < 0) {
        [self.deluxeImage setHidden:YES];
    } else {
        Service * service = self.services[row];
        [self.deluxeImage setHidden:!service.deluxe.boolValue];
    }
    [self.delegate wizardStep:self isValid:self.isValid];
    [self updateTotal];
}
#pragma mark - Actions
- (IBAction)categoryChanged:(id)sender {
    NSManagedObjectContext * moc = self.documentMoc;
    NSEntityDescription * entityDescription = [NSEntityDescription entityForName:@"Service" inManagedObjectContext:moc];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSPredicate *predicate;
    if (self.categoryPopup.indexOfSelectedItem == 0) {
        predicate = nil;
    } else {
        ServiceCategory * category = self.categories[self.categoryPopup.indexOfSelectedItem-1];
        predicate = [NSPredicate predicateWithFormat:@"serviceCategory = %@",category];
    }
    NSSortDescriptor * sort = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    [request setEntity:entityDescription];
    [request setPredicate:predicate];
    [request setSortDescriptors:@[sort]];
    NSError *error = nil;
    self.services = [[moc executeFetchRequest:request error:&error] mutableCopy];
    
    if (!self.services) {
        self.services = [@[] mutableCopy];
    }
    [self.servicesListTable reloadData];
    [self.servicesListTable deselectAll:self];
    [self.servicesBox setHidden:YES];
}
- (IBAction)chargedPriceChanged:(id)sender {
    SaleItem * saleItem = [self selectedSaleItem];
    saleItem.nominalCharge = @(self.chargePriceBeforeDiscount.doubleValue);
    [self setPriceBeforeDiscountFromSaleItem:saleItem];
    [self applyDiscount];
    [self.delegate wizardStep:self isValid:self.isValid];
    [self updateTotal];
}
- (IBAction)priceSliderChanged:(id)sender {
    SaleItem * saleItem = [self selectedSaleItem];
    saleItem.nominalCharge = @(self.priceSlider.doubleValue);
    [self setPriceBeforeDiscountFromSaleItem:saleItem];
    [self applyDiscount];
    [self.delegate wizardStep:self isValid:self.isValid];
    [self updateTotal];
}
- (IBAction)addSaleItemFromSelectedService:(id)sender {
    NSInteger row = self.servicesListTable.selectedRow;
    NSButton * button = sender;
    if (row >= 0) {
        Service * service = self.services[row];
        self.employeeForServiceViewController.service = service;
        [self.employeeForServiceViewController prepareForDisplayWithSalon:self.salonDocument];
        [self presentViewController:self.employeeForServiceViewController asPopoverRelativeToRect:button.bounds ofView:button preferredEdge:NSMaxXEdge behavior:NSPopoverBehaviorApplicationDefined];
    }
}
-(void)dismissViewController:(NSViewController *)viewController {
    if (viewController == self.employeeForServiceViewController && ! self.employeeForServiceViewController.cancelled) {
        [self addSaleItemForService:self.employeeForServiceViewController.service performedBy:self.employeeForServiceViewController.employee];
    }
    if (viewController == self.quickQuoteViewController) {
        _saleItemsArray = nil;
        [self.saleItemsTable reloadData];
        self.totalLabel.objectValue = self.sale.actualCharge;
    }
    [super dismissViewController:viewController];
}
-(void)addSaleItemForService:(Service*)service performedBy:(Employee*)employee {
    Sale * sale = [self.delegate wizardStepRequiresSale:self];
    SaleItem * saleItem = [self newSaleItem];
    saleItem.service = service;
//    NSAssert(employee, @"Employee is set to nil");
    saleItem.performedBy = employee;
    [sale addSaleItemObject:saleItem];
    [self.saleItemsArray addObject:saleItem];
    [self.saleItemsTable reloadData];
    NSInteger index = [self.saleItemsArray indexOfObject:saleItem];
    [self.saleItemsTable selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
    [self saleItemWasSelected];
    [self updateTotal];
}
-(BOOL)isValid
{
    if (!self.saleItemsArray || self.saleItemsArray.count == 0) return NO;
    return YES;
}
- (IBAction)showProductsInfo:(id)sender {
}
- (IBAction)showDiscountInfo:(id)sender {
}
- (IBAction)discountChanged:(id)sender {
    [self applyDiscount];
    [self updateTotal];
}
-(void)updateTotal {
    [self.sale updatePriceFromSaleItems];
    self.totalLabel.objectValue = self.sale.actualCharge;
}
-(void)removeSaleItem:(id)sender
{
    NSInteger row = self.saleItemsTable.selectedRow;
    if (row >= 0) {
        SaleItem * saleItem = self.saleItemsArray[row];
        [self.saleItemsArray removeObjectAtIndex:row];
        [[self sale] removeSaleItemObject:saleItem];
        saleItem.service = nil;
        [self.saleItemsTable deselectAll:self];
        [self.saleItemsTable reloadData];
        if (self.saleItemsArray.count == 0) {
            [self.delegate wizardStep:self isValid:self.isValid];
            [self clearPriceAndDiscount];
        }
        [self updateTotal];
    }
}
#pragma mark - Helpers
-(SaleItem*)selectedSaleItem
{
    SaleItem * saleItem = nil;
    NSInteger row = self.saleItemsTable.selectedRow;
    if (row >= 0) {
        saleItem = self.saleItemsArray[row];
    }
    return saleItem;
}
-(NSMutableArray*)saleItemsArray
{
    if (!_saleItemsArray) {
        Sale * sale = self.sale;
        NSSet * saleItems = sale.saleItem;
        _saleItemsArray = [[[saleItems allObjects] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"createdDate" ascending:YES]]] mutableCopy];
        if (!_saleItemsArray) {
            _saleItemsArray = [NSMutableArray array];
        }
    }
    return _saleItemsArray;
}
-(void)serviceListItemWasSelected
{
    NSInteger row = self.servicesListTable.selectedRow;
    if (row >= 0) {
        [self.servicesBox setHidden:NO];
        Service * service = self.services[row];
    
        self.nameOfService.stringValue = service.displayText;
        self.nominalPriceOrPriceRange.stringValue = [self priceRangeStringFromMinimumPrice:service.minimumCharge maximumPrice:service.maximumCharge nominalCharge:service.nominalCharge];
        if (service.hairLength.integerValue == 0) {
            self.hairLength.stringValue = @"Not applicable";
        } else {
            self.hairLength.stringValue = service.hairLengthDescription;
        }
        [self.deluxeImage setHidden:!service.deluxe.boolValue];
        [self.addSelectedServiceButton setEnabled:self.enabled];
    } else {
        [self.addSelectedServiceButton setEnabled:NO];
    }
}
-(void)saleItemWasSelected
{
    SaleItem * selectedSaleItem = [self selectedSaleItem];
    if (selectedSaleItem) {
        [self setPriceAndDiscountFromSelectedSaleItem];
        [self.selectedSaleItemBox setHidden:NO];
        if ([self selectedSaleItem].refund) {
            [self.refundButton setEnabled:NO];
        } else {
            [self.refundButton setEnabled:YES];
        }
        self.numberFormatterForSelectedItemPriceBeforeDiscount.minimum = selectedSaleItem.service.minimumCharge;
        self.numberFormatterForSelectedItemPriceBeforeDiscount.maximum = selectedSaleItem.service.maximumCharge;
    } else {
        [self.removeSaleItemButton setEnabled:NO];
        [self clearPriceAndDiscount];
        [self.selectedSaleItemBox setHidden:YES];
        [self.refundButton setEnabled:NO];
    }
    switch (self.editMode) {
        case EditModeCreate:
        {
            break;
        }
        case EditModeEdit:
        {
            [self.refundButton setEnabled:YES];
            if (selectedSaleItem.refund) {
                [self.refundButton setTitle:@"View refund on this item"];
            } else {
                [self.refundButton setTitle:@"Refund customer for this item"];
            }
            break;
        }
        case EditModeView:
        {
            [self.refundButton setEnabled:YES];
            if (selectedSaleItem.refund) {
                [self.refundButton setTitle:@"View refund on this item"];
            } else {
                [self.refundButton setTitle:@"Refund customer for this item"];
            }
            break;
        }
    }
    [self.delegate wizardStep:self isValid:self.isValid];
}
-(void)clearPriceAndDiscount
{
    self.minimumPrice.stringValue = @"£0";
    self.maximumPrice.stringValue = @"£0";
    self.nominalPriceOrPriceRange.stringValue = @"£0";
    self.chargePriceBeforeDiscount.stringValue = @"";
    self.chargePriceAfterDiscount.stringValue = @"£0.00";
    [self.discountPopup selectItemAtIndex:0];
    [self.priceSlider setEnabled:NO];
    [self.chargePriceBeforeDiscount setEnabled:NO];
}
-(void)setPriceAndDiscountFromSelectedSaleItem
{
    NSInteger row = self.saleItemsTable.selectedRow;
    if (row >= 0) {
        SaleItem * saleItem = self.saleItemsArray[row];
        Service * service = saleItem.service;
        double min = 0;
        double max = 0;
        if (service.minimumCharge) {
            min = service.minimumCharge.doubleValue;
        } else {
            min = service.nominalCharge.doubleValue;
        }
        if (service.maximumCharge) {
            max = service.maximumCharge.doubleValue;
        } else {
            max = service.nominalCharge.doubleValue;
        }
        [self.discountPopup selectItemAtIndex:saleItem.discountType.integerValue];
        BOOL enablePriceSlider = (self.enabled && (min < max));
        [self.priceSlider setEnabled:enablePriceSlider];
        [self.chargePriceBeforeDiscount setEnabled:YES];
        [self.chargePriceBeforeDiscount setEditable:NO];
        if (enablePriceSlider) {
            self.chargePriceBeforeDiscount.textColor = [NSColor keyboardFocusIndicatorColor];
        } else {
            self.chargePriceBeforeDiscount.textColor = [NSColor textColor];
        }
        
        [self.discountPopup setEnabled:self.enabled];
        max = fmax(max, service.nominalCharge.doubleValue);
        if (saleItem.nominalCharge.doubleValue < 0) {
            // sale item charge has not been set before
            saleItem.minimumCharge = @(min);
            saleItem.maximumCharge = @(max);
            saleItem.nominalCharge = [service.nominalCharge copy];
        }
        [self setPriceBeforeDiscountFromSaleItem:(SaleItem*)saleItem];
        [self.removeSaleItemButton setEnabled:self.enabled];
        [self applyDiscount];
    }
}
-(void)setPriceBeforeDiscountFromSaleItem:(SaleItem*)saleItem
{
    double min = floor(saleItem.minimumCharge.doubleValue);
    double max = ceil(saleItem.maximumCharge.doubleValue);
    double charge = round(saleItem.nominalCharge.doubleValue);
    saleItem.minimumCharge = @(min);
    saleItem.maximumCharge = @(max);
    saleItem.nominalCharge = @(charge);
    self.minimumPrice.stringValue = [@"£" stringByAppendingFormat:@"%@",@(min)];
    self.maximumPrice.stringValue = [@"£" stringByAppendingFormat:@"%@",@(max)];
    [self.priceSlider setMinValue:min];
    [self.priceSlider setMaxValue:max];
    [self.priceSlider setDoubleValue:charge];
    saleItem.nominalCharge = @(charge);
    self.chargePriceBeforeDiscount.doubleValue = charge;
}
-(Sale*)sale
{
    return [self.delegate wizardStepRequiresSale:self];
}
-(SaleItem*)newSaleItem
{
    NSManagedObjectContext * moc = self.documentMoc;
    SaleItem * saleItem = [NSEntityDescription insertNewObjectForEntityForName:@"SaleItem" inManagedObjectContext:moc];
    saleItem.nominalCharge = @(-1);
    return saleItem;
}
-(NSString*)priceRangeStringFromMinimumPrice:(NSNumber*)minimumPrice maximumPrice:(NSNumber*)maximumPrice nominalCharge:(NSNumber*)nominalCharge
{
    NSString * string = @"";
    if (minimumPrice && minimumPrice.doubleValue >= 0) {
        string = [NSString stringWithFormat:@"£%@",minimumPrice];
        if (maximumPrice && (maximumPrice.doubleValue == minimumPrice.doubleValue)) {
            return string;
        }
    }
    if (maximumPrice && maximumPrice.doubleValue > 0) {
        if (minimumPrice) {
            string = [string stringByAppendingFormat:@" – £%@",maximumPrice];
        } else {
            string = [string stringByAppendingFormat:@"£%@",maximumPrice];
        }
    }
    if (string.length == 0) {
        string = [NSString stringWithFormat:@"£%@",nominalCharge];
    }
    return string;
}
-(void)applyDiscount
{
    SaleItem * saleItem = [self selectedSaleItem];
    double amount = saleItem.nominalCharge.doubleValue;
    AMCDiscount discount = self.discountPopup.indexOfSelectedItem;
    saleItem.discountType = @(discount);
    double discountedPrice = [AMCDiscountCalculator calculateDiscountedPriceWithDiscountType:discount undiscountedPrice:amount];
    self.selectedSaleItem.actualCharge = @(discountedPrice);
    self.chargePriceAfterDiscount.stringValue = [NSString stringWithFormat:@"£%1.2f",discountedPrice];
}
- (IBAction)totalInfoButtonClicked:(id)sender {
    Sale * sale = self.sale;
    AMCQuickQuoteViewController * vc = self.quickQuoteViewController;
    vc.sale = sale;
    [vc prepareForDisplayWithSalon:self.salonDocument];
    [self presentViewController:vc asPopoverRelativeToRect:self.quickQuoteButton.bounds ofView:self.quickQuoteButton preferredEdge:NSMinYEdge behavior:NSPopoverBehaviorTransient];
}

- (IBAction)refundButtonClicked:(id)sender {
    AMCRefundViewController * vc = [AMCRefundViewController new];
    vc.saleItem = [self selectedSaleItem];
    [self presentViewController:vc asPopoverRelativeToRect:self.refundButton.bounds ofView:self.refundButton preferredEdge:NSMinYEdge behavior:NSPopoverBehaviorTransient];
}
-(void)popoverDidClose:(NSNotification *)notification
{
    [self saleItemWasSelected];
}

@end
