//
//  AMCAppointmentsViewController.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 23/08/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "AMCAppointmentsViewController.h"
#import "Appointment+Methods.h"
#import "NSDate+AMCDate.h"
#import "Service+Methods.h"
#import "Customer+Methods.h"
#import "Employee+Methods.h"
#import "AMCWizardForNewAppointmentWindowController.h"
#import "EditObjectViewController.h"
#import "AMCAssociatedNotesViewController.h"
#import "AMCCancelAppointmentViewController.h"
#import "AMCCompleteAppointmentViewController.h"
#import "AMCAppointmentCompletionBoilerPlate.h"
#import "Sale+Methods.h"
#import "SaleItem+Methods.h"
#import "AMCQuickQuoteViewController.h"
#import "AMCSalonDocument.h"
#import "Payment+Methods.h"
#import "AMCAppointmentViewer.h"

typedef NS_ENUM(NSInteger, AMCPeriod) {
    AMCperiodNone = -1,
    AMCPeriodAll = 0,
    AMCPeriodToday = 1,
    AMCPeriodTomorrow = 2,
    AMCPeriodNextSevenDays = 3,
    AMCPeriodNextThirtyDays = 4,
    AMCPeriodYesterday = 5,
    AMCPeriodPreviousSevenDays = 6,
    AMCPeriodPreviousThirtyDays = 7,
};

@interface AMCAppointmentsViewController ()
<
NSMenuDelegate,
NSTableViewDataSource,
NSTableViewDelegate,
NSPopoverDelegate,
AMCAppointmentsViewDelegate,
NSAnimationDelegate>
{
    NSArray * _appointments;
    NSArray * _saleItems;
    NSArray * _searchFilteredAppointments;
    AMCCancelAppointmentViewController * _cancelAppointmentViewController;
    AMCCompleteAppointmentViewController * _completeAppointmentViewController;
    AMCQuickQuoteViewController * _quickQuoteViewController;
    AMCAssociatedNotesViewController * _associatedNotesViewController;
}
@property NSArray * appointments;
@property (readonly) NSArray * searchFilteredAppointments;
@property (readonly) NSArray * saleItems;
@property (strong) AMCWizardWindowController * currentWizard;
@property (readonly) Appointment * selectedAppointment;
@property (readonly) SaleItem * selectedSaleItem;
@property NSViewAnimation * notesUpAnimation;
@property NSViewAnimation * notesDownAnimation;
@property NSRect notesButtonInitialRect;
@property (readonly) AMCCancelAppointmentViewController * cancelAppointmentViewController;
@property (readonly) AMCCompleteAppointmentViewController * completeAppointmentViewController;
@property (readonly) AMCQuickQuoteViewController * quickQuoteViewController;
@property (readonly) AMCAssociatedNotesViewController * associatedNotesViewController;

@property (strong) IBOutlet AMCAppointmentViewer *appointmentViewer;

@property Appointment * previouslySelectedAppointment;
@property (weak) IBOutlet NSButton *actionButton;

@property (strong) IBOutlet NSMenu *rightClickMenu;

@property (weak) IBOutlet NSMenuItem *rightClickEditMenuItem;
@property (weak) IBOutlet NSMenuItem *rightClickCompleteMenuItem;
@property (weak) IBOutlet NSMenuItem *rightClickCancelMenuItem;
@property (weak) IBOutlet NSMenuItem *rightClickViewCustomerMenuItem;
@property (weak) IBOutlet NSMenuItem *rightClickViewCustomerNotesMenuItem;
@property (weak) IBOutlet NSMenuItem *rightClickViewPriceDetailsMenuItem;


@property (strong) IBOutlet NSMenu *actionMenu;
@property (weak) IBOutlet NSMenuItem *actionAddMenuItem;
@property (weak) IBOutlet NSMenuItem *actionEditMenuItem;
@property (weak) IBOutlet NSMenuItem *actionCompleteMenuItem;
@property (weak) IBOutlet NSMenuItem *actionCancelMenuItem;
@property (weak) IBOutlet NSMenuItem *actionViewCustomerMenuItem;
@property (weak) IBOutlet NSMenuItem *actionViewCustomerNotesMenuItem;
@property (weak) IBOutlet NSMenuItem *actionViewPriceDetailsMenuItem;

@end

@implementation AMCAppointmentsViewController

-(NSString *)nibName
{
    return @"AMCAppointmentsViewController";
}
-(void)awakeFromNib {
    self.appointmentsTable.target = self;
    [self.appointmentsTable setDoubleAction:@selector(tableDoubleClick:)];
}
#pragma mark - "PermissionDenied" Delegate
-(BOOL)permissionDeniedNeedsOKButton {
    return NO;
}
#pragma mark - AMCAppointmentsViewDelegate
-(void)appointmentsViewDidAwakeFromNib:(AMCAppointmentsView *)appointmentsView
{
    [self buildIntervalSegmentedControl:appointmentsView.intervalPickerSegmentedControl];
    [self reloadData];
}

#pragma mark - NSTableViewDataSource
-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    if (tableView == self.appointmentsTable) {
        return self.searchFilteredAppointments.count;
    } else {
        return self.saleItems.count;
    }
}
-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if (tableView == self.appointmentsTable) {
        if (!self.searchFilteredAppointments || self.searchFilteredAppointments.count == 0) return nil;
        
        Appointment * appointment = self.searchFilteredAppointments[row];
        if ([tableColumn.identifier isEqualToString:@"appointmentDate"]) {
            return appointment.appointmentDate;
        }
        if ([tableColumn.identifier isEqualToString:@"appointmentTime"]) {
            return appointment.appointmentDate;
        }
        if ([tableColumn.identifier isEqualToString:@"customerFirstName"]) {
            return appointment.customer.firstName;
        }
        if ([tableColumn.identifier isEqualToString:@"customerBirthday"]) {
            return appointment.customer.birthday;
        }
        if ([tableColumn.identifier isEqualToString:@"customerLastName"]) {
            return appointment.customer.lastName;
        }
        if ([tableColumn.identifier isEqualToString:@"customerPhone"]) {
            return appointment.customer.phone;
        }
        if ([tableColumn.identifier isEqualToString:@"bookedDurationInMinutes"]) {
            NSInteger time = appointment.bookedDurationInMinutes;
            if (time == 0) {
                return @"unknown";
            } else {
                return[self stringDescribingTimeSpecifiedInMinutes:time];
            }
        }
        if ([tableColumn.identifier isEqualToString:@"amount"]) {
            return appointment.sale.actualCharge;
        }
        if ([tableColumn.identifier isEqualToString:@"advance"]) {
            return appointment.sale.advancePayment.amount;
        }
        if ([tableColumn.identifier isEqualToString:@"status"]) {
            if (appointment.cancelled.boolValue) {
                NSString * cancelled = @"Cancelled - ";
                NSString * cancelledExplanation = @"";
                AMCancellationType cancelType = appointment.cancellationType.integerValue;
                if (appointment.cancellationNote && appointment.cancellationNote.length > 0) {
                    cancelledExplanation = [cancelledExplanation stringByAppendingString:appointment.cancellationNote];
                } else {
                    cancelledExplanation = [cancelledExplanation stringByAppendingString:[AMCAppointmentCompletionBoilerPlate boilerPlateExplanationForCancellationType:cancelType]];
                }
                cancelled = [cancelled stringByAppendingString:cancelledExplanation];
                return cancelled;
            }
            if (appointment.completed.boolValue) {
                NSString * completed = @"Completed - ";
                NSString * completedExplanation = @"";
                AMCompletionType completionType = appointment.completionType.integerValue;
                if (appointment.completionNote && appointment.completionNote.length > 0) {
                    completedExplanation = [completedExplanation stringByAppendingString:appointment.completionNote];
                } else {
                    completedExplanation = [AMCAppointmentCompletionBoilerPlate boilerPlateExplanationForCompletionType:completionType];
                }
                completed = [completed stringByAppendingString:completedExplanation];
                return completed;
            }
            if ([appointment.appointmentDate isGreaterThan:[NSDate date]]) {
                return @"Booked";
            } else {
                if ([appointment.appointmentEndDate isGreaterThan:[NSDate date]]) {
                    return @"Booked - customer due now";
                } else {
                    return @"Customer No-Show";
                }
            }
        }
    } else {
        SaleItem * saleItem = self.saleItems[row];
        if ([tableColumn.identifier isEqualToString:@"serviceName"]) {
            return saleItem.service.name;
        }
        if ([tableColumn.identifier isEqualToString:@"serviceExpectedTimeRequired"]) {
            NSInteger time = saleItem.service.expectedTimeRequired.integerValue;
            if (time == 0) {
                return @"unknown";
            } else {
                return [self stringDescribingTimeSpecifiedInMinutes:time];
            }
        }
        if ([tableColumn.identifier isEqualToString:@"employeeFullName"]) {
            return saleItem.performedBy.fullName;
        }
        
    }
    return nil;
}
#pragma mark - NSMenuDelegate
-(void)menuNeedsUpdate:(NSMenu *)menu {
    Appointment * appointment = nil;
    menu.autoenablesItems = NO;
    self.actionEditMenuItem.enabled = YES;
    self.rightClickEditMenuItem.enabled = YES;
    if (menu == self.rightClickMenu) {
        appointment = [self appointmentForRightClick];
        for (NSMenuItem * item in menu.itemArray) {
            item.enabled = (self.appointmentsTable.clickedRow>=0)?YES:NO;
        }
    } else if (menu == self.actionMenu) {
        appointment = self.selectedAppointment;
        for (NSMenuItem * item in menu.itemArray) {
            item.enabled = (appointment!=nil);
        }
        self.actionAddMenuItem.enabled = YES;
    }
    if (appointment) {
        if (appointment.cancelled.boolValue) {
            self.actionCompleteMenuItem.enabled = NO;
            self.rightClickCompleteMenuItem.enabled = NO;
            self.actionCancelMenuItem.title = @"Reinstate Appointment";
            self.rightClickEditMenuItem.title = @"View Appointment";
            self.actionEditMenuItem.title = @"Edit Appointment";
        } else {
            self.actionCompleteMenuItem.enabled = !appointment.completed.boolValue;
            self.rightClickCompleteMenuItem.enabled = !appointment.completed.boolValue;
            self.actionCancelMenuItem.title = @"Cancel Appointment";
            self.actionCancelMenuItem.enabled = !appointment.completed.boolValue;
            self.rightClickCancelMenuItem.enabled = !appointment.completed.boolValue;
            if (appointment.completed.boolValue) {
                self.rightClickEditMenuItem.title = @"View Appointment";
                self.actionEditMenuItem.title = @"View Appointment";
            } else {
                self.rightClickEditMenuItem.title = @"Edit Appointment";
                self.actionEditMenuItem.title = @"Edit Appointment";
            }
        }
        self.rightClickCancelMenuItem.title = self.actionCancelMenuItem.title;
    }
}
#pragma mark - NSTableViewDelegate
-(BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    return NO;
}
-(void)tableViewSelectionIsChanging:(NSNotification *)notification {
    NSTableView * tableView = notification.object;
    if (tableView == self.appointmentsTable) {
        [self.saleItemsTable deselectAll:self];
        _saleItems = @[];
        [self.saleItemsTable reloadData];
    }
    if (tableView == self.saleItemsTable) {
    }
}
-(void)tableViewSelectionDidChange:(NSNotification *)notification
{
    NSTableView * tableView = notification.object;
    if (tableView == self.appointmentsTable) {
        [self appointmentSelectionChanged];
    }
    if (tableView == self.saleItemsTable) {
    }
}
#pragma mark - Helpers
-(void)presentAppointmentViewerOnTab:(AMCAppointmentViews)tab
                            withAppointment:(Appointment*)appointment {
    self.appointmentViewer.appointment = appointment;
    self.appointmentViewer.sale = appointment.sale;
    self.appointmentViewer.customer = appointment.customer;
    self.appointmentViewer.selectedView = tab;
    [self.appointmentViewer prepareForDisplayWithSalon:self.salonDocument];
    [self presentViewControllerAsSheet:self.appointmentViewer];
}
-(NSString*)stringDescribingTimeSpecifiedInMinutes:(NSInteger)time {
    if (time < 60) {
        return [NSString stringWithFormat:@"%li minutes",(long)time];
    }
    long hours = time / 60;
    long minutes = fmod(time, 60);
    return [NSString stringWithFormat:@"%li hours %li minutes",hours,minutes];
}
-(void)appointmentSelectionChanged
{
    [self configureButtons];
    [self.saleItemsTable deselectAll:self];
    [self.saleItemsTable reloadData];
    [self saleItemSelectionChanged];
    [self animateNotesIconIfNecessary];
}
-(void)animateNotesIconIfNecessary {
    Appointment * appointment = [self selectedAppointment];
    Customer * customer = appointment.customer;
    if (customer && customer.nonAuditNotes.count > 0) {
        [self animateNotesIcon];
    }
}
-(void)animateNotesIcon {
    if (!self.notesUpAnimation) {
        NSView * notesView = self.showNotesButton;
        NSRect notesViewFrame;
        self.notesButtonInitialRect = notesView.frame;
        NSRect newViewFrame;
        NSMutableDictionary* notesViewDict;
        
        // Create the attributes dictionary for the notes view
        notesViewDict = [NSMutableDictionary dictionaryWithCapacity:3];
        notesViewFrame = [notesView frame];
        
        // Specify which view to modify.
        [notesViewDict setObject:notesView forKey:NSViewAnimationTargetKey];
        
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
        [theAnim setDuration:0.5];    // One and a half seconds.
        [theAnim setAnimationCurve:NSAnimationEaseInOut];
        [theAnim setAnimationBlockingMode:NSAnimationNonblocking];
        [theAnim setDelegate:self];
        self.notesDownAnimation = theAnim;
    }
    
    // Run the animation.
    [self.notesUpAnimation startAnimation];
}
-(void)animation:(NSAnimation *)animation didReachProgressMark:(NSAnimationProgress)progress {
    if (progress == 1 && animation == self.notesUpAnimation) {
        [self.notesDownAnimation startAnimation];
    }
}
-(void)configureButtons {
    Appointment * appointment = [self selectedAppointment];
    BOOL appointmentSelected = (appointment!=nil)?YES:NO;
    [self.editAppointmentButton setEnabled:appointmentSelected];
    [self.showNotesButton setEnabled:appointmentSelected];
    [self.completeAppointmentButton setEnabled:appointmentSelected];
    [self.showQuickQuoteButton setEnabled:appointmentSelected];
    if (appointmentSelected) {
        self.totalLabel.stringValue = [NSString stringWithFormat:@"Total: £%1.2f",appointment.sale.actualCharge.doubleValue];
        if (appointment.cancelled.boolValue) {
            // appointment is currently cancelled
            [self.completeAppointmentButton setEnabled:NO];
            self.editAppointmentButton.title = @"View Appointment";
        } else {

        }
        if (appointment.completed.boolValue) {
            // appointment is currently completed
            self.editAppointmentButton.title = @"View Appointment";
            [self.completeAppointmentButton setEnabled:NO];
        }
        if (!appointment.completed.boolValue && !appointment.cancelled.boolValue) {
            [self.completeAppointmentButton setEnabled:YES];
            self.editAppointmentButton.title = @"Edit Appointment";
            //[self.editAppointmentButton setEnabled:YES];
        }
    } else {
        self.totalLabel.stringValue = @"";
    }
}
-(void)saleItemSelectionChanged {

}
-(Appointment*)selectedAppointment
{
    if (self.appointmentsTable.selectedRow <0) return nil;
    return self.searchFilteredAppointments[self.appointmentsTable.selectedRow];
}
-(SaleItem*)selectedSaleItem
{
    if (self.saleItemsTable.selectedRow <0) return nil;
    return self.saleItems[self.saleItemsTable.selectedRow];
}
-(void)selectAppointment:(Appointment*)appointment {
    if (appointment) {
        NSInteger row = [self.appointments indexOfObject:appointment];
        if (row != NSNotFound) {
            [self.appointmentsTable selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
        }
    }
}
-(void)reloadData
{
    _appointments = nil;
    _saleItems = nil;
    _searchFilteredAppointments = nil;
    [self.appointmentsTable reloadData];
    [self.saleItemsTable reloadData];
    [self appointmentSelectionChanged];
    [self saleItemSelectionChanged];
}
-(void)buildIntervalSegmentedControl:(NSSegmentedControl*)segmented
{
    segmented.segmentCount = 8;
    [segmented setLabel:@"All" forSegment:0];
    [segmented setLabel:@"Today" forSegment:1];
    [segmented setLabel:@"Tomorrow" forSegment:2];
    [segmented setLabel:@"Next 7 days" forSegment:3];
    [segmented setLabel:@"Next 30 days" forSegment:4];
    [segmented setLabel:@"Yesterday" forSegment:5];
    [segmented setLabel:@"Last 7 days" forSegment:6];
    [segmented setLabel:@"Last 30 days" forSegment:7];
    [segmented setSelectedSegment:0];
    [segmented setSelectedSegment:AMCPeriodToday];
}
-(void)setAppointments:(NSArray *)appointments
{
    _appointments = appointments;
}
-(NSArray*)saleItems {
    if (!self.selectedAppointment) return @[];
    NSArray * array = self.selectedAppointment.sale.saleItem.allObjects;
    NSSortDescriptor * sort = [NSSortDescriptor sortDescriptorWithKey:@"createdDate" ascending:YES];
    return [array sortedArrayUsingDescriptors:@[sort]];
}
-(NSArray*)appointments
{
    NSManagedObjectContext * moc = self.documentMoc;
    _searchFilteredAppointments = nil;
    AMCPeriod interval = self.intervalPickerSegmentedControl.selectedSegment;
    NSDate * intervalStart;
    NSDate * intervalEnd;
    NSDate * rightNow = [NSDate date];
    NSInteger secondsInDay = 24 * 3600;
    switch (interval) {
        case AMCperiodNone:
        {
            intervalStart = [NSDate distantPast];
            intervalEnd = [NSDate distantFuture];
            break;
        }
        case AMCPeriodAll:
        {
            intervalStart = [NSDate distantPast];
            intervalEnd = [NSDate distantFuture];
            break;
        }
        case AMCPeriodToday:
        {
            intervalStart = [rightNow beginningOfDay];
            intervalEnd = [rightNow endOfDay];
            break;
        }
        case AMCPeriodTomorrow:
        {
            intervalStart = [rightNow endOfDay];
            intervalEnd = [intervalStart dateByAddingTimeInterval:secondsInDay];
            break;
        }
        case AMCPeriodNextSevenDays:
        {
            intervalStart = rightNow;
            intervalEnd = [rightNow dateByAddingTimeInterval:8 * secondsInDay];
            intervalEnd = [intervalEnd beginningOfDay];
            break;
        }
        case AMCPeriodNextThirtyDays:
        {
            intervalStart = rightNow;
            intervalEnd = [rightNow dateByAddingTimeInterval:30 * secondsInDay];
            intervalEnd = [intervalEnd beginningOfDay];
            break;
        }
        case AMCPeriodYesterday:
        {
            intervalEnd = [rightNow beginningOfDay];
            intervalStart = [intervalEnd dateByAddingTimeInterval:-secondsInDay];
            break;
        }
        case AMCPeriodPreviousSevenDays:
        {
            intervalEnd = rightNow;
            intervalStart = [rightNow dateByAddingTimeInterval:-8*secondsInDay];
            intervalStart = [intervalStart endOfDay];
            break;
        }
        case AMCPeriodPreviousThirtyDays:
        {
            intervalEnd = rightNow;
            intervalStart = [rightNow dateByAddingTimeInterval:-30*secondsInDay];
            intervalStart = [intervalStart endOfDay];
            break;
        }
    }
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Appointment" inManagedObjectContext:moc];
    [fetchRequest setEntity:entity];
    // Specify criteria for filtering which objects to fetch
    NSPredicate *statePredicate;
    NSInteger appointmentState = self.appointmentStateSelectorButton.indexOfSelectedItem;
    switch (appointmentState) {
        case 0:
        {
            // Show open appointments (ie, not cancelled and not completed)
            statePredicate = [NSPredicate predicateWithFormat:@"appointmentDate >= %@ and appointmentDate <= %@ and cancelled == %@ and completed == %@", intervalStart, intervalEnd,@(NO),@(NO)];
            break;
        }
        case 1:
        {
            // Show completed appointments
            statePredicate = [NSPredicate predicateWithFormat:@"appointmentDate >= %@ and appointmentDate <= %@ and completed == %@", intervalStart, intervalEnd,@(YES)];
            break;
        }
        case 2:
        {
            // Show cancelled appointments
            statePredicate = [NSPredicate predicateWithFormat:@"appointmentDate >= %@ and appointmentDate <= %@ and cancelled == %@", intervalStart, intervalEnd,@(YES)];
            break;
        }
    }
    [fetchRequest setPredicate:statePredicate];
    // Specify how the fetched objects should be sorted
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"appointmentDate" ascending:NO];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];
    
    NSError *error = nil;
    return [moc executeFetchRequest:fetchRequest error:&error];
}
-(NSArray*)searchFilteredAppointments {
    if (!_searchFilteredAppointments) {
        NSString * searchText = self.searchField.stringValue;
        NSPredicate * searchPredicate = nil;
        if (searchText.length > 0) {
            searchPredicate = [NSPredicate predicateWithFormat:@"(customer.firstName beginswith[cd] %@ or customer.lastName beginswith[cd] %@ or customer.phone beginswith %@)",searchText, searchText,searchText];
            _searchFilteredAppointments = [self.appointments filteredArrayUsingPredicate:searchPredicate];
        } else {
            _searchFilteredAppointments = self.appointments;
        }
    }
    return _searchFilteredAppointments;
}
-(void)showBookingWizardInMode:(EditMode)editMode {
    [self.salonDocument saveDocument:self];
    self.currentWizard = [[AMCWizardForNewAppointmentWindowController alloc] init];
    self.currentWizard.editMode = editMode;
    if (editMode == EditModeCreate) {
        self.currentWizard.objectToManage = [Appointment newObjectWithMoc:self.documentMoc];
    } else {
        self.currentWizard.objectToManage = [self selectedAppointment];
    }
    self.currentWizard.document = self.salonDocument;
    NSWindow * window = self.view.window;
    [window beginSheet:self.currentWizard.window completionHandler:^(NSModalResponse returnCode) {
        NSLog(@"Closing!!");
        NSManagedObjectContext * moc = self.documentMoc;
        if (self.currentWizard.cancelled) {
            if (self.currentWizard.editMode == EditModeCreate) {
                Appointment * app = self.currentWizard.objectToManage;
                app.sale.voided = @(YES);
                [moc deleteObject:self.currentWizard.objectToManage];
            } else {
                [moc rollback];
            }
        } else {
            [self.salonDocument saveDocument:self];
            self.previouslySelectedAppointment = (Appointment*)self.currentWizard.objectToManage;
        }
        [self reloadData];
        [self selectAppointment:self.previouslySelectedAppointment];
        [self.view.window makeFirstResponder:self.appointmentsTable];
    }];
}
-(void)convertAppointmentToQuote:(Appointment*)appointment {
    Sale * sale = appointment.sale;
    NSAssert(sale, @"Sale must not be nil");
    NSAssert(sale.isQuote.boolValue == YES, @"Sale must be in quote state");
    sale.hidden = @(NO);
    sale.createdDate = [NSDate date];
    sale.lastUpdatedDate = [NSDate date];
    NSAlert * alert = [[NSAlert alloc] init];
    alert.messageText = @"Sale generated!";
    alert.informativeText = @"A new quote has been created on the Sales tab. You must edit the quote to finalize prices and complete the sale. You will need to switch to the Sales tab to do this.";
    [alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
        
    }];
}
-(NSRect)rectOfCellForRow:(NSUInteger)row column:(NSUInteger)col {
    NSRect rowBounds = [self.appointmentsTable rectOfRow:row];
    NSRect colBounds = [self.appointmentsTable rectOfColumn:col];
    return NSIntersectionRect(rowBounds, colBounds);
}
#pragma mark - Actions
-(IBAction)rightClickEditAction:(id)sender {
    [self editAppointment:[self appointmentForRightClick]];
}
- (IBAction)rightClickShowCustomerNotes:(id)sender {
    [self showCustomerNotesForAppointment:[self appointmentForRightClick]];
}
-(IBAction)rightClickCompleteAction:(id)sender {
    [self completeAppointment:[self appointmentForRightClick]];
}
-(IBAction)rightClickCancelAction:(id)sender {
    [self cancelAppointment:[self appointmentForRightClick]];
}
-(IBAction)rightClickViewCustomerAction:(id)sender {
    [self viewCustomerForAppointment:[self appointmentForRightClick]];
}
-(Appointment*)appointmentForRightClick {
    NSInteger rightClickRow = self.appointmentsTable.clickedRow;
    if (rightClickRow < 0) return nil;
    [self.appointmentsTable selectRowIndexes:[NSIndexSet indexSetWithIndex:self.appointmentsTable.clickedRow] byExtendingSelection:NO];
    [self.view.window makeFirstResponder:self.appointmentsTable];
    NSInteger clickedRow = self.appointmentsTable.clickedRow;
    Appointment * appointment = self.appointments[clickedRow];
    return appointment;
}

- (IBAction)showActionMenu:(id)sender {
    [self.actionButton.menu popUpMenuPositioningItem:nil atLocation:NSMakePoint(NSMaxX(self.actionButton.bounds), 0) inView:self.actionButton];
}

-(void)tableDoubleClick:(id)sender {
    if (sender == self.appointmentsTable) {
        NSInteger clickedRow = self.appointmentsTable.clickedRow;
        if (clickedRow>=0) {
            [self.appointmentsTable selectRowIndexes:[NSIndexSet indexSetWithIndex:clickedRow] byExtendingSelection:NO];
            [self viewSelectedCustomer:self];
        }
    }
}
- (IBAction)createNewAppointment:(id)sender {
    self.previouslySelectedAppointment = self.selectedAppointment;
    [self showBookingWizardInMode:EditModeCreate];
}
- (IBAction)editSelectedAppointment:(id)sender {
    self.previouslySelectedAppointment = self.selectedAppointment;
    [self editAppointment:self.selectedAppointment];
}
-(void)editAppointment:(Appointment*)appointment {
    if (appointment.completed.boolValue || appointment.cancelled.boolValue) {
        [self presentAppointmentViewerOnTab:AMCAppointmentViewAppointment withAppointment:appointment];
    } else {
        [self showBookingWizardInMode:EditModeEdit];
    }
}
-(IBAction)cancelSelectedAppointment:(id)sender {
    [self cancelAppointment:self.selectedAppointment];
}
-(void)cancelAppointment:(Appointment*)appointment {
    if (!appointment) return;
    AMCCancelAppointmentViewController * vc = self.cancelAppointmentViewController;
    vc.appointment = appointment;
    NSRect rect = [self rectForAppointment:appointment column:1];
    [self presentViewController:vc asPopoverRelativeToRect:rect ofView:self.appointmentsTable preferredEdge:NSMaxYEdge behavior:NSPopoverBehaviorTransient];
}
-(IBAction)completeSelectedAppointment:(id)sender {
    [self completeAppointment:self.selectedAppointment];
}
-(void)completeAppointment:(Appointment*)appointment {
    AMCCompleteAppointmentViewController * vc = [self completeAppointmentViewController];
    vc.appointment = appointment;
    NSRect rect = [self rectForAppointment:appointment column:1];
    [self presentViewController:vc asPopoverRelativeToRect:rect ofView:self.appointmentsTable preferredEdge:NSMinYEdge behavior:NSPopoverBehaviorTransient];
}
- (IBAction)viewSelectedCustomer:(id)sender {
    [self viewCustomerForAppointment:self.selectedAppointment];
}
-(void)viewCustomerForAppointment:(Appointment*)appointment {
    if (!appointment) return;
    Customer * customer = appointment.customer;
    if (!customer) return;
    EditObjectViewController * viewController = self.editCustomerViewController;
    viewController.editMode = EditModeView;
    [viewController clear];
    viewController.objectToEdit = customer;
    [viewController prepareForDisplayWithSalon:self.salonDocument];
    [self presentViewControllerAsSheet:viewController];
}
- (IBAction)intervalChanged:(id)sender {
    [self reloadData];
}

- (IBAction)showNotesButtonClicked:(id)sender {
    [self showCustomerNotesForAppointment:self.selectedAppointment];
}
-(void)showCustomerNotesForAppointment:(Appointment*)appointment {
    if (!appointment) return;
    AMCAssociatedNotesViewController * vc = self.associatedNotesViewController;
    vc.objectWithNotes = appointment.customer;
    [vc prepareForDisplayWithSalon:self.salonDocument];
    NSRect rect = [self rectForAppointment:appointment column:2];
    [self presentViewController:vc asPopoverRelativeToRect:rect ofView:self.appointmentsTable preferredEdge:NSMaxYEdge behavior:NSPopoverBehaviorTransient];
}
- (IBAction)rightClickShowQuickQuote:(id)sender {
    [self showQuickQuoteForAppointment:[self appointmentForRightClick]];
}
- (IBAction)showQuickQuoteForSelectedAppointment:(id)sender {
    [self showQuickQuoteForAppointment:self.selectedAppointment];
}
-(void)showQuickQuoteForAppointment:(Appointment*)appointment {
    AMCQuickQuoteViewController* vc = self.quickQuoteViewController;
    vc.sale = appointment.sale;
    [vc prepareForDisplayWithSalon:self.salonDocument];
    NSRect rect = [self rectForAppointment:appointment column:8];
    [self presentViewController:vc asPopoverRelativeToRect:rect ofView:self.appointmentsTable preferredEdge:NSMaxYEdge behavior:NSPopoverBehaviorTransient];
}
-(NSRect)rectForAppointment:(Appointment*)appointment column:(NSInteger)column {
    NSInteger row = [self.appointments indexOfObject:appointment];
    [self.appointmentsTable scrollRowToVisible:row];
    NSRect rect = [self.appointmentsTable rectOfRow:row];
    rect = NSIntersectionRect(rect, [self.appointmentsTable rectOfColumn:column]);
    return rect;
}
- (IBAction)appointmentStateSelectorChanged:(id)sender {
    [self reloadData];
}
- (IBAction)searchFieldChanged:(id)sender {
    _searchFilteredAppointments = nil;
    [self.appointmentsTable reloadData];
    [self.saleItemsTable reloadData];
    [self appointmentSelectionChanged];
    [self saleItemSelectionChanged];
}

-(void)dismissViewController:(NSViewController *)viewController {
    if (viewController == self.cancelAppointmentViewController) {
        if (!self.cancelAppointmentViewController.cancelled) {
            [self reloadData];
        }
    }
    if (viewController == self.completeAppointmentViewController) {
        if (!self.completeAppointmentViewController.cancelled) {
            [self reloadData];
            if (self.completeAppointmentViewController.appointment.completionType.integerValue == AMCompletionTypeCompletedWithConversionToQuote) {
                [self convertAppointmentToQuote:self.completeAppointmentViewController.appointment];
            }
        }
    }
    if (viewController == self.quickQuoteViewController) {
        [self reloadData];
        [self selectAppointment:self.previouslySelectedAppointment];
        [self configureButtons];
    }
    [super dismissViewController:viewController];
}
-(AMCCancelAppointmentViewController *)cancelAppointmentViewController {
    if (!_cancelAppointmentViewController) {
        _cancelAppointmentViewController = [AMCCancelAppointmentViewController new];
        _cancelAppointmentViewController.salonDocument = self.salonDocument;
    }
    return _cancelAppointmentViewController;
}
-(AMCCompleteAppointmentViewController *)completeAppointmentViewController {
    if (!_completeAppointmentViewController) {
        _completeAppointmentViewController = [AMCCompleteAppointmentViewController new];
        _completeAppointmentViewController.salonDocument = self.salonDocument;
    }
    return _completeAppointmentViewController;
}
-(AMCQuickQuoteViewController *)quickQuoteViewController {
    if (!_quickQuoteViewController) {
        _quickQuoteViewController = [AMCQuickQuoteViewController new];
        _quickQuoteViewController.salonDocument = self.salonDocument;
    }
    return _quickQuoteViewController;
}
-(AMCAssociatedNotesViewController *)associatedNotesViewController {
    if (!_associatedNotesViewController) {
        _associatedNotesViewController = [AMCAssociatedNotesViewController new];
        _associatedNotesViewController.salonDocument = self.salonDocument;
    }
    return _associatedNotesViewController;
}
@end
