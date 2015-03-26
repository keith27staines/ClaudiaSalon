//
//  AMCAssociatedNotesViewController.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 29/08/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "AMCAssociatedNotesViewController.h"
#import "Note+Methods.h"
#import "AMCNoteViewController.h"
#import "AMCNoteView.h"

@interface AMCAssociatedNotesViewController ()
{
    id<AMCObjectWithNotesProtocol> _objectWithNotes;
}
@property NSArray * notesArray;
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
    Note * newNote = [Note newObjectWithMoc:self.documentMoc];
    newNote.title = self.titleForNewNote.stringValue;
    newNote.text = self.textForNewNote.stringValue;
    newNote.isAuditNote = @(NO);
    self.titleForNewNote.stringValue = @"";
    self.textForNewNote.stringValue = @"";
    [self.objectWithNotes addNotesObject:newNote];
    [self reloadData];
}
- (IBAction)removeNoteButtonClicked:(id)sender {
    NSInteger row = self.notesTable.selectedRow;
    if (row>=0) {
        Note * note = self.notesArray[row];
        [self.objectWithNotes removeNotesObject:note];
        [self reloadData];
    }
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
    self.notesArray = [notes sortedArrayUsingDescriptors:@[sort]];
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
    Note * note = self.notesArray[row];
    noteView.titleField.stringValue = note.title;
    NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    NSString * text = [dateFormatter stringFromDate:note.createdDate];
    text = [text stringByAppendingString:@" "];
    text = [text stringByAppendingString:note.text];
    noteView.textField.stringValue = text;
    return noteView;
}
@end
