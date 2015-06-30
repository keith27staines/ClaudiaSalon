//
//  AMCPaymentsViewController.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 22/11/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "AMCPaymentsViewController.h"
#import "AMCMoneyTransferViewController.h"

#import "Payment+Methods.h"
#import "Sale+Methods.h"
#import "Customer+Methods.h"
#import "Account+Methods.h"
#import "AMCConstants.h"
#import "NSDate+AMCDate.h"

#import "PaymentCategory.h"
#import "WorkRecord+Methods.h"
#import "Employee+Methods.h"
#import "AMCSalonDocument.h"

#import "EditEmployeeViewController.h"
#import "AMCAppointmentViewer.h"

@interface AMCPaymentsViewController ()
{

}
@property (weak) IBOutlet NSPopUpButton *accountSelector;
@property (weak) IBOutlet NSSegmentedControl *directionSelector;
@property (weak) IBOutlet NSSegmentedControl *reconciliationStateSelector;
@property (strong) IBOutlet AMCMoneyTransferViewController * moneyTransferViewController;
@property (weak) IBOutlet NSPopUpButton *paymentCategoryPopup;
@property (weak) IBOutlet NSButton *addButton;

@property (strong) IBOutlet EditEmployeeViewController *editEmployeeViewController;
@property (strong) IBOutlet AMCAppointmentViewer *appointmentViewer;

@end

@implementation AMCPaymentsViewController


#pragma mark - AMCEntityViewController Overrides
- (NSString*)entityName {
    return @"Payment";
}
-(NSPredicate*)filtersPredicate {
    NSMutableArray * predicates = [NSMutableArray array];
    [predicates addObject:[NSPredicate predicateWithFormat:@"voided = %@",@(NO)]];
    switch (self.directionSelector.selectedSegment) {
        case 0:
            [predicates addObject:[NSPredicate predicateWithFormat:@"direction = %@",kAMCPaymentDirectionIn]];
            break;
        case 1:
            [predicates addObject:[NSPredicate predicateWithFormat:@"direction = %@",kAMCPaymentDirectionOut]];
            break;
        default:
            break;
    }
    switch (self.reconciliationStateSelector.selectedSegment) {
        case 0:
            [predicates addObject:[NSPredicate predicateWithFormat:@"reconciledWithBankStatement = %@",@(YES)]];
            break;
        case 1:
            [predicates addObject:[NSPredicate predicateWithFormat:@"reconciledWithBankStatement = %@",@(NO)]];
            break;
        default:
            break;
    }
    Account * account = self.accountSelector.selectedItem.representedObject;
    if (account) {
        [predicates addObject:[NSPredicate predicateWithFormat:@"account = %@",account]];
    }
    PaymentCategory * paymentCategory = self.paymentCategoryPopup.selectedItem.representedObject;
    if (paymentCategory) {
        [predicates addObject:[NSPredicate predicateWithFormat:@"paymentCategory = %@",paymentCategory]];
    }
    return [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
}
-(void)prepareForDisplayWithSalon:(AMCSalonDocument *)salonDocument {
    [super prepareForDisplayWithSalon:salonDocument];
    [self populateAccountPopup];
    [self populatePaymentCategoryPopup];
    self.dataTable.doubleAction = @selector(viewDetailsClicked:);
}
-(void)applySearchField {
    NSString * search = self.searchField.stringValue;
    if (!search || search.length == 0) {
        self.displayedObjects = [self.filteredObjects copy];
        return;
    }
    NSPredicate * searchPredicate = [NSPredicate predicateWithFormat:@"payeeName contains[cd] %@ or amount = %@",search,@(search.doubleValue)];
    self.displayedObjects = [self.filteredObjects filteredArrayUsingPredicate:searchPredicate];
}
#pragma mark - "PermissionDenied" Delegate
-(BOOL)permissionDeniedNeedsOKButton {
    return NO;
}
#pragma mark - NSViewController Overrides
-(NSString *)nibName {
    return @"AMCPaymentsViewController";
}
- (void)viewDidLoad {
    [super viewDidLoad];
    NSSortDescriptor* sortDescriptor = [[NSSortDescriptor alloc] initWithKey: @"paymentDate" ascending: NO];
    [self.dataTable setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
}

#pragma mark - NSTableViewDelegate
-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    Payment * payment = self.displayedObjects[row];
    NSString * columnID = tableColumn.identifier;
    NSTableCellView * view = [tableView makeViewWithIdentifier:columnID owner:self];
    if ([columnID isEqualToString:@"paymentDay"]) {
        view.textField.stringValue = [payment.paymentDate stringNamingDayOfWeek];
        return view;
    }
    if ([columnID isEqualToString:@"paymentDate"]) {
        view.textField.stringValue = [payment.paymentDate dateStringWithMediumDateFormat];
        return view;
    }
    if ([columnID isEqualToString:@"paymentTime"]) {
        view.textField.stringValue = [payment.paymentDate timeStringWithShortFormat];
        return view;
    }
    if ([columnID isEqualToString:@"amount"]) {
        view.textField.stringValue = [NSString stringWithFormat:@"£%1.2f",payment.amount.doubleValue];
        return view;
    }
    if ([columnID isEqualToString:@"account"]) {
        if (payment.account) {
            view.textField.stringValue = payment.account.friendlyName;
        } else {
            view.textField.stringValue = @"UNKNOWN";
        }
        return view;
    }
    if ([columnID isEqualToString:@"direction"]) {
        view.textField.stringValue = payment.direction;
        return view;
    }
    if ([columnID isEqualToString:@"name"]) {
        if (payment.payeeName) {
            view.textField.stringValue = payment.payeeName;
        } else {
            view.textField.stringValue = @"";
        }
        return view;
    }
    if ([columnID isEqualToString:@"isRefund"]) {
        view.textField.stringValue = payment.refundYNString;
        return view;
    }
    if ([columnID isEqualToString:@"explanation"]) {
        if (payment.paymentCategory) {
            view.textField.stringValue = payment.paymentCategory.categoryName;
        } else {
            view.textField.stringValue = [NSString stringWithFormat:@"* %@",payment.reason];
        }
        return view;
    }
    return nil;
}
#pragma mark - private implementation
-(Payment*)selectedPayment {
    return self.displayedObjects[self.dataTable.selectedRow];
}
-(void)populatePaymentCategoryPopup {
    NSManagedObjectContext * moc = self.documentMoc;
    [self.paymentCategoryPopup removeAllItems];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"PaymentCategory" inManagedObjectContext:moc];
    [fetchRequest setEntity:entity];
    // Specify how the fetched objects should be sorted
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"categoryName"
                                                                   ascending:YES];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];
    
    NSError *error = nil;
    NSArray *fetchedObjects = [moc executeFetchRequest:fetchRequest error:&error];
    if (fetchedObjects == nil) {
        [NSApp presentError:error];
    }

    NSMenu * menu = self.paymentCategoryPopup.menu;
    NSMenuItem * item = [[NSMenuItem alloc] init];
    item.title = @"All categories";
    [menu addItem:item];
    for (PaymentCategory * category in fetchedObjects) {
        item = [[NSMenuItem alloc] init];
        item.title = category.categoryName;
        item.representedObject = category;
        [menu addItem:item];
    }
}
-(void)populateAccountPopup {
    [self.accountSelector removeAllItems];
    NSMenu * menu = self.accountSelector.menu;
    NSMenuItem * menuItem = [[NSMenuItem alloc] init];
    menuItem.title = @"All accounts";
    menuItem.representedObject = nil;
    [menu addItem:menuItem];
    NSArray * accounts = [Account allObjectsWithMoc:self.documentMoc];
    for (Account * account in accounts) {
        menuItem = [[NSMenuItem alloc] init];
        menuItem.title = account.friendlyName;
        menuItem.representedObject = account;
        [menu addItem:menuItem];
    }
    [self.accountSelector selectItemAtIndex:0];
}
#pragma mark - Actions
-(IBAction)viewDetailsClicked:(id)sender {
    self.objectSelectedBeforeEditorInvoked = self.selectedObject;
    [self editObject:self.selectedObject forSalon:self.salonDocument inMode:EditModeView withViewController:self.editObjectViewController];
}
-(IBAction)rightClickViewDetails:(id)sender {
    self.objectSelectedBeforeEditorInvoked = self.selectedObject;
    Payment * payment = self.displayedObjects[self.dataTable.clickedRow];
    [self editObject:payment forSalon:self.salonDocument inMode:EditModeView withViewController:self.editObjectViewController];
}
- (IBAction)showAddRemoveActionMenu:(id)sender {
    NSButton * button = (NSButton*)sender;
    NSMenu * menu = button.menu;
    // Get menu rect in screen window coordinates (menu's size is in screen coordinates)
    NSRect menuRect = [button.window convertRectFromBacking:NSMakeRect(0, 0, menu.size.width, menu.size.height)];
    menuRect = [self.view convertRect:menuRect fromView:nil];
    [menu popUpMenuPositioningItem:nil atLocation:NSMakePoint(button.frame.origin.x+4, NSMaxY(button.frame)+menuRect.size.height-10) inView:self.view];
}
-(IBAction)rightClickViewPayeeInfo:(id)sender {
    self.objectSelectedBeforeEditorInvoked = self.selectedObject;
    Payment * payment = self.displayedObjects[self.dataTable.clickedRow];
    if (payment.sale.customer) {
        [self presentAppointmentViewerOnTab:AMCAppointmentViewCustomer withPayment:payment];
    } else if(payment.workRecord.employee) {
        self.editEmployeeViewController.objectToEdit = payment.workRecord.employee;
        self.editEmployeeViewController.editMode = EditModeView;
        [self.editEmployeeViewController prepareForDisplayWithSalon:self.salonDocument];
        [self presentViewControllerAsSheet:self.editEmployeeViewController];
    } else {
        NSAlert * alert = [[NSAlert alloc] init];
        alert.alertStyle = NSInformationalAlertStyle;
        alert.messageText = @"No Customer Found";
        alert.informativeText = @"This Payment isn't associated with a Customer";
        [alert runModal];
    }
}
-(IBAction)rightClickViewSale:(id)sender {
    self.objectSelectedBeforeEditorInvoked = self.selectedObject;
    Payment * payment = self.displayedObjects[self.dataTable.clickedRow];
    if (payment.sale) {
        [self presentAppointmentViewerOnTab:AMCAppointmentViewSale withPayment:payment];
    } else {
        NSAlert * alert = [[NSAlert alloc] init];
        alert.alertStyle = NSInformationalAlertStyle;
        alert.messageText = @"No Sale Found";
        alert.informativeText = @"This Payment isn't associated with a Sale";
        [alert runModal];
    }
}
-(void)presentAppointmentViewerOnTab:(AMCAppointmentViews)tab
                         withPayment:(Payment*)payment {
    self.appointmentViewer.sale = payment.sale;
    self.appointmentViewer.customer = payment.sale.customer;
    self.appointmentViewer.appointment = payment.sale.fromAppointment;
    self.appointmentViewer.selectedView = tab;
    [self.appointmentViewer prepareForDisplayWithSalon:self.salonDocument];
    [self presentViewControllerAsSheet:self.appointmentViewer];
}
-(IBAction)rightClickViewAppointment:(id)sender {
    self.objectSelectedBeforeEditorInvoked = self.selectedObject;
    Payment * payment = self.displayedObjects[self.dataTable.clickedRow];
    if (payment.sale.fromAppointment) {
        [self presentAppointmentViewerOnTab:AMCAppointmentViewAppointment withPayment:payment];
    } else {
        NSAlert * alert = [[NSAlert alloc] init];
        alert.alertStyle = NSInformationalAlertStyle;
        alert.messageText = @"No Appointment Found";
        alert.informativeText = @"This Payment isn't associated with an Appointment";
        [alert runModal];
    }
}
- (IBAction)accountSelected:(id)sender {
    [self reloadData];
}
- (IBAction)directionSelected:(id)sender {
    [self reloadData];
}
- (IBAction)reconciliationStateSelected:(id)sender {
    [self reloadData];
}
- (IBAction)tillPaymentClicked:(id)sender {
    self.objectSelectedBeforeEditorInvoked = self.selectedObject;
    Account * account = self.salonDocument.salon.tillAccount;
    Payment * payment = [account makePaymentWithAmount:@(0) date:[NSDate date] category:nil direction:kAMCPaymentDirectionOut payeeName:@"" reason:@""];
    [self reloadData];
    [self editObject:payment forSalon:self.salonDocument inMode:EditModeCreate withViewController:self.editObjectViewController];
}
- (IBAction)bankPaymentClicked:(id)sender {
    self.objectSelectedBeforeEditorInvoked = self.selectedObject;
    Account * account = self.salonDocument.salon.primaryBankAccount;
    Payment * payment = [account makePaymentWithAmount:@(0) date:[NSDate date] category:nil direction:kAMCPaymentDirectionOut payeeName:@"" reason:@""];
    [self reloadData];
    [self editObject:payment forSalon:self.salonDocument inMode:EditModeCreate withViewController:self.editObjectViewController];
}
- (IBAction)transferMoneyClicked:(id)sender {
    self.objectSelectedBeforeEditorInvoked = self.selectedObject;
    [self.moneyTransferViewController prepareForDisplayWithSalon:self.salonDocument];
    [self presentViewControllerAsSheet:self.moneyTransferViewController];
}
- (IBAction)rightClickVoidPayment:(id)sender {
    self.objectSelectedBeforeEditorInvoked = self.selectedObject;
    Payment * payment = self.displayedObjects[self.dataTable.clickedRow];
    [self voidPayment:payment];
}
- (IBAction)voidPaymentClicked:(id)sender {
    self.objectSelectedBeforeEditorInvoked = self.selectedObject;
    [self voidPayment:[self selectedPayment]];
}
-(void)voidPayment:(Payment*)payment {
    if (!payment) return;
    if (payment.isReconciled) {
        NSAlert * alert = [[NSAlert alloc] init];
        alert.alertStyle = NSInformationalAlertStyle;
        alert.messageText = @"Payment cannot be edited or voided";
        alert.informativeText = @"The date of the last account reconciliation point for the payment's account is later than the payment date. The details of this payment are now fixed in order to protect the validity of the accounts";
        [alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
            
        }];
    } else {
        NSString * info = [NSString stringWithFormat:@"Once voided, this Payment of £%@ to %@ will no longer be visible on the Payments tab and will not appear in reports or Sales totals.\n\nYou can't undo this action.",payment.amount,payment.payeeName];
        NSAlert *alert = [[NSAlert alloc] init];
        alert.alertStyle = NSWarningAlertStyle;
        [alert setMessageText:@"Void this Payment?"];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:@"Void the Payment"];
        [alert addButtonWithTitle:@"Cancel"];
        [alert beginSheetModalForWindow:[NSApp mainWindow] completionHandler:^(NSModalResponse response) {
            if (response == NSAlertFirstButtonReturn) {
                payment.voided = @(YES);
                payment.transferPartner.voided = @(YES);
                [self reloadData];
                NSAlert * alert = [[NSAlert alloc] init];
                alert.alertStyle = NSInformationalAlertStyle;
                alert.messageText = @"Payment was a transfer";
                NSString * thisDirection;
                NSString * otherDirection;
                if (payment.transferPartner) {
                    if (payment.isIncoming) {
                        thisDirection = @"incoming";
                        otherDirection = @"outgoing";
                    } else {
                        thisDirection = @"outgoing";
                        otherDirection = @"incoming";
                    }
                }
                alert.informativeText = [NSString stringWithFormat:@"This payment was the %@ payment of a transfer. The corresponding %@ payment has also been voided",thisDirection,otherDirection];
                [alert beginSheetModalForWindow:[NSApp mainWindow] completionHandler:nil];
            }
        }];
    }
}
- (IBAction)paymentCategoryChanged:(id)sender {
    [self reloadData];
}
-(void)dismissViewController:(NSViewController *)viewController {
    [self populatePaymentCategoryPopup];
    [self populateAccountPopup];
    [self reloadData];
    [super dismissViewController:viewController];
}
@end
