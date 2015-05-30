//
//  AMCViewControllerWithArrayController.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 29/05/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "AMCViewController.h"

@interface AMCViewControllerWithArrayController : AMCViewController
@property (strong) IBOutlet NSArrayController *arrayController;
@property (weak) IBOutlet NSTableView *dataTable;

@property (readonly) id selectedObject;
@property (readonly) id rightClickedObject;
-(NSArray*)initialSortDescriptors;
-(NSRect)cellRectForObject:(id)object column:(NSInteger)column;

@end
