//
//  AMCShoppingListPrintViewController.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 04/01/2015.
//  Copyright (c) 2015 Keith Staines. All rights reserved.
//
@class AMCShoppingListPrintView;
#import <Cocoa/Cocoa.h>
#import "AMCSalonDocument.h"
@interface AMCShoppingListPrintViewController : AMCViewController

@property (weak) IBOutlet AMCShoppingListPrintView *shoppingListView;

@end
