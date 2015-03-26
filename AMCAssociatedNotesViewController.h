//
//  AMCAssociatedNotesViewController.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 29/08/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

@class Note;
#import <Cocoa/Cocoa.h>
#import "AMCSalonDocument.h"
#import "AMCObjectWithNotesProtocol.h"

@interface AMCAssociatedNotesViewController : AMCViewController <NSTableViewDataSource, NSTableViewDelegate>

@property (weak) IBOutlet NSButton *addNoteButton;
@property (weak) IBOutlet NSButton *removeNoteButton;
- (IBAction)addNoteButtonClicked:(id)sender;
- (IBAction)removeNoteButtonClicked:(id)sender;

@property (weak) IBOutlet NSTableView *notesTable;

@property id<AMCObjectWithNotesProtocol>objectWithNotes;

@property (weak) IBOutlet NSTextField *viewTitle;
@property (weak) IBOutlet NSTextField *titleForNewNote;
@property (weak) IBOutlet NSTextField *textForNewNote;
@property (weak) IBOutlet NSTextField *existingNotesTitle;


@end
