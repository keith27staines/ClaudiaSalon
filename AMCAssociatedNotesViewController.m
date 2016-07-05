//
//  AMCAssociatedNotesViewController.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 29/08/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "AMCAssociatedNotesViewController.h"
#import "Note.h"
#import "AMCNoteViewController.h"
#import "AMCNoteView.h"

@interface AMCAssociatedNotesViewController ()
{
    id<AMCObjectWithNotesProtocol> _objectWithNotes;
}
@property NSMutableArray * notesArray;
@end

@implementation AMCAssociatedNotesViewController

-(NSString *)nibName {
    return @"AMCAssociatedNotesViewController";
}
-(void)setObjectWithNotes:(id<AMCObjectWithNotesProtocol>)objectWithNotes {
    _objectWithNotes = objectWithNotes;
}
-(void)prepareForDisplayWithSalon:(AMCSalonDocument *)salonDocument {
    [super prepareForDisplayWithSalon:salonDocument];
    [self reloadData];
}
-(id<AMCObjectWithNotesProtocol>)objectWithNotes {
    return _objectWithNotes;
}
- (IBAction)addNoteButtonClicked:(id)sender {
    Note * newNote = [Note createObjectInMoc:self.documentMoc];
    newNote.isAuditNote = @(NO);
    newNote.title = nil;
    newNote.text = nil;
    [self addNote:newNote atRow:0];
    [self setFocusOnTitleFieldForNote:newNote];
}
-(void)setFocusOnTitleFieldForNote:(Note*)note {
    NSInteger row = [self.notesArray indexOfObject:note];
    AMCNoteView * view = [self.notesTable viewAtColumn:0 row:row makeIfNecessary:NO];
    if (view) {
        [self.view.window makeFirstResponder:view.titleField];
    }
}
- (IBAction)removeNoteButtonClicked:(id)sender {
    NSInteger row = self.notesTable.selectedRow;
    [self removeNoteAtRow:row];
}
-(void)removeNoteView:(id)sender {
    AMCNoteView * noteView = sender;
    NSInteger row = [self.notesTable rowForView:noteView];
    [self removeNoteAtRow:row];
}
-(void)removeNoteAtRow:(NSInteger)row {
    if (row>=0 && row < self.notesArray.count) {
        Note * note = self.notesArray[row];
        [[self.undoManager prepareWithInvocationTarget:self] addNote:note atRow:row];
        if (![self.undoManager isUndoing]) {
            [self.undoManager setActionName:NSLocalizedString(@"Remove Note", @"Remove Note")];
        }
        [self.objectWithNotes removeNotesObject:note];
        [self.notesArray removeObject:note];
        [self.notesTable removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:row] withAnimation:NSTableViewAnimationSlideUp];
        [self.notesTable selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    }
}
-(void)addNote:(Note*)note atRow:(NSInteger)row {
    [[self.undoManager prepareWithInvocationTarget:self] removeNoteAtRow:row];
    if (![self.undoManager isUndoing]) {
        [self.undoManager setActionName:NSLocalizedString(@"Add Note", @"Add Note")];
    }
    [self.notesTable scrollRowToVisible:row];
    [self.objectWithNotes addNotesObject:note];
    [self.notesArray insertObject:note atIndex:row];
    [self.notesTable insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:row] withAnimation:NSTableViewAnimationSlideDown];
    [self.notesTable selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
}
-(void)reloadData {
    if (!self.objectWithNotes) return;
    NSArray * notes;
    if ([self.objectWithNotes respondsToSelector:@selector(nonAuditNotes)]) {
        notes = [[self.objectWithNotes nonAuditNotes] allObjects];
    } else {
        notes = [[self.objectWithNotes notes] allObjects];
    }
    NSSortDescriptor * sort = [NSSortDescriptor sortDescriptorWithKey:@"createdDate" ascending:NO];
    self.notesArray = [[notes sortedArrayUsingDescriptors:@[sort]] mutableCopy];
    [self.notesTable reloadData];
    if (self.notesArray.count == 1) {
        self.existingNotesTitle.stringValue = [NSString stringWithFormat:@"There is 1 existing note for this %@",[self.objectWithNotes class]];
    } else {
        self.existingNotesTitle.stringValue = [NSString stringWithFormat:@"There are %lu existing notes for this %@",(unsigned long)self.notesArray.count,[self.objectWithNotes class]];
    }
    self.viewTitle.stringValue = [NSString stringWithFormat:@"Notes for this %@",[self.objectWithNotes class]];
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.notesArray.count;
}
-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    AMCNoteViewController * vc = [[AMCNoteViewController alloc] init];
    AMCNoteView * noteView = (AMCNoteView*)vc.view;
    noteView.note = self.notesArray[row];
    noteView.target = self;
    noteView.removeAction = @selector(removeNoteView:);
    return noteView;
}
-(void)tableViewSelectionDidChange:(NSNotification *)notification {
    for (NSInteger index = 0; index < self.notesArray.count; index++) {
        AMCNoteView * view = [self.notesTable viewAtColumn:0 row:index makeIfNecessary:YES];
        if ([self.notesTable.selectedRowIndexes containsIndex:index]) {
            view.isSelected = YES;
        } else {
            view.isSelected = NO;
        }
    }
}
@end
