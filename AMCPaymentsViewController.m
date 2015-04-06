//
//  AMCPaymentsViewController.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 22/11/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "AMCPaymentsViewController.h"
#import "AMCMoneyTransferViewController.h"
#import "AMCPaymentCategoryListViewController.h"
#import "AMCFinancialAnalysisViewController.h"
#import "AMCSalaryPaymentViewController.h"

#import "Payment+Methods.h"
#import "Account+Methods.h"
#import "AMCConstants.h"
#import "NSDate+AMCDate.h"

#import "PaymentCategory.h"
#import "WorkRecord+Methods.h"
#import "Employee+Methods.h"
#import "AMCSalonDocument.h"

@interface AMCPaymentsViewController ()
{

}
@property (weak) IBOutlet NSPopUpButton *accountSelector;
@property (weak) IBOutlet NSSegmentedControl *directionSelector;
@property (weak) IBOutlet NSSegmentedControl *reconciliationStateSelector;
@property (weak) IBOutlet NSButton *tillPaymentButton;
@property (weak) IBOutlet NSButton *bankPaymentButton;
@property (weak) IBOutlet NSButton *transferMoneyButton;
@property (weak) IBOutlet NSButton *voidPaymentButton;
@property (strong) IBOutlet AMCSalaryPaymentViewController *salaryPaymentWindowController;
@property (strong) IBOutlet AMCMoneyTransferViewController * moneyTransferViewController;
@property (strong) IBOutlet AMCPaymentCategoryListViewController *paymentCategoryListViewController;
@property (strong) IBOutlet AMCFinancialAnalysisViewController *financialAnalysisWindowController;
@property (weak) IBOutlet NSPopUpButton *paymentCategoryPopup;

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
    if ([columnID isEqualToString:@"bankStatementDate"]) {
        if (payment.reconciledWithBankStatement.boolValue) {
            if (payment.bankStatementTransactionDate) {
                view.textField.stringValue = [payment.bankStatementTransactionDate dateStringWithMediumDateFormat];
            } else {
                view.textField.stringValue = @"???";
            }
        } else {
            view.textField.stringValue = @"";
        }
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
-(Payment*)createNewPayment
{
    Payment * payment = [Payment newObjectWithMoc:self.documentMoc];
    [self reloadData];
    return payment;
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
    Payment * payment = [self createNewPayment];
    Account * account = self.salonDocument.salon.tillAccount;
    payment.account = account;
    [self editObject:payment forSalon:self.salonDocument inMode:EditModeCreate withViewController:self.editObjectViewController];
}
- (IBAction)bankPaymentClicked:(id)sender {
    self.objectSelectedBeforeEditorInvoked = self.selectedObject;
    Payment * payment = [self createNewPayment];
    Account * account = self.salonDocument.salon.primaryBankAccount;
    payment.account = account;
    [self editObject:payment forSalon:self.salonDocument inMode:EditModeCreate withViewController:self.editObjectViewController];
}
- (IBAction)transferMoneyClicked:(id)sender {
    self.objectSelectedBeforeEditorInvoked = self.selectedObject;
    NSButton * button = sender;
    [self.moneyTransferViewController prepareForDisplayWithSalon:self.salonDocument];
    [self presentViewController:self.moneyTransferViewController asPopoverRelativeToRect:button.bounds ofView:button preferredEdge:NSMinYEdge behavior:NSPopoverBehaviorApplicationDefined];
}
- (IBAction)voidPaymentClicked:(id)sender {
    self.objectSelectedBeforeEditorInvoked = self.selectedObject;
    Payment * payment = [self selectedPayment];
    if (!payment) return;
    NSString * info = [NSString stringWithFormat:@"Once voided, this Payment of £%@ to %@ will no longer be visible on the Payments tab and will not appear in reports or Sales totals.\n\nPlease note that you can't undo this action.",payment.amount,payment.payeeName];
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"Void this Payment?"];
    [alert setInformativeText:info];
    [alert addButtonWithTitle:@"Void the Payment"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert beginSheetModalForWindow:[NSApp mainWindow] completionHandler:^(NSModalResponse response) {
        if (response == NSAlertFirstButtonReturn) {
            payment.voided = @(YES);
            [self.salonDocument commitAndSave:nil];
            [self reloadData];
        }
    }];
}
- (IBAction)paymentCategoryChanged:(id)sender {
    [self reloadData];
}

- (IBAction)editPaymentCategoryList:(id)sender {
    [self.paymentCategoryListViewController prepareForDisplayWithSalon:self.salonDocument];
    [self presentViewControllerAsSheet:self.paymentCategoryListViewController];
}
- (IBAction)showFinancialAnalysisWindow:(id)sender {
    [self.financialAnalysisWindowController prepareForDisplayWithSalon:self.salonDocument];
    [self presentViewControllerAsSheet:self.financialAnalysisWindowController];
}
- (IBAction)paySalariesButtonClicked:(id)sender {
    [self.salaryPaymentWindowController prepareForDisplayWithSalon:self.salonDocument];
    [self presentViewControllerAsSheet:self.salaryPaymentWindowController];
}
-(void)dismissViewController:(NSViewController *)viewController {
    [self populatePaymentCategoryPopup];
    [self populateAccountPopup];
    [self reloadData];
    [super dismissViewController:viewController];
}
@end
