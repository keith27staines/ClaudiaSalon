//
//  AMCProductSelectorWindowController.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 10/01/2015.
//  Copyright (c) 2015 Keith Staines. All rights reserved.
//
@class StockedProduct, AMCStockedBrandMaintenanceWindowController, AMCStockedCategoryMaintenanceWindowController;

#import <Cocoa/Cocoa.h>
#import "AMCSalonDocument.h"
@interface AMCProductSelectorWindowController : NSWindowController <NSTableViewDataSource, NSTableViewDelegate>

@property (weak) StockedProduct * product;
@property (weak) NSWindow * callingWindow;

- (IBAction)cancel:(id)sender;
- (IBAction)selectProduct:(id)sender;
@property (weak) IBOutlet NSPopUpButton *categorySelector;
@property (weak) IBOutlet NSPopUpButton *brandSelector;
@property (weak) IBOutlet NSSearchField *searchField;
- (IBAction)categoryChanged:(id)sender;
- (IBAction)brandChanged:(id)sender;
- (IBAction)searchFieldChanged:(id)sender;
@property (weak) IBOutlet NSTableView *dataTable;
@property (weak) IBOutlet NSButton *selectProductButton;
@property (weak) IBOutlet AMCStockedCategoryMaintenanceWindowController * categoryMaintenanceWindowController;
@property (weak) IBOutlet AMCStockedBrandMaintenanceWindowController * brandMaintenanceWindowController;

@end
