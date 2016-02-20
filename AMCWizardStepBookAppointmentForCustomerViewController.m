//
//  AMCWizardStepBookAppointmentForCustomerViewController.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 24/08/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "AMCWizardStepBookAppointmentForCustomerViewController.h"
#import "Appointment+Methods.h"
#import "ServiceCategory+Methods.h"
#import "Service+Methods.h"
#import "Sale+Methods.h"
#import "SaleItem+Methods.h"
#import "Employee+Methods.h"
#import "AMCJobsColumnView.h"
#import "AMCJobsColumnViewController.h"
#import "AMCSaleItemViewController.h"
#import "AMCQuickQuoteViewController.h"
#import "AMCAssociatedNotesViewController.h"
#import "NSDate+AMCDate.h"
#import "AMCBookingViewController.h"
#import "AMCStaffBusyViewController.h"
#import "AMCEmployeeForServiceSelector.h"
#import "AMCAdvancePayment.h"
#import "Payment+Methods.h"
#import "ClaudiaSalon-swift.h"

@interface AMCWizardStepBookAppointmentForCustomerViewController () <NSTableViewDataSource, NSTableViewDelegate, AMCJobsColumnViewDelegate, AMCServiceCategoryPopupControllerDelegate>
{
    NSMutableArray * _chosenServices;
    AMCEmployeeForServiceSelector * _staffForServiceViewController;
    AMCQuickQuoteViewController * _quickQuoteViewController;
}
@property (readonly) Appointment * appointment;
@property NSMutableArray * chosenServices;
@property NSTimer * timer;
@property NSArray * appointmentsOnSelectedDay;
@property (readonly) AMCEmployeeForServiceSelector * staffForServiceViewController;
@property (readonly) AMCQuickQuoteViewController * quickQuoteViewController;
@property (strong) IBOutlet AMCAdvancePayment *advancePaymentViewController;
@property (strong) IBOutlet AMCServiceCategoryPopupController *serviceCategoryPopupController;

@end

@implementation AMCWizardStepBookAppointmentForCustomerViewController
-(void)awakeFromNib {
    self.timeNowLabel.stringValue = [self stringForDate:[NSDate date]];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                  target:self
                                                selector:@selector(updateTime)
                                                userInfo:nil
                                                 repeats:YES];
    self.appointmentsOnSelectedDay = [Appointment appointmentsOnDayOfDate:self.datePicker.dateValue withMoc:self.documentMoc];
}
-(void)dealloc {
    [self.timer invalidate];
}

-(void)viewDidLoad {
    [super viewDidLoad];
    self.serviceCategoryPopupController.delegate = self;
}
#pragma mark - Overrides we must implement here
-(NSString *)nibName {
    return @"AMCWizardStepBookAppointmentForCustomerViewController";
}
-(void)prepareForDisplayWithSalon:(AMCSalonDocument *)salonDocument {
    [super prepareForDisplayWithSalon:self.salonDocument];
    [self loadCategoryPopup];
    [self enableAddRemoveServiceButtons];
}
-(BOOL)isValid {
    return ([self.appointment.appointmentDate isGreaterThan:[NSDate distantPast]] &&
            self.appointment.bookedDuration.integerValue > 0 &&
            self.appointment.sale.saleItem.count > 0);
}
-(void)resetToObject {
    Appointment * appointment = self.appointment;
    if (appointment) {
        [self loadSaleItems];
        [self.chosenServicesTable reloadData];
        if ([self.appointment.appointmentDate isEqualToDate:[NSDate distantPast]]) {
            [self.datePicker setDateValue:[NSDate date]];
        } else {
            [self.datePicker setDateValue:self.appointment.appointmentDate];
        }
        [self datePickerChanged:self];
        [self.appointmentSlotsTable reloadData];
        if (appointment.sale.advancePayment) {
            self.advancePaymentLabel.objectValue = appointment.sale.advancePayment.amount;
        } else {
            self.advancePaymentLabel.objectValue = @(0);
        }
    }
    [self displayTotal];
}
-(Appointment*)appointment {
    return (Appointment*)self.objectToManage;
}

#pragma mark - Helpers
-(BOOL)rowIsBooked:(NSUInteger)row {
    NSDate * date = [self slotStartDateFromRow:row];
    NSDate * appointmentStart = self.appointment.appointmentDate;
    NSDate * appointmentEnd = [appointmentStart dateByAddingTimeInterval:self.appointment.bookedDuration.integerValue];
    if ([date isGreaterThanOrEqualTo:appointmentStart] &&
        [date isLessThan:appointmentEnd]) {
        return YES;
    } else {
        return NO;
    }
}
-(BOOL)calculateAppointmentTime:(NSError**)error {
    NSIndexSet * selectedRows = self.appointmentSlotsTable.selectedRowIndexes;
    if (![self goodSlotSelection:selectedRows error:error]) return NO;
    NSUInteger r1 = selectedRows.firstIndex;
    NSUInteger r2 = selectedRows.lastIndex;
    NSDate * date1 = [self slotStartDateFromRow:r1];
    NSDate * date2 = [self slotEndDateFromRow:r2];
    self.appointment.appointmentDate = date1;
    self.appointment.bookedDuration = @([date2 timeIntervalSinceDate:date1]);
    [self.delegate wizardStepControllerDidChangeState:self];
    return YES;
}
-(void)displayBookingValidityError:(NSError*)error {
    if (!error) return;
    [self.view presentError:error
             modalForWindow:self.view.window
                   delegate:self
         didPresentSelector:@selector(didPresentErrorWithRecovery:contextInfo:)
                contextInfo:nil];
}
-(BOOL)goodSlotSelection:(NSIndexSet*)selection error:(NSError**)error {
    if (selection.count == 0) {
        if (error != NULL) {
            NSString * description = [NSString stringWithFormat:@"Cannot create the appointment"];
            NSString * failureReason = @"No time slots have been chosen";
            NSString * recoverySuggestion = @"You must select at least one time slot for this appointment";
            NSDictionary * userInfo = @{NSLocalizedDescriptionKey:description,
                                        NSLocalizedFailureReasonErrorKey: failureReason,
                                        NSLocalizedRecoverySuggestionErrorKey: recoverySuggestion};
            *error = [NSError errorWithDomain:@"Claudia's Salon" code:1 userInfo:userInfo];
            return NO;
        }
    }
    return YES;
}
-(BOOL)isBookingValidForStart:(NSDate*)startDate endDate:(NSDate*)endDate error:(NSError**)error {
    // Check booking is entirely in the future
    if ([startDate isLessThan:[NSDate date]]) {
        if (error != NULL) {
            NSString * description = [NSString stringWithFormat:@"Cannot create the appointment"];
            NSString * failureReason;
            NSString * recoverySuggestion;
            if ([endDate isLessThan:[NSDate date]]) {
                failureReason= @"The appointment is in the past";
                recoverySuggestion = @"Have you selected the right date?";
            } else {
                failureReason= @"The appointment begins in the past";
                recoverySuggestion = @"Have you selected the right time?";
            }
            NSDictionary * userInfo = @{NSLocalizedDescriptionKey:description,
                                        NSLocalizedFailureReasonErrorKey: failureReason,
                                        NSLocalizedRecoverySuggestionErrorKey: recoverySuggestion};
            *error = [NSError errorWithDomain:@"Claudia's Salon" code:1 userInfo:userInfo];
            return NO;
        }
    }
    return YES;
}
-(BOOL)appointmentClashWarning {
    return YES;
}
-(NSUInteger)minuteFromRow:(NSUInteger)row {
    return fmod(row, 2) * 30;
}
-(NSUInteger)hourFromRow:(NSUInteger)row {
    return 8 + row/2;
}
-(NSDate*)slotStartDateFromRow:(NSUInteger)row {
    NSUInteger h = [self hourFromRow:row];
    NSUInteger m = [self minuteFromRow:row];
    NSDate * date = self.datePicker.dateValue;
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *components = [gregorian components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute fromDate:date];
    components.hour = h;
    components.minute = m;
    date = [gregorian dateFromComponents:components];
    return date;
}
-(NSDate*)slotEndDateFromRow:(NSUInteger)row {
    return [self slotStartDateFromRow:row+1];
}
-(void)updateTime {
    NSDate * rightNow = [NSDate date];
    self.timeNowLabel.stringValue = [self stringForDate:rightNow];
}
-(SaleItem*)selectedSaleItem {
    NSInteger selectedRow = self.chosenServicesTable.selectedRow;
    if (selectedRow >= 0) {
        return self.chosenServices[selectedRow];
    } else {
        return nil;
    }
}
-(NSString*)stringForDate:(NSDate*)date {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    return [dateFormatter stringFromDate:date];
}
-(void)loadCategoryPopup
{
    [self.serviceCategoryPopupController refreshListWithRootCategory:self.salonDocument.salon.rootServiceCategory];
}
- (void)loadSaleItems {
    self.chosenServices = [[self.appointment.sale.saleItem allObjects] mutableCopy];
    NSSortDescriptor * sort = [NSSortDescriptor sortDescriptorWithKey:@"createdDate" ascending:YES];
    self.chosenServices = [[self.chosenServices sortedArrayUsingDescriptors:@[sort]] mutableCopy];
    [self.chosenServicesTable reloadData];
}
-(void)loadEmployeePopup:(NSPopUpButton*)popup forSaleItem:(SaleItem*)saleItem {
    [popup removeAllItems];
    [popup addItemWithTitle:@"Unassigned"];
    [popup selectItemAtIndex:0];
    NSArray * stylists = [saleItem.service.canBeDoneBy allObjects];
    NSSortDescriptor * sort = [NSSortDescriptor sortDescriptorWithKey:@"fullName" ascending:YES];
    stylists = [stylists sortedArrayUsingDescriptors:@[sort]];
    NSPredicate * predicate = [NSPredicate predicateWithFormat:@"isActive == %@",@YES];
    stylists = [stylists filteredArrayUsingPredicate:predicate];
    for (Employee * stylist in stylists) {
        [popup addItemWithTitle:stylist.firstName];
        NSMenuItem * item = [popup.itemArray lastObject];
        item.representedObject = stylist;
        if (stylist == saleItem.performedBy) {
            [popup selectItem:item];
        }
    }
}
-(void)displayTotal {
    Sale * sale = self.appointment.sale;
    self.priceTotalLabel.stringValue = [NSString stringWithFormat:@"Total = £%1.2f",sale.actualCharge.doubleValue];
}
-(void)displayTotal {
    Sale * sale = self.appointment.sale;
    self.priceTotalLabel.stringValue = [NSString stringWithFormat:@"Total = £%1.2f",sale.actualCharge.doubleValue];
}
-(void)updateTotal {
    Sale * sale = self.appointment.sale;
    [sale updatePriceFromSaleItems];
    sale.bqNeedsCoreDataExport = @YES;
    [self displayTotal];
}
- (void)didPresentErrorWithRecovery:(BOOL)recover contextInfo:(void *)info {
    if (recover == NO) { // Recovery did not succeed, or no recovery attempted.
        // Proceed accordingly.
    }
}
#pragma mark -AMCJobsColumnViewDelegate
-(void)jobsColumnView:(AMCJobsColumnView *)view selectedStylist:(id)stylist {
    NSUInteger row = [self.chosenServicesTable rowForView:view];
    [self.chosenServicesTable selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    [self stateUpdateForTableSelectionChange];
    [self.view.window makeFirstResponder:self.chosenServicesTable];
    [[self selectedSaleItem] setPerformedBy:stylist];
}
#pragma mark - AMCServiceCategoryPopupControllerDelegate
-(void)serviceChanged:(Service *)service {
    [self enableAddRemoveServiceButtons];
}
#pragma mark - NSTableViewDataSource
-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    if (tableView == self.chosenServicesTable) {
        return self.chosenServices.count;
    }
    if (tableView == self.appointmentSlotsTable) {
        return 24;
    }
    return 0;
}
-(void)enableAddRemoveServiceButtons {
    [self.addServiceButton setEnabled:self.serviceCategoryPopupController.hasSelectedService];
    [self.removeServiceButton setEnabled:(self.chosenServicesTable.selectedRow >=0)];
}
-(void)enableSetAppointmentTimeButton {
    [self.setAppointmentTimeButton setEnabled:(self.appointmentSlotsTable.selectedRow>=0)];
}
#pragma mark - NSTableViewDelegate
-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (tableView == self.chosenServicesTable) {
        SaleItem * saleItem = self.chosenServices[row];
        if ([tableColumn.identifier isEqualToString:@"serviceName"]) {
            AMCJobsColumnViewController * vc = [[AMCJobsColumnViewController alloc] init];
            AMCJobsColumnView * view = (AMCJobsColumnView*)vc.view;
            view.delegate = self;
            NSString * serviceName = saleItem.service.name;
            view.textField.stringValue = serviceName;
            if (saleItem.service.deluxe.boolValue) {
                view.imageView.image = [[NSBundle mainBundle] imageForResource:@"GoldStarIcon"];
            } else {
                view.imageView.image = nil;
            }
            [self loadEmployeePopup:view.stylistPopup forSaleItem:saleItem];
            return view;
        }
        if ([tableColumn.identifier isEqualToString:@"timeRequired"]) {
            NSString * timeRequired = [NSString stringWithFormat:@"(%lu mins)",saleItem.service.expectedTimeRequired.integerValue];
            NSTableCellView * view = [tableView makeViewWithIdentifier:@"timeRequiredView" owner:self];
            view.textField.stringValue = timeRequired;
            return view;
        }
        if ([tableColumn.identifier isEqualToString:@"priceAfterDiscount"]) {
            NSString * itemPrice = [NSString stringWithFormat:@"£%1.2f",saleItem.actualCharge.doubleValue];
            NSTableCellView * view = [tableView makeViewWithIdentifier:@"timeRequiredView" owner:self];
            view.textField.stringValue = itemPrice;
            return view;
        }
    }
    if (tableView == self.appointmentSlotsTable) {
        NSTableCellView * view = [self.appointmentSlotsTable makeViewWithIdentifier:@"appointmentSlotView" owner:self];
        NSDate * slotStart = [self slotStartDateFromRow:row];
        NSDate * slotEnd = [self slotEndDateFromRow:row];
        NSMutableArray * appointmentsInSlot = [NSMutableArray array];
        for (Appointment * app in self.appointmentsOnSelectedDay) {
            if (app.cancelled.boolValue) continue;
            if ([app conflictsWithInterval:slotStart endOfInterval:slotEnd]) {
                [appointmentsInSlot addObject:app];
            }
        }
        NSNumberFormatter * h = [[NSNumberFormatter alloc] init];
        [h setMinimumIntegerDigits:2];
        [h setMaximumFractionDigits:0];
        NSNumberFormatter * m = [[NSNumberFormatter alloc] init];
        [m setMinimumIntegerDigits:2];
        [m setMaximumFractionDigits:0];
        NSString * basicText = [NSString stringWithFormat:@"%@.%@ – %@.%@ ",
                                [h stringFromNumber:@([self hourFromRow:row])],
                                [m stringFromNumber:@([self minuteFromRow:row])],
                                [h stringFromNumber:@([self hourFromRow:row+1])],
                                [m stringFromNumber:@([self minuteFromRow:row+1])]];
        NSString * text = [basicText copy];
        if ([appointmentsInSlot containsObject:self.appointment]) {
            if (appointmentsInSlot.count == 1) {
                text = [text stringByAppendingString:@"This appointment "];
                view.imageView.image = [[NSBundle mainBundle] imageForResource:@"GreenTickIcon"];
            } else {
                if (appointmentsInSlot.count == 2) {
                    text = [text stringByAppendingFormat:@"This appointment + 1 other already booked"];
                } else {
                    text = [text stringByAppendingFormat:@"This appointment + %@ others already booked",@(appointmentsInSlot.count - 1)];
                }
                view.imageView.image = [[NSBundle mainBundle] imageForResource:@"AmberWarningIcon"];
            }
        } else {
            if ([self rowIsBooked:row]) {
                text = [text stringByAppendingString:@"This appointment "];
                view.imageView.image = [[NSBundle mainBundle] imageForResource:@"GreenTickIcon"];
                if (appointmentsInSlot.count > 0) {
                    if (appointmentsInSlot.count == 1) {
                        text = [text stringByAppendingFormat:@"+ 1 other already booked"];
                    } else {
                        text = [text stringByAppendingFormat:@"+ %@ other already booked",@(appointmentsInSlot.count)];
                    }
                    view.imageView.image = [[NSBundle mainBundle] imageForResource:@"AmberWarningIcon"];
                }
            } else {
                if (appointmentsInSlot.count > 0) {
                    if (appointmentsInSlot.count == 1) {
                        text = [text stringByAppendingFormat:@"1 appointment already booked"];
                    } else {
                        text = [text stringByAppendingFormat:@"%@ appointments already booked",@(appointmentsInSlot.count)];
                    }
                    view.imageView.image = [[NSBundle mainBundle] imageForResource:@"AmberWarningIcon"];
                } else {
                    text = [text stringByAppendingString:@"Available"];
                    view.imageView.image = nil;
                }
            }
        }
        if ([self rowIsBooked:row]) {
            view.imageView.image = [[NSBundle mainBundle] imageForResource:@"GreenTickIcon"];
        }
        if ([slotStart isLessThan:[NSDate date]]) {
            if ([self rowIsBooked:row]) {
                view.imageView.image = [[NSBundle mainBundle] imageForResource:@"AmberWarningIcon"];
            } else {
                text = @"Unavailable (in the past)";
                view.imageView.image = [[NSBundle mainBundle] imageForResource:@"RedCrossIcon"];
            }
        }
        view.textField.stringValue = text;
        return view;
    }
    return nil;
}
-(void)tableViewSelectionDidChange:(NSNotification *)notification {
    [self stateUpdateForTableSelectionChange];
}
-(void)stateUpdateForTableSelectionChange {
    [self enableAddRemoveServiceButtons];
    [self enableSetAppointmentTimeButton];
    [self.delegate wizardStepControllerDidChangeState:self];
}
-(BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row {
    if (tableView == self.appointmentSlotsTable) {
        if ([[self slotStartDateFromRow:row] isLessThan:[NSDate date]]) {
            return NO;
        }
    }
    return YES;
}
#pragma mark - Actions
- (IBAction)setDateTimeToNowButtonClicked:(id)sender {
    self.datePicker.dateValue = [NSDate date];
    [self datePickerChanged:self];
}
- (IBAction)datePickerChanged:(id)sender {
    if (!self.datePicker) return;
    self.appointmentsOnSelectedDay = [Appointment appointmentsOnDayOfDate:self.datePicker.dateValue withMoc:self.documentMoc];
    [self.appointmentSlotsTable reloadData];
    [self.delegate wizardStepControllerDidChangeState:self];
    NSDate * datePickerDate = self.datePicker.dateValue;
    NSString * weekdayString = [datePickerDate stringNamingDayOfWeek];
    self.dayOfWeekLabel.stringValue = weekdayString;
    self.dateLabel.stringValue = [datePickerDate dayAndMonthString];
}
- (IBAction)addServiceButtonClicked:(id)sender {
    NSButton * button = sender;
    Service * service = self.serviceCategoryPopupController.selectedService;
    AMCEmployeeForServiceSelector * vc = self.staffForServiceViewController;
    vc.service = service;
    [vc prepareForDisplayWithSalon:self.salonDocument];
    [self presentViewController:vc asPopoverRelativeToRect:button.bounds ofView:button preferredEdge:NSMaxXEdge behavior:NSPopoverBehaviorApplicationDefined];
}
-(void)addSaleItemForService:(Service*)service performedBy:(Employee*)employee {
    SaleItem * saleItem = [SaleItem newObjectWithMoc:self.documentMoc];
    saleItem.service = service;
    saleItem.minimumCharge = service.minimumCharge;
    saleItem.maximumCharge = service.maximumCharge;
    saleItem.nominalCharge = service.nominalCharge;
    saleItem.actualCharge = service.nominalCharge;
    saleItem.discountType = @(AMCDiscountNone);
    saleItem.performedBy = employee;
    [self.chosenServices addObject:saleItem];
    [self.appointment.sale addSaleItemObject:saleItem];
    [self.chosenServicesTable reloadData];
    NSUInteger index = [self.chosenServices indexOfObject:saleItem];
    [self.chosenServicesTable selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:YES];
    [self updateTotal];
    [self.delegate wizardStepControllerDidChangeState:self];
}
-(void)dismissViewController:(NSViewController *)viewController {
    if (viewController == self.staffForServiceViewController && !self.staffForServiceViewController.cancelled) {
        [self addSaleItemForService:self.staffForServiceViewController.service performedBy:self.staffForServiceViewController.employee];
    }
    if (viewController == self.quickQuoteViewController) {
        [self.chosenServicesTable reloadData];
        [self updateTotal];
    }
    if (viewController == self.advancePaymentViewController) {
        if (self.appointment.sale.advancePayment) {
            self.advancePaymentLabel.objectValue = self.appointment.sale.advancePayment.amount;
        } else {
            self.advancePaymentLabel.objectValue = @(0);
        }
    }
    [super dismissViewController:viewController];
}
- (IBAction)removeServiceButtonClicked:(id)sender {
    SaleItem * saleItem = [self selectedSaleItem];
    if (!saleItem) return;
    [self.appointment.sale removeSaleItemObject:saleItem];
    [self.chosenServices removeObject:saleItem];
    [self.chosenServicesTable reloadData];
    [self updateTotal];
    [self.delegate wizardStepControllerDidChangeState:self];
}
- (IBAction)setAppointmentTimeButtonClicked:(id)sender {
    NSError * error;
    if (![self calculateAppointmentTime:&error]) {
        if (error)
            [self displayBookingValidityError:error];
    } else {
        NSArray * conflictingAppointments = [self.appointment conflictingAppointments];
        if (conflictingAppointments.count > 0) {
            NSString * messageText = @"";
            if (conflictingAppointments.count == 1) {
                messageText = [NSString stringWithFormat:@"Be careful! A possibly conflicting appointment already exists"];
                
            } else {
                messageText = [NSString stringWithFormat:@"Be careful! %@ possibly conflicting appointments already exist",@(conflictingAppointments.count)];
            }
            NSAlert * alert = [[NSAlert alloc] init];
            alert.messageText = messageText;
            alert.informativeText = @"Are you sure staff will be available to fulfil this appointment?";
            [alert addButtonWithTitle:@"Yes"];
            [alert addButtonWithTitle:@"Cancel"];
            [alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
                if (returnCode == NSAlertSecondButtonReturn) {
                    self.appointment.appointmentDate = [NSDate distantPast];
                    self.appointment.bookedDuration = @(0);
                }
            }];
        }
    }
    [self.appointmentSlotsTable reloadData];
}
- (IBAction)showNotesButtonClicked:(id)sender {
    AMCAssociatedNotesViewController * vc = [AMCAssociatedNotesViewController new];
    vc.objectWithNotes = self.appointment;
    [vc prepareForDisplayWithSalon:self.salonDocument];
    [self presentViewController:vc asPopoverRelativeToRect:self.showNotesButton.bounds ofView:self.showNotesButton preferredEdge:NSMinYEdge behavior:NSPopoverBehaviorTransient];
}
- (IBAction)quickQuoteButtonClicked:(id)sender {
    Sale * sale = ((Appointment*)self.objectToManage).sale;
    AMCQuickQuoteViewController * vc = self.quickQuoteViewController;
    vc.sale = sale;
    [vc prepareForDisplayWithSalon:self.salonDocument];
    [self presentViewController:vc asPopoverRelativeToRect:self.quickQuoteButton.bounds ofView:self.quickQuoteButton preferredEdge:NSMinYEdge behavior:NSPopoverBehaviorTransient];
}
-(AMCQuickQuoteViewController *)quickQuoteViewController {
    if (!_quickQuoteViewController) {
        _quickQuoteViewController = [AMCQuickQuoteViewController new];
    }
    return _quickQuoteViewController;
}
- (IBAction)showBookingViewButtonClicked:(id)sender {
    NSButton * button = sender;
    AMCBookingViewController * vc = [AMCBookingViewController new];
    vc.date = self.datePicker.dateValue;
    [vc prepareForDisplayWithSalon:self.salonDocument];
    [self presentViewController:vc asPopoverRelativeToRect:button.bounds ofView:button preferredEdge:NSMinXEdge behavior:NSPopoverBehaviorTransient];
}
- (IBAction)showBusyButtonClicked:(id)sender {
    NSButton * button = sender;
    AMCStaffBusyViewController * vc = [AMCStaffBusyViewController new];
    vc.startDate = self.datePicker.dateValue;
    vc.endDate = self.datePicker.dateValue;
    [vc prepareForDisplayWithSalon:self.salonDocument];
    [self presentViewController:vc asPopoverRelativeToRect:button.bounds ofView:button preferredEdge:NSMinXEdge behavior:NSPopoverBehaviorTransient];
}

-(AMCEmployeeForServiceSelector *)staffForServiceViewController {
    if (!_staffForServiceViewController) {
        _staffForServiceViewController = [AMCEmployeeForServiceSelector new];
    }
    return _staffForServiceViewController;
}
- (IBAction)advancePaymentButtonClicked:(id)sender {
    Sale * sale = self.appointment.sale;
    if (sale) {
        if (sale.advancePayment && [sale.advancePayment isReconciled]) {
            NSAlert * alert = [[NSAlert alloc] init];
            alert.messageText = @"Cannot change the advance payment";
            alert.informativeText = @"The advance payment has already been reconciled with a bank statement and therefore cannot be changed.";
            [alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
                
            }];
        } else {
            self.advancePaymentViewController.appointment = self.appointment;
            [self.advancePaymentViewController prepareForDisplayWithSalon:self.salonDocument];
            [self presentViewControllerAsSheet:self.advancePaymentViewController];
        }
    }
}

@end