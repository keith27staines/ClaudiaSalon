//
//  ObjectSelectorViewController.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 23/07/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//
#import "AMCSalonDocument.h"
#import <Cocoa/Cocoa.h>

@interface ObjectSelectorViewController : AMCViewController <NSTableViewDataSource, NSTableViewDelegate>

@property (strong) NSArray * objects;
@property (weak,readonly) id selectedObject;
@property (readonly) BOOL isCancelled;
@property (weak) IBOutlet NSButton * selectButton;
@property (weak) IBOutlet NSButton * cancelButton;

-(IBAction)selectObject:(id)sender;
-(IBAction)cancel:(id)sender;

@property (weak) IBOutlet NSTableView * objectTable;


@end
