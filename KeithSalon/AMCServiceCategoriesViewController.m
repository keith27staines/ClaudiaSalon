//
//  AMCServiceCategoriesController.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 29/05/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "AMCServiceCategoriesViewController.h"
#import "ServiceCategory+Methods.h"
#import "AMCAssociatedNotesViewController.h"
#import "EditServiceCategoryViewController.h"

@interface AMCServiceCategoriesViewController () <NSTableViewDelegate,NSMenuDelegate, NSAnimationDelegate,EditObjectViewControllerDelegate>
@property (strong) IBOutlet NSArrayController *categoryArrayController;

@property (strong) IBOutlet AMCAssociatedNotesViewController *notesViewController;
@property (strong) IBOutlet EditServiceCategoryViewController *editCategoryViewController;

@property (weak) IBOutlet NSButton *addCategoryButton;
@property (weak) IBOutlet NSButton *viewCategoryButton;
@property (weak) IBOutlet NSButton *actionButton;
@property (weak) IBOutlet NSButton *notesButton;
@property (weak) IBOutlet NSTableView *categoryTable;
@property (strong) IBOutlet NSMenu *actionMenu;
@property (strong) IBOutlet NSMenu *rightClickMenu;

@property ServiceCategory * selectedCategory;
@property ServiceCategory * previouslySelectedCategory;

@property NSRect notesButtonInitialRect;
@property NSAnimation * notesUpAnimation;
@property NSAnimation * notesDownAnimation;
@end

@implementation AMCServiceCategoriesViewController

-(NSString *)nibName {
    return @"AMCServiceCategoriesViewController";
}
-(void)viewDidLoad {
    self.categoryArrayController.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"Name" ascending:YES]];
    [self.categoryArrayController rearrangeObjects];
    self.categoryTable.doubleAction = @selector(showDetailsForSelectedCategory:);
}
-(void)prepareForDisplayWithSalon:(AMCSalonDocument *)salonDocument {
    [super prepareForDisplayWithSalon:salonDocument];
    self.categoryArrayController.managedObjectContext = self.documentMoc;
}

#pragma mark - Action: Other Actions
- (IBAction)showActionMenu:(id)sender {
    [self.actionButton.menu popUpMenuPositioningItem:nil atLocation:NSMakePoint(0, NSMaxY(self.actionButton.bounds)) inView:self.actionButton];
}
#pragma mark - Action: Add Service
- (IBAction)addCategory:(id)sender {
    self.previouslySelectedCategory = self.selectedCategory;
    ServiceCategory * category = [ServiceCategory newObjectWithMoc:self.documentMoc];
    [self showServiceCategoryEditorForCategory:category editMode:EditModeCreate];
}
#pragma mark - Action: View Service Details
- (IBAction)rightClickViewDetails:(id)sender {
    [self showDetailsForCategory:[self categoryForRightClick]];
}
- (IBAction)showDetailsForSelectedCategory:(id)sender {
    [self showDetailsForCategory:self.selectedCategory];
}
-(void)showDetailsForCategory:(ServiceCategory*)category {
    [self showServiceCategoryEditorForCategory:category editMode:EditModeView];
}
-(void)showServiceCategoryEditorForCategory:(ServiceCategory*)category editMode:(EditMode)editMode {
    NSRect rect = [self rectForCategory:category column:0];
    self.editCategoryViewController.delegate = self;
    self.editCategoryViewController.objectToEdit = category;
    self.editCategoryViewController.editMode = editMode;
    [self.editCategoryViewController prepareForDisplayWithSalon:self.salonDocument];
    [self presentViewController:self.editCategoryViewController asPopoverRelativeToRect:rect ofView:self.categoryTable preferredEdge:NSMaxYEdge behavior:NSPopoverBehaviorTransient];
}

#pragma mark - Action: Show notes popover
- (IBAction)rightClickShowNotes:(id)sender {
    [self showNotesForCategory:[self categoryForRightClick]];
}
- (IBAction)showNotesForSelectedService:(id)sender {
    [self showNotesForCategory:self.selectedCategory];
}
-(void)showNotesForCategory:(ServiceCategory*)category {
    NSRect rect = [self rectForCategory:category column:0];
    self.notesViewController.objectWithNotes = category;
    [self.notesViewController prepareForDisplayWithSalon:self.salonDocument];
    [self presentViewController:self.notesViewController asPopoverRelativeToRect:rect ofView:self.categoryTable preferredEdge:NSMaxYEdge behavior:NSPopoverBehaviorTransient];
}
#pragma mark - NSTableViewDelegate
-(void)tableViewSelectionDidChange:(NSNotification *)notification {
    NSInteger row = self.categoryTable.selectedRow;
    self.selectedCategory = self.categoryArrayController.arrangedObjects[row];
}
#pragma mark - NSMenuDelegate
-(void)menuNeedsUpdate:(NSMenu *)menu {
    ServiceCategory * category = nil;
    if (menu == self.actionMenu) {
        category = self.selectedCategory;
    } else {
        category = [self categoryForRightClick];
    }
    for (NSMenuItem * item in menu.itemArray) {
        item.enabled = (category != nil);
    }
}
#pragma mark - EditViewControllerDelegate
-(void)editObjectViewController:(EditObjectViewController *)controller didCancelCreationOfObject:(id)object {
    [self.categoryArrayController removeObject:object];
    [self selectCategory:self.previouslySelectedCategory];
}
-(void)editObjectViewController:(EditObjectViewController *)controller didCompleteCreationOfObject:(id)object {
    [self.categoryTable reloadData];
    [self selectCategory:object];
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
-(ServiceCategory*)categoryForRightClick {
    NSInteger row = self.categoryTable.clickedRow;
    ServiceCategory * category = self.categoryArrayController.arrangedObjects[row];
    [self selectCategory:category];
    return category;
}
-(void)selectCategory:(ServiceCategory*)category {
    if (!category) {
        [self.categoryTable deselectAll:self];
        return;
    }
    NSInteger row = [self.categoryArrayController.arrangedObjects indexOfObject:category];
    [self.view.window makeFirstResponder:self.categoryTable];
    [self.categoryTable selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    self.selectedCategory = category;
    [self.categoryTable scrollRowToVisible:row];
    [self animateNotesButton:self.notesButton ifNecessaryForObject:category];
}
-(NSRect)rectForCategory:(ServiceCategory*)category column:(NSInteger)column {
    NSInteger row = [self.categoryArrayController.arrangedObjects indexOfObject:category];
    NSRect columnRect = [self.categoryTable rectOfColumn:column];
    NSRect rowRect = [self.categoryTable rectOfRow:row];
    return NSIntersectionRect(rowRect, columnRect);
}
@end
