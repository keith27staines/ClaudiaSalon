//
//  AMCServicesViewController.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 29/05/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "AMCServicesViewController.h"
#import "Service+Methods.h"
#import "AMCAssociatedNotesViewController.h"
#import "EditServiceViewController.h"

@interface AMCServicesViewController () <NSTableViewDelegate,NSMenuDelegate, NSAnimationDelegate,EditObjectViewControllerDelegate>
@property (strong) IBOutlet NSArrayController *servicesArrayController;

@property (strong) IBOutlet AMCAssociatedNotesViewController *notesViewController;
@property (strong) IBOutlet EditServiceViewController *editServiceViewController;

@property (weak) IBOutlet NSButton *addServiceButton;
@property (weak) IBOutlet NSButton *viewServiceButton;
@property (weak) IBOutlet NSButton *actionButton;
@property (weak) IBOutlet NSButton *notesButton;
@property (weak) IBOutlet NSTableView *servicesTable;
@property (strong) IBOutlet NSMenu *actionMenu;
@property (strong) IBOutlet NSMenu *rightClickMenu;

@property Service * selectedService;
@property Service * previouslySelectedService;

@property NSRect notesButtonInitialRect;
@property NSAnimation * notesUpAnimation;
@property NSAnimation * notesDownAnimation;
@end

@implementation AMCServicesViewController

-(NSString *)nibName {
    return @"AMCServicesViewController";
}
-(void)viewDidLoad {
    self.servicesArrayController.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"Name" ascending:YES]];
    [self.servicesArrayController rearrangeObjects];
    self.servicesTable.doubleAction = @selector(showDetailsForSelectedService:);
}
-(void)prepareForDisplayWithSalon:(AMCSalonDocument *)salonDocument {
    [super prepareForDisplayWithSalon:salonDocument];
    self.servicesArrayController.managedObjectContext = self.documentMoc;
}

#pragma mark - Action: Other Actions
- (IBAction)showActionMenu:(id)sender {
    [self.actionButton.menu popUpMenuPositioningItem:nil atLocation:NSMakePoint(0, NSMaxY(self.actionButton.bounds)) inView:self.actionButton];
}
#pragma mark - Action: Add Service
- (IBAction)addService:(id)sender {
    self.previouslySelectedService = self.selectedService;
    Service * service = [Service newObjectWithMoc:self.documentMoc];
    [self showServiceEditorForService:service editMode:EditModeCreate];
}
#pragma mark - Action: View Service Details
- (IBAction)rightClickViewDetails:(id)sender {
    [self showDetailsForService:[self serviceForRightClick]];
}
- (IBAction)showDetailsForSelectedService:(id)sender {
    [self showDetailsForService:self.selectedService];
}
-(void)showDetailsForService:(Service*)service {
    [self showServiceEditorForService:service editMode:EditModeView];
}
-(void)showServiceEditorForService:(Service*)service editMode:(EditMode)editMode {
    NSRect rect = [self rectForService:service column:0];
    self.editServiceViewController.delegate = self;
    self.editServiceViewController.objectToEdit = service;
    self.editServiceViewController.editMode = editMode;
    [self.editServiceViewController prepareForDisplayWithSalon:self.salonDocument];
    [self presentViewController:self.editServiceViewController asPopoverRelativeToRect:rect ofView:self.servicesTable preferredEdge:NSMaxYEdge behavior:NSPopoverBehaviorTransient];
}

#pragma mark - Action: Show notes popover
- (IBAction)rightClickShowNotes:(id)sender {
    [self showNotesForService:[self serviceForRightClick]];
}
- (IBAction)showNotesForSelectedService:(id)sender {
    [self showNotesForService:self.selectedService];
}
-(void)showNotesForService:(Service*)service {
    NSRect rect = [self rectForService:service column:0];
    self.notesViewController.objectWithNotes = service;
    [self.notesViewController prepareForDisplayWithSalon:self.salonDocument];
    [self presentViewController:self.notesViewController asPopoverRelativeToRect:rect ofView:self.servicesTable preferredEdge:NSMaxYEdge behavior:NSPopoverBehaviorTransient];
}
#pragma mark - NSTableViewDelegate
-(void)tableViewSelectionDidChange:(NSNotification *)notification {
    NSInteger row = self.servicesTable.selectedRow;
    self.selectedService = self.servicesArrayController.arrangedObjects[row];
}
#pragma mark - NSMenuDelegate
-(void)menuNeedsUpdate:(NSMenu *)menu {
    Service * service = nil;
    if (menu == self.actionMenu) {
        service = self.selectedService;
    } else {
        service = [self serviceForRightClick];
    }
    for (NSMenuItem * item in menu.itemArray) {
        item.enabled = (service != nil);
    }
}
#pragma mark - EditViewControllerDelegate
-(void)editObjectViewController:(EditObjectViewController *)controller didCancelCreationOfObject:(id)object {
    [self.servicesArrayController removeObject:object];
    [self selectService:self.previouslySelectedService];
}
-(void)editObjectViewController:(EditObjectViewController *)controller didCompleteCreationOfObject:(id)object {
    [self.servicesTable reloadData];
    [self selectService:object];
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
-(Service*)serviceForRightClick {
    NSInteger row = self.servicesTable.clickedRow;
    Service * service = self.servicesArrayController.arrangedObjects[row];
    [self selectService:service];
    return service;
}
-(void)selectService:(Service*)service {
    if (!service) {
        [self.servicesTable deselectAll:self];
        return;
    }
    NSInteger row = [self.servicesArrayController.arrangedObjects indexOfObject:service];
    [self.view.window makeFirstResponder:self.servicesTable];
    [self.servicesTable selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    self.selectedService = service;
    [self.servicesTable scrollRowToVisible:row];
    [self animateNotesButton:self.notesButton ifNecessaryForObject:service];
}
-(NSRect)rectForService:(Service*)service column:(NSInteger)column {
    NSInteger row = [self.servicesArrayController.arrangedObjects indexOfObject:service];
    NSRect columnRect = [self.servicesTable rectOfColumn:column];
    NSRect rowRect = [self.servicesTable rectOfRow:row];
    return NSIntersectionRect(rowRect, columnRect);
}
@end
