//
//  AMCSalesViewController.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 27/05/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "AMCSalesViewController.h"
#import "Sale.h"
#import "Appointment.h"
#import "Customer.h"
#import "AMCSalonDocument.h"
#import "Account.h"
#import "AMCCancelAppointmentViewController.h"
#import "AMCCompleteAppointmentViewController.h"
#import "AMCReceiptWindowController.h"
#import "EditObjectViewController.h"
#import "EditObjectViewControllerDelegate.h"
#import "AMCQuickQuoteViewController.h"
#import "AMCAssociatedNotesViewController.h"
#import "AMCAppointmentViewer.h"

@interface AMCSalesViewController () <NSTableViewDelegate, NSControlTextEditingDelegate, NSAnimationDelegate, EditObjectViewControllerDelegate, AMCQuickQuoteViewControllerDelegate>
{
    Sale * _selectedSale;
}
@property (strong) IBOutlet NSArrayController *saleArrayController;
@property (strong) IBOutlet AMCCancelAppointmentViewController *cancelSaleViewController;
@property (weak) IBOutlet NSTableView *salesTable;
@property (weak) IBOutlet EditObjectViewController * editSaleViewController;
@property (weak) IBOutlet AMCReceiptWindowController * receiptWindowController;
@property (weak) IBOutlet AMCQuickQuoteViewController * quickQuoteViewController;
@property (weak) IBOutlet EditObjectViewController * editCustomerViewController;
@property (strong) IBOutlet AMCAssociatedNotesViewController *notesViewController;
@property (strong) IBOutlet AMCAppointmentViewer *appointmentViewer;

@property (weak) IBOutlet NSButton *actionButton;
@property (weak) IBOutlet NSButton *quickQuoteButton;
@property (weak) IBOutlet NSButton *notesButton;
@property (weak) IBOutlet NSTextField *totalLabel;
@property (weak) IBOutlet NSButton *viewSaleButton;
@property (strong) IBOutlet NSMenu *rightClickMenu;
@property (strong) IBOutlet NSMenu *actionMenu;

@property Sale * sale;
@property Sale * previouslySelectedSale;
@property Sale * selectedSale;
@property NSRect notesButtonInitialRect;
@property NSViewAnimation * notesUpAnimation;
@property NSViewAnimation * notesDownAnimation;

@property (weak) IBOutlet NSMenuItem *editSaleActionMenuItem;
@property (weak) IBOutlet NSMenuItem *editSaleRightClickMenuItem;
@property (weak) IBOutlet NSMenuItem *voidSaleActionMenuItem;
@property (weak) IBOutlet NSMenuItem *voidSaleRightClickMenuItem;

@end

@implementation AMCSalesViewController
-(NSString *)nibName {
    return @"AMCSalesViewController";
}
-(void)prepareForDisplayWithSalon:(AMCSalonDocument *)salonDocument {
    [super prepareForDisplayWithSalon:salonDocument];
    [self.salesTable setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"createdDate" ascending:NO]]];
    self.salesTable.doubleAction = @selector(viewSelectedSale:);
}
#pragma mark - "PermissionDenied" Delegate
-(BOOL)permissionDeniedNeedsOKButton {
    return NO;
}
#pragma mark - Action: Other actions
- (IBAction)showActionMenu:(id)sender {
    //[self menuNeedsUpdate:self.actionMenu];
    [self.actionButton.menu popUpMenuPositioningItem:nil atLocation:NSMakePoint(NSMaxX(self.actionButton.bounds), 0) inView:self.actionButton];
}

-(void)tableDoubleClick:(id)sender {
    if (sender == self.salesTable) {
        NSInteger clickedRow = self.salesTable.clickedRow;
        if (clickedRow>=0) {
            [self.salesTable selectRowIndexes:[NSIndexSet indexSetWithIndex:clickedRow] byExtendingSelection:NO];
            [self viewSelectedSale:self];
        }
    }
}
#pragma mark - Action: New sale

- (IBAction)newSale:(id)sender {
    self.previouslySelectedSale = [self selectedSale];
    Sale * sale = [self newSale];
    [self editObject:sale inMode:EditModeCreate withViewController:self.editSaleViewController];
}
#pragma mark - Action: View sale
- (IBAction)rightClickViewSale:(id)sender {
    [self viewSale:[self saleFromRightClick]];
}
- (IBAction)viewSelectedSale:(id)sender {
    [self viewSale:self.selectedSale];
}
-(void)viewSale:(Sale*)sale {
    if (!sale) return;
    if (sale.isQuote.boolValue) {
        [self editObject:sale inMode:EditModeEdit withViewController:self.editSaleViewController];
    } else {
        [self presentAppointmentViewerOnTab:AMCAppointmentViewSale withSale:sale];
    }
}
#pragma mark - Action: Void sale
- (IBAction)rightClickVoidSale:(id)sender {
    [self voidSale:[self saleFromRightClick]];
}
- (IBAction)voidSelectedSale:(id)sender {
    [self voidSale:self.selectedSale];
}
-(void)voidSale:(Sale*)sale {
    if (!sale) return;
    if (sale.fromAppointment) {
        [self voidSaleGeneratedFromAppointment:sale];
    } else {
        [self voidStandaloneSale:sale];
    }
}
#pragma mark - Action: Show notes popover
-(IBAction)rightClickShowCustomerNotes:(id)sender {
    [self showCustomerNotesForSale:[self saleFromRightClick]];
}
- (IBAction)showSelectedCustomerNotes:(id)sender {
    [self showCustomerNotesForSale:self.selectedSale];
}
-(void)showCustomerNotesForSale:(Sale*)sale {
    NSRect customerRect = [self rectForSale:sale column:3];
    self.notesViewController.objectWithNotes = sale.customer;
    [self.notesViewController prepareForDisplayWithSalon:self.salonDocument];
    [self presentViewController:self.notesViewController asPopoverRelativeToRect:customerRect ofView:self.salesTable preferredEdge:NSMaxYEdge behavior:NSPopoverBehaviorTransient];
}
-(NSRect)rectForSale:(Sale*)sale column:(NSInteger)column {
    NSInteger row = [self.saleArrayController.arrangedObjects indexOfObject:sale];
    [self.salesTable scrollRowToVisible:row];
    NSRect columnRect = [self.salesTable rectOfColumn:column];
    NSRect rowRect = [self.salesTable rectOfRow:row];
    return NSIntersectionRect(rowRect, columnRect);
}
#pragma mark - Action: Show price details
- (IBAction)rightClickShowPriceDetails:(id)sender {
    [self showPriceDetailsForSale:[self saleFromRightClick]];
}
- (IBAction)showSelectedPriceDetails:(id)sender {
    [self showPriceDetailsForSale:self.selectedSale];
}
-(void)showPriceDetailsForSale:(Sale*)sale {
    NSRect amountRect = [self rectForSale:sale column:5];
    self.quickQuoteViewController.delegate = self;
    self.quickQuoteViewController.sale = [self selectedSale];
    [self.quickQuoteViewController prepareForDisplayWithSalon:self.salonDocument];
    
    [self presentViewController:self.quickQuoteViewController asPopoverRelativeToRect:amountRect ofView:self.salesTable preferredEdge:NSMinYEdge behavior:NSPopoverBehaviorSemitransient];
}
#pragma mark - Action: Show customer details
- (IBAction)rightClickShowCustomerDetails:(id)sender {
    [self showCustomerDetailsForSale:[self saleFromRightClick]];
}
- (IBAction)showSelectedCustomerDetails:(id)sender {
    [self showCustomerDetailsForSale:self.selectedSale];
}
-(void)showCustomerDetailsForSale:(Sale*)sale {
    if (!sale) return;
    [self editObject:sale.customer inMode:EditModeView withViewController:self.editCustomerViewController];
}
#pragma mark - Action: Show sale receipt
- (IBAction)rightClickViewSaleReceipt:(id)sender {
    [self viewReceiptForSale:[self saleFromRightClick]];
}
- (IBAction)viewSelectedSaleReceipt:(id)sender {
    [self viewReceiptForSale:self.selectedSale];
}
-(void)viewReceiptForSale:(Sale*)sale {
    if (!sale) return;
    self.receiptWindowController.sale = sale;
    NSWindow * sheet = [self.receiptWindowController window];
    NSWindow * window = self.view.window;
    [window beginSheet:sheet completionHandler:^(NSModalResponse returnCode) {
    
    }];
}
#pragma mark - Edit object detail methods
-(void)presentAppointmentViewerOnTab:(AMCAppointmentViews)tab
                         withSale:(Sale*)sale {
    self.appointmentViewer.sale = sale;
    self.appointmentViewer.customer = sale.customer;
    self.appointmentViewer.appointment = sale.fromAppointment;
    self.appointmentViewer.selectedView = tab;
    [self.appointmentViewer prepareForDisplayWithSalon:self.salonDocument];
    [self presentViewControllerAsSheet:self.appointmentViewer];
}
-(Sale*)selectedSale
{
    return _selectedSale;
}
-(void)setSelectedSale:(Sale *)sale {
    if (sale != _selectedSale) {
        NSArray * array = self.saleArrayController.arrangedObjects;
        NSUInteger index = [array indexOfObject:sale];
        if (index == NSNotFound || array.count == 0) {
            _selectedSale = nil;
            [self.salesTable deselectAll:self];
        } else {
            _selectedSale = array[index];
            [self.salesTable selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
        }
    }
    [self configureForSelectedSale];
}
-(void)saleEditOperationComplete {
    [self.saleArrayController rearrangeObjects];
    [self.salesTable reloadData];
    self.selectedSale = self.previouslySelectedSale;
    [self configureForSelectedSale];
}
-(void)editObject:(id)object inMode:(EditMode)editMode withViewController:(EditObjectViewController*)viewController
{
    NSAssert(object, @"No object to edit");
    if (object) {
        viewController.delegate = self;
        viewController.editMode = editMode;
        [viewController clear];
        viewController.objectToEdit = object;
        [viewController prepareForDisplayWithSalon:self.salonDocument];
        [self presentViewControllerAsSheet:viewController];
    }
}
#pragma mark - editObjectViewControllerDelegate
-(void)editObjectViewController:(EditObjectViewController *)controller didCancelCreationOfObject:(id)object {
    [self.documentMoc deleteObject:object];
    [self.saleArrayController removeObject:object];
    if (controller == self.editSaleViewController) {
        [self saleEditOperationComplete];
    }
}
-(void)editObjectViewController:(EditObjectViewController *)controller didCompleteCreationOfObject:(id)object {
    if (controller == self.editSaleViewController) {
        self.previouslySelectedSale = object;
        [self saleEditOperationComplete];
    }
}
-(void)editObjectViewController:(EditObjectViewController *)controller didEditObject:(id)object {
    if (controller == self.editSaleViewController) {
        self.previouslySelectedSale = object;
        [self saleEditOperationComplete];
    }
}

#pragma mark - AMCQuickQuoteViewController delegate

-(void)quickQuoteViewControllerDidFinish:(AMCQuickQuoteViewController *)quickQuoteViewController {
    [self configureForSelectedSale];
}
#pragma mark - NSMenuDelegate
-(void)menuNeedsUpdate:(NSMenu *)menu {
    Sale * sale = nil;
    if (menu == self.rightClickMenu) {
        menu.autoenablesItems = NO;
        for (NSMenuItem * item in menu.itemArray) {
            NSInteger clickedRow = self.salesTable.clickedRow;
            if (clickedRow >=0 ) {
                item.enabled = YES;
                sale = self.saleArrayController.arrangedObjects[clickedRow];
            } else {
                item.enabled = NO;
            }
        }
    } else if (menu == self.actionMenu) {
        sale = self.selectedSale;
    }
    
    if (sale) {
        if (sale.isQuote.boolValue) {
            self.editSaleRightClickMenuItem.title = @"Convert this Quote to Sale...";
            self.voidSaleRightClickMenuItem.title = @"Void this Quote...";
        } else {
            self.editSaleRightClickMenuItem.title = @"View this Sale...";
            self.voidSaleRightClickMenuItem.title = @"Void this Sale...";
        }
        self.editSaleActionMenuItem.title = self.editSaleRightClickMenuItem.title;
        self.voidSaleActionMenuItem.title = self.voidSaleRightClickMenuItem.title;
    }
}
#pragma mark - NSTableViewDelegate
-(void)tableViewSelectionDidChange:(NSNotification *)notification
{
    NSInteger row = self.salesTable.selectedRow;
    Sale * saleToSelect = nil;
    if (row >= 0) {
        saleToSelect = self.saleArrayController.arrangedObjects[row];
    }
    self.selectedSale = saleToSelect;
}
-(BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    return NO;
}
-(void)configureForSelectedSale
{
    Sale * sale = [self selectedSale];
    if (sale) {
        self.totalLabel.stringValue = [NSString stringWithFormat:@"Total = £%1.2f",sale.actualCharge.doubleValue];
    } else {
        self.totalLabel.stringValue = @"";
    }
    if (sale.isQuote.boolValue) {
        self.viewSaleButton.title = @"Quote to Sale";
    } else {
        self.viewSaleButton.title = @"View sale";
    }
    [self animateNotesButton:self.notesButton ifNecessaryForObject:[self selectedSale].customer];
}
-(void)voidStandaloneSale:(Sale*)sale {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"Void this Sale?"];
    [alert setInformativeText:@"Once voided, this Sale will no longer be visible on the Sales tab and will not appear in reports or Sales totals.\n\nPlease note that you can't undo this action."];
    [alert addButtonWithTitle:@"Void the Sale"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert beginSheetModalForWindow:[NSApp mainWindow] completionHandler:^(NSModalResponse response) {
        if (response == NSAlertFirstButtonReturn) {
            sale.voided = @(YES);
            [self.salesTable reloadData];
        }
    }];
}
-(void)voidSaleGeneratedFromAppointment:(Sale*)sale {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"Void this Sale?"];
    [alert setInformativeText:@"This sale was generated from an Appointment that is currently marked as complete. \n\nWhat would you like to do?\n\nVoid the sale and re-open the appointment\n\nVoid the sale and leave the appointment as it is\n"];
    [alert addButtonWithTitle:@"Re-open Appointment"];
    [alert addButtonWithTitle:@"Just void the Sale"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert beginSheetModalForWindow:[NSApp mainWindow] completionHandler:^(NSModalResponse response) {
        if (response == NSAlertFirstButtonReturn) {
            sale.hidden = @(YES);
            sale.isQuote = @(YES);
            sale.amountGivenByCustomer = @(0);
            sale.changeGiven = @(0);
            sale.fromAppointment.completed = @(NO);
            sale.fromAppointment.completionNote = @"";
            sale.fromAppointment.completionType = AMCompletionTypeNotCompleted;
            [self.salesTable reloadData];
        }
        if (response == NSAlertSecondButtonReturn) {
            sale.voided = @(YES);
            [self.salesTable reloadData];
        }
    }];
}

#pragma mark - Notes button bounce animation
-(Sale*)saleFromRightClick {
    NSInteger clickedRow = self.salesTable.clickedRow;
    [self.salesTable selectRowIndexes:[NSIndexSet indexSetWithIndex:clickedRow] byExtendingSelection:NO];
    [self.view.window makeFirstResponder:self.salesTable];
    Sale * sale = self.saleArrayController.arrangedObjects[clickedRow];
    return sale;
}
-(Sale*)newSale
{
    Sale * sale = [Sale newObjectWithMoc:self.documentMoc];
    sale.isQuote = @YES;
    [self.saleArrayController addObject:sale];
    [self.saleArrayController rearrangeObjects];
    self.selectedSale = sale;
    return sale;
}
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



@end
