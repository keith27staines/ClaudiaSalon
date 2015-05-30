//
//  AMCViewControllerWithArrayController.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 29/05/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "AMCViewControllerWithArrayController.h"
#import "AMCAssociatedNotesViewController.h"
#import "EditObjectViewController.h"

@interface AMCViewControllerWithArrayController () <NSTableViewDelegate,NSMenuDelegate, NSAnimationDelegate,EditObjectViewControllerDelegate>


@property (strong) IBOutlet AMCAssociatedNotesViewController *notesViewController;
@property (strong) IBOutlet EditObjectViewController *editObjectViewController;
@property (weak) IBOutlet NSButton *addObjectButton;
@property (weak) IBOutlet NSButton *viewObjectButton;
@property (weak) IBOutlet NSButton *actionButton;
@property (weak) IBOutlet NSButton *notesButton;
@property (strong) IBOutlet NSMenu *actionMenu;
@property (strong) IBOutlet NSMenu *rightClickMenu;
@property id selectedObject;
@property id previouslySelectedObject;
@property NSRect notesButtonInitialRect;
@property NSAnimation * notesUpAnimation;
@property NSAnimation * notesDownAnimation;
@end

@implementation AMCViewControllerWithArrayController

-(void)viewDidLoad {
    self.arrayController.sortDescriptors = [self initialSortDescriptors];
    [self.arrayController rearrangeObjects];
    self.dataTable.doubleAction = @selector(showDetailsForSelectedObject:);
}
-(NSArray *)initialSortDescriptors {
    return @[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)]];
}
-(void)prepareForDisplayWithSalon:(AMCSalonDocument *)salonDocument {
    [super prepareForDisplayWithSalon:salonDocument];
    self.arrayController.managedObjectContext = self.documentMoc;
    [self.arrayController rearrangeObjects];
}

#pragma mark - Action: Other Actions
- (IBAction)showActionMenu:(id)sender {
    [self.actionButton.menu popUpMenuPositioningItem:nil atLocation:NSMakePoint(0, NSMaxY(self.actionButton.bounds)) inView:self.actionButton];
}
#pragma mark - Action: Add Object
- (IBAction)addObject:(id)sender {
    self.previouslySelectedObject = self.selectedObject;
    id object = [self.arrayController newObject];
    [self.arrayController addObject:object];
    [self selectObject:object];
    [self showEditorForObject:object editMode:EditModeCreate];
}
#pragma mark - Action: View Object Details
- (IBAction)rightClickViewDetails:(id)sender {
    [self showDetailsForObject:[self rightClickedObject]];
}
- (IBAction)showDetailsForSelectedObject:(id)sender {
    [self showDetailsForObject:self.selectedObject];
}
-(void)showDetailsForObject:(id)object {
    [self showEditorForObject:object editMode:EditModeView];
}
-(void)showEditorForObject:(id)object editMode:(EditMode)editMode {
    NSRect rect = [self cellRectForObject:object column:0];
    [self.editObjectViewController clear];
    self.editObjectViewController.delegate = self;
    self.editObjectViewController.objectToEdit = object;
    self.editObjectViewController.editMode = editMode;
    [self.editObjectViewController prepareForDisplayWithSalon:self.salonDocument];
    [self presentViewController:self.editObjectViewController asPopoverRelativeToRect:rect ofView:self.dataTable preferredEdge:NSMaxYEdge behavior:NSPopoverBehaviorTransient];
}

#pragma mark - Action: Show notes popover
- (IBAction)rightClickShowNotes:(id)sender {
    [self showNotesForObject:[self rightClickedObject]];
}
- (IBAction)showNotesForSelectedObject:(id)sender {
    [self showNotesForObject:self.selectedObject];
}
-(void)showNotesForObject:(id)object {
    NSRect rect = [self cellRectForObject:object column:0];
    self.notesViewController.objectWithNotes = object;
    [self.notesViewController prepareForDisplayWithSalon:self.salonDocument];
    [self presentViewController:self.notesViewController asPopoverRelativeToRect:rect ofView:self.dataTable preferredEdge:NSMaxYEdge behavior:NSPopoverBehaviorTransient];
}
#pragma mark - NSTableViewDelegate
-(void)tableViewSelectionDidChange:(NSNotification *)notification {
    NSInteger row = self.dataTable.selectedRow;
    if (row < 0 ) {
        self.selectedObject = nil;
    } else {
        self.selectedObject = self.arrayController.arrangedObjects[row];
        [self animateNotesButton:self.notesButton ifNecessaryForObject:self.selectedObject];
    }
}
-(BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    return NO;
}
#pragma mark - NSMenuDelegate
-(void)menuNeedsUpdate:(NSMenu *)menu {
    id object = nil;
    if (menu == self.actionMenu) {
        object = self.selectedObject;
    } else {
        object = [self rightClickedObject];
    }
    for (NSMenuItem * item in menu.itemArray) {
        item.enabled = (object != nil);
    }
}
#pragma mark - EditViewControllerDelegate
-(void)editObjectViewController:(EditObjectViewController *)controller didEditObject:(id)object {
    
}
-(void)editObjectViewController:(EditObjectViewController *)controller didCancelCreationOfObject:(id)object {
    [self.arrayController removeObject:object];
    [self selectObject:self.previouslySelectedObject];
}
-(void)editObjectViewController:(EditObjectViewController *)controller didCompleteCreationOfObject:(id)object {
    [self.dataTable reloadData];
    [self selectObject:object];
}
#pragma mark - Notes icon animation
-(void)animateNotesButton:(NSButton*)button ifNecessaryForObject:(id<AMCObjectWithNotesProtocol>)selectedObject {
    if (selectedObject && selectedObject.nonAuditNotes.count > 0) {
        [self animateNotesButton:button];
    }
}
-(void)animateNotesButton:(NSButton*)button {
    NSRect notesViewFrame;
    self.notesButtonInitialRect = button.frame;
    NSRect newViewFrame;
    NSMutableDictionary* notesViewDict;
    
    // Create the attributes dictionary for the notes view
    notesViewDict = [NSMutableDictionary dictionaryWithCapacity:3];
    notesViewFrame = [button frame];
    
    // Specify which view to modify.
    [notesViewDict setObject:button forKey:NSViewAnimationTargetKey];
    
    // Specify the starting position of the view.
    [notesViewDict setObject:[NSValue valueWithRect:notesViewFrame]
                      forKey:NSViewAnimationStartFrameKey];
    
    // Change the ending position of the view.
    newViewFrame = notesViewFrame;
    newViewFrame.origin.y += 25;
    [notesViewDict setObject:[NSValue valueWithRect:newViewFrame]
                      forKey:NSViewAnimationEndFrameKey];
    
    // Create the view animation object.
    NSViewAnimation *theAnim;
    theAnim = [[NSViewAnimation alloc] initWithViewAnimations:@[notesViewDict]];
    
    // Set some additional attributes for the animation.
    [theAnim setDuration:0.5];    // One and a half seconds.
    [theAnim setAnimationCurve:NSAnimationEaseInOut];
    [theAnim setAnimationBlockingMode:NSAnimationNonblocking];
    [theAnim setDelegate:self];
    self.notesUpAnimation = theAnim;
    
    [notesViewDict setObject:[NSValue valueWithRect:newViewFrame]
                      forKey:NSViewAnimationStartFrameKey];
    [notesViewDict setObject:[NSValue valueWithRect:notesViewFrame]
                      forKey:NSViewAnimationEndFrameKey];
    theAnim = [[NSViewAnimation alloc] initWithViewAnimations:@[notesViewDict]];
    
    // Set some additional attributes for the animation.
    [theAnim setDuration:0.5];    // half second.
    [theAnim setAnimationCurve:NSAnimationEaseInOut];
    [theAnim setAnimationBlockingMode:NSAnimationNonblocking];
    [theAnim setDelegate:self];
    self.notesDownAnimation = theAnim;
    
    // Run the animation.
    [self.notesUpAnimation startAnimation];
}
#pragma mark - NSAnimationDelegate
-(void)animation:(NSAnimation *)animation didReachProgressMark:(NSAnimationProgress)progress {
    if (animation == self.notesUpAnimation && progress == 1) {
        [self.notesDownAnimation startAnimation];
    }
}
#pragma mark - Helpers
-(id)rightClickedObject {
    NSInteger row = self.dataTable.clickedRow;
    id object = self.arrayController.arrangedObjects[row];
    [self selectObject:object];
    return object;
}
-(void)selectObject:(id)object {
    if (!object) {
        [self.dataTable deselectAll:self];
        return;
    }
    NSInteger row = [self.arrayController.arrangedObjects indexOfObject:object];
    [self.view.window makeFirstResponder:self.dataTable];
    [self.dataTable selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    self.selectedObject = object;
    [self.dataTable scrollRowToVisible:row];
    [self animateNotesButton:self.notesButton ifNecessaryForObject:object];
}
-(NSRect)cellRectForObject:(id)object column:(NSInteger)column {
    NSInteger row = [self.arrayController.arrangedObjects indexOfObject:object];
    NSRect columnRect = [self.dataTable rectOfColumn:column];
    NSRect rowRect = [self.dataTable rectOfRow:row];
    return NSIntersectionRect(rowRect, columnRect);
}
@end

