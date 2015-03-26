//
//  AMCProductSelectorWindowController.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 10/01/2015.
//  Copyright (c) 2015 Keith Staines. All rights reserved.
//

#import "AMCProductSelectorWindowController.h"
#import "StockedProduct+Methods.h"
#import "StockedBrand+Methods.h"
#import "StockedCategory+Methods.h"
#import "AMCStockedBrandMaintenanceWindowController.h"
#import "AMCStockedCategoryMaintenanceWindowController.h"

@interface AMCProductSelectorWindowController ()
@property NSArray * filteredObjects;
@property NSArray * displayedObjects;
@end

@implementation AMCProductSelectorWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    [self populateStockCategoriesSelector];
    [self populateBrandSelector];
    NSMutableArray * sortDescriptors = [NSMutableArray array];
    [sortDescriptors addObject:[NSSortDescriptor sortDescriptorWithKey:@"stockedBrand.shortBrandName" ascending:YES]];
    [sortDescriptors addObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];
    [sortDescriptors addObject:[NSSortDescriptor sortDescriptorWithKey:@"code" ascending:YES]];
    [sortDescriptors addObject:[NSSortDescriptor sortDescriptorWithKey:@"barcode" ascending:YES]];
    [self.dataTable setSortDescriptors:sortDescriptors];
    [self reloadData];
}
-(NSString *)windowNibName {
    return @"AMCProductSelectorWindowController";
}

-(void)populateStockCategoriesSelector {
    NSMenu * menu = self.categorySelector.menu;
    [menu removeAllItems];
    
    NSMenuItem * menuItem = [[NSMenuItem alloc] init];
    menuItem.representedObject = nil;
    menuItem.title = @"All categories";
    [menu addItem:menuItem];
    [self.categorySelector selectItem:menuItem];
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
-(void)populateBrandSelector {
    NSMenu * menu = self.brandSelector.menu;
    [menu removeAllItems];
    
    NSMenuItem * menuItem = [[NSMenuItem alloc] init];
    menuItem.representedObject = nil;
    menuItem.title = @"All brands";
    [menu addItem:menuItem];
    [self.brandSelector selectItem:menuItem];
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
-(NSPredicate*)filtersPredicate {
    NSMutableArray * predicates = [NSMutableArray array];
    StockedCategory * category = self.categorySelector.selectedItem.representedObject;
    if (category) {
        [predicates addObject:[NSPredicate predicateWithFormat:@"stockedCategory = %@",category]];
    }
    StockedBrand * brand = self.brandSelector.selectedItem.representedObject;
    if (brand) {
        [predicates addObject:[NSPredicate predicateWithFormat:@"stockedBrand = %@",brand]];
    }
    if (predicates.count == 0) {
        return nil;
    } else {
        return [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
    }
}
-(void)reloadData {
    NSManagedObjectContext * moc = self.documentMoc;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"StockedProduct" inManagedObjectContext:moc];
    [fetchRequest setEntity:entity];
    // Specify criteria for filtering which objects to fetch
    NSPredicate *predicate = [self filtersPredicate];
    [fetchRequest setPredicate:predicate];
    
    NSError *error = nil;
    self.filteredObjects = [moc executeFetchRequest:fetchRequest error:&error];
    if (self.filteredObjects == nil) {
        [NSApp presentError:error];
    }
    [self applySearchFilter];
    self.displayedObjects = [self.displayedObjects sortedArrayUsingDescriptors:self.dataTable.sortDescriptors];
    [self.dataTable reloadData];
    [self.selectProductButton setEnabled:NO];
}
-(void)applySearchFilter {
    NSString * search = self.searchField.stringValue;
    if (!search || search.length == 0) {
        self.displayedObjects = [self.filteredObjects copy];
        return;
    }
    NSPredicate * searchPredicate = [NSPredicate predicateWithFormat:@"code contains[cd] %@ or name contains[cd] %@ or stockedBrand.shortBrandName contains[cd] %@ or barcode = %@",search, search,search,search];
    self.displayedObjects = [self.filteredObjects filteredArrayUsingPredicate:searchPredicate];
}
#pragma mark - NSTableViewDelegate
-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.displayedObjects.count;
}
-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    StockedProduct * product = self.displayedObjects[row];
    NSString * columnID = tableColumn.identifier;
    NSTableCellView * view = [tableView makeViewWithIdentifier:columnID owner:self];
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
    if ([columnID isEqualToString:@"barcode"]) {
        view.textField.stringValue = (product.barcode)?product.barcode:@"";
        return view;
    }
    return nil;
}
-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    return self.displayedObjects[row];
}
-(BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row {
    return YES;
}
-(void)tableViewSelectionDidChange:(NSNotification *)notification {
    [self.selectProductButton setEnabled:(self.dataTable.selectedRow >=0)];
}
-(void)tableView:(NSTableView *)tableView sortDescriptorsDidChange:(NSArray *)oldDescriptors {
    [self reloadData];
}
#pragma mark - Actions
-(IBAction)categoryChanged:(id)sender {
    [self reloadData];
}

- (IBAction)brandChanged:(id)sender {
    [self reloadData];
}

- (IBAction)searchFieldChanged:(id)sender {
    [self applySearchFilter];
    [self.dataTable reloadData];
    [self.selectProductButton setEnabled:NO];
}

- (IBAction)cancel:(id)sender {
    self.product = nil;
    [self.callingWindow endSheet:self.window];
}

- (IBAction)selectProduct:(id)sender {
    self.product = self.displayedObjects[self.dataTable.selectedRow];
    [self.callingWindow endSheet:self.window];
}
- (IBAction)editBrandListClicked:(id)sender {
    NSWindow * sheet = self.brandMaintenanceWindowController.window;
    self.brandMaintenanceWindowController.sourceWindow = self.window;
    [self.window beginSheet:sheet completionHandler:^(NSModalResponse returnCode) {
        [self populateBrandSelector];
        [self reloadData];
    }];
}
- (IBAction)editCategoryList:(id)sender {
    NSWindow * sheet = self.categoryMaintenanceWindowController.window;
    self.categoryMaintenanceWindowController.sourceWindow = self.window;
    [self.window beginSheet:sheet completionHandler:^(NSModalResponse returnCode) {
        [self populateStockCategoriesSelector];
        [self reloadData];
    }];
}

@end
