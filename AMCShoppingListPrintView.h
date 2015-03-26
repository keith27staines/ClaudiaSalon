//
//  AMCShoppingListPrintView.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 04/01/2015.
//  Copyright (c) 2015 Keith Staines. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AMCSalonDocument.h"
@interface AMCShoppingListPrintView : NSView
@property (weak) AMCSalonDocument * document;
@property (weak) NSArray * products;
-(void)reloadData;
@end
