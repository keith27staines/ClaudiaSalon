//
//  AMCViewControllerWithArrayController.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 29/05/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "AMCViewController.h"
#import "EditObjectViewController.h"

@interface AMCViewControllerWithArrayController : AMCViewController <NSTableViewDelegate,NSMenuDelegate, NSAnimationDelegate,EditObjectViewControllerDelegate>

@property (weak) IBOutlet NSButton *addObjectButton;
@property (weak) IBOutlet NSButton *viewObjectButton;
@property (weak) IBOutlet NSButton *actionButton;
@property (weak) IBOutlet NSButton *notesButton;
@property (strong) IBOutlet NSMenu *actionMenu;
@property (strong) IBOutlet NSMenu *rightClickMenu;
@property NSRect notesButtonInitialRect;
@property NSAnimation * notesUpAnimation;
@property NSAnimation * notesDownAnimation;

@property (strong) IBOutlet NSArrayController *arrayController;
@property (weak) IBOutlet NSTableView *dataTable;

@property (readonly) id selectedObject;
@property (readonly) id rightClickedObject;
-(NSArray*)initialSortDescriptors;
-(NSRect)cellRectForObject:(id)object column:(NSInteger)column;
@end
