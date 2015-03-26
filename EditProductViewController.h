//
//  EditProductViewController.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 21/07/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "EditObjectViewController.h"
#import "AMCSalonDocument.h"
@interface EditProductViewController : EditObjectViewController

@property (weak) IBOutlet NSTextField *brandName;
@property (weak) IBOutlet NSTextField *productType;

@end
