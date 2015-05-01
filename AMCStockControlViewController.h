//
//  AMCStockControlViewController.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 28/12/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

@class StockedProduct, AMCStockedCategoryMaintenanceWindowController, AMCStockedBrandMaintenanceWindowController, AMCShoppingListPrintViewController, AMCBarcodeScanningViewController;

#import <Cocoa/Cocoa.h>
#import "AMCSalonDocument.h"
#import "AMCEntityViewController.h"

@interface AMCStockControlViewController : AMCEntityViewController <EditObjectViewControllerDelegate, NSTextFieldDelegate, NSWindowDelegate>

@property (weak) IBOutlet NSPopUpButton *stockedCategoryPopupButton;
@property (weak) IBOutlet NSPopUpButton *brandPopupButton;
@property (weak) IBOutlet NSPopUpButton *stockLevelPopupButton;
@property (nonatomic) NSInteger selectedItemStockLevel;
@property (nonatomic) NSInteger selectedItemNumberToBuy;

- (IBAction)filtersChanged:(id)sender;

- (IBAction)editCategoryList:(id)sender;
- (IBAction)editBrandListClicked:(id)sender;
- (IBAction)addNewProductClicked:(id)sender;

- (IBAction)searchFieldChanged:(id)sender;

@property (weak) IBOutlet NSTextField *currentStockTextField;

@property (strong) IBOutlet AMCStockedCategoryMaintenanceWindowController *stockedCategoryMaintenanceWindowController;
@property (strong) IBOutlet AMCStockedBrandMaintenanceWindowController *stockedBrandMaintenanceWindowController;

- (IBAction)clearShoppingList:(id)sender;
- (IBAction)printShoppingList:(id)sender;

- (IBAction)completeShoppingList:(id)sender;
@property (strong) IBOutlet AMCShoppingListPrintViewController *shoppingListPrintViewController;

@property (strong) IBOutlet AMCBarcodeScanningViewController *barcodeScanningViewController;
- (IBAction)enterBarcodeScanningMode:(id)sender;
@property (weak) IBOutlet NSButton *enterBarcodeModeButton;


@end
