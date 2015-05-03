//
//  AMCAccountStatementViewController.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 05/03/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "AMCAccountStatementViewController.h"
#import "Sale+Methods.h"
#import "Payment+Methods.h"
#import "Sale+Methods.h"
#import "Employee+Methods.h"
#import "Customer+Methods.h"
#import "AMCAccountStatementItem.h"
#import "Account+Methods.h"
#import "EditPaymentViewController.h"
#import "AMCSaleMiniEditorViewController.h"
#import "AMCCashBook.h"
#import "NSDate+AMCDate.h"
#import "AMCCashBookViewController.h"
#import "AMCBankStatementReconciliationViewController.h"
#import "AccountReconciliation+Methods.h"

@interface AMCAccountStatementViewController () <NSTableViewDataSource, NSTableViewDelegate>
{
    NSArray * _payments;
    NSMutableArray * _statementItems;
}
@property (weak) IBOutlet NSPopUpButton *accountPopup;
@property (weak) IBOutlet NSButton *doneButton;
@property (weak) IBOutlet NSTableView *dataTable;
@property (strong) IBOutlet EditPaymentViewController *editPaymentViewController;
@property (strong) IBOutlet AMCSaleMiniEditorViewController *editSaleViewController;
@property (weak) IBOutlet NSButton *addTransactionButton;
@property (weak) IBOutlet NSButton *removeTransactionButton;
@property (weak) IBOutlet NSButton *viewTransactionButton;
@property (weak) IBOutlet NSTextField *broughtForward;


@property Account * account;
@property (copy,readonly) NSArray * payments;
@property NSMutableArray * statementItems;

@property (strong) IBOutlet NSArrayController *arrayController;

@property (weak) IBOutlet NSTextField *finalBalance;

@property (weak) IBOutlet NSDatePicker *fromDatePicker;
@property (weak) IBOutlet NSDatePicker *toDatePicker;
@property (strong) IBOutlet AMCCashBookViewController *cashBookViewController;
@property (readonly) NSDate * startDate;
@property (readonly) NSDate * endDate;
@property double balance;
@property double amountBroughtForward;
@property (strong) IBOutlet AMCBankStatementReconciliationViewController *bankStatementReconciliationViewController;
@end

@implementation AMCAccountStatementViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}
-(NSString *)nibName {
    return @"AMCAccountStatementViewController";
}
-(void)prepareForDisplayWithSalon:(AMCSalonDocument *)salonDocument {
    [super prepareForDisplayWithSalon:salonDocument];
    NSSortDescriptor * sort = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES];
    self.dataTable.sortDescriptors = @[sort];
    self.fromDatePicker.dateValue = [[self.fromDatePicker.minDate beginningOfDay] dateByAddingTimeInterval:12*3600]; // Midday long ago
    self.toDatePicker.dateValue = [[[NSDate date] beginningOfDay] dateByAddingTimeInterval:12*3600]; // Midday today
    [self populateAccounts];
    [self reloadData];
    if (!self.accountPopup.selectedItem.representedObject) {
        self.addTransactionButton.enabled = NO;
        self.viewTransactionButton.enabled = NO;
    }
}
-(void)reloadData {
    _payments = nil;
    self.statementItems = [NSMutableArray array];
    [self loadAccount];
    [self.dataTable reloadData];
}
-(void)populateAccounts {
    [self.accountPopup removeAllItems];
    NSMenuItem * menuItem = [[NSMenuItem alloc] init];
    menuItem.title = @"Select account";
    [self.accountPopup.menu addItem:menuItem];
    for (Account * account in [Account allObjectsWithMoc:self.documentMoc]) {
        NSMenuItem * menuItem = [[NSMenuItem alloc] init];
        menuItem.title = account.friendlyName;
        menuItem.representedObject = account;
        [self.accountPopup.menu addItem:menuItem];
    }
}
-(NSDate *)startDate {
    return [self.fromDatePicker.dateValue beginningOfDay];
}
-(NSDate *)endDate {
    return [self.toDatePicker.dateValue endOfDay];
}
-(NSArray *)payments {
    if (!_payments) {
        _payments = [self.account paymentsBetween:self.startDate endDate:self.endDate];
    }
    return [_payments copy];
}
- (IBAction)accountChanged:(NSPopUpButton *)sender {
    [self reloadData];
}
-(void)loadAccount {
    self.account = self.accountPopup.selectedItem.representedObject;
    if (!self.account) {return;}
    self.statementItems = [NSMutableArray array];
    for (Payment * payment in self.payments) {
        AMCAccountStatementItem * statementItem = [[AMCAccountStatementItem alloc] initWithPayment:payment];
        [self.statementItems addObject:statementItem];
    }
    NSSortDescriptor * sort = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES];
    self.statementItems = [[self.statementItems sortedArrayUsingDescriptors:@[sort]] mutableCopy];
    self.balance = [self.account amountBroughtForward:self.startDate].doubleValue;
    for (AMCAccountStatementItem * item in self.statementItems) {
        self.balance = ( round(self.balance*100.0) + round(item.amountNet * 100.0) )/100.0;
        item.balance = self.balance;
    }
    self.amountBroughtForward = [self.account amountBroughtForward:self.startDate].doubleValue;
    self.broughtForward.objectValue = @(self.amountBroughtForward);
    NSAssert(self.balance == [self.account amountBroughtForward:self.endDate].doubleValue, @"balances don't match");
    self.finalBalance.doubleValue = self.balance;
    self.addTransactionButton.enabled = YES;
    self.viewTransactionButton.enabled = YES;
}
- (IBAction)exportToCSV:(id)sender {
    NSSavePanel* savePanel = [NSSavePanel savePanel];
    savePanel.title = @"Export";
    savePanel.extensionHidden = YES;
    savePanel.prompt = @"Export account data";
    savePanel.nameFieldStringValue = [NSString stringWithFormat:@"Claudia's Salon %@ account transactions.csv",self.account.friendlyName];
    savePanel.allowedFileTypes = @[@"csv"];
    savePanel.allowsOtherFileTypes = NO;
    [savePanel beginWithCompletionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            NSURL *saveURL = [savePanel URL];
            NSError * error;
            [self writeAccountStatementToFile:[saveURL path] error:&error];
        }
    }];
}
- (IBAction)viewPaymentDetails:(id)sender {
    NSInteger row = self.dataTable.selectedRow;
    AMCAccountStatementItem * item = self.arrayController.arrangedObjects[row];
    self.editSaleViewController.editMode = EditModeView;
    self.editSaleViewController.allowUserToChangeAccount = NO;
    self.editSaleViewController.transaction = item.payment;
    [self.editSaleViewController prepareForDisplayWithSalon:self.salonDocument];
    [self presentViewControllerAsSheet:self.editSaleViewController];
}
-(void)editNewTransaction:(id)transaction {
    self.editSaleViewController.editMode = EditModeCreate;
    self.editSaleViewController.allowUserToChangeAccount = YES;
    self.editSaleViewController.transaction = transaction;
    [self.editSaleViewController prepareForDisplayWithSalon:self.salonDocument];
    [self presentViewControllerAsSheet:self.editSaleViewController];
}
-(void)dismissViewController:(NSViewController *)viewController {
    if (viewController == self.editSaleViewController) {
        if (self.editSaleViewController.editMode == EditModeCreate) {
            if (self.editSaleViewController.cancelled) {
                [self.documentMoc deleteObject:self.editSaleViewController.transaction];
            } else {
                Payment * payment = nil;
                if ([self.editSaleViewController.transaction isKindOfClass:[Sale class]]) {
                    Sale * sale = self.editSaleViewController.transaction;
                    payment = [sale makePaymentInFull];
                } else {
                    payment = self.editSaleViewController.transaction;
                }
                AMCAccountStatementItem * item = [[AMCAccountStatementItem alloc] initWithPayment:payment];
                [self.arrayController addObject:item];
            }
        }
        [self.arrayController rearrangeObjects];
    }
    [super dismissViewController:viewController];
}
- (IBAction)addItem:(id)sender {
    NSAlert * alert = [[NSAlert alloc] init];
    alert.messageText = @"Create a new sale or payment?";
    alert.informativeText = @"Choose whether to create a new payment, sale, or just cancel the operation";
    [alert addButtonWithTitle:@"Payment"];
    [alert addButtonWithTitle:@"Sale"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
        switch (returnCode) {
            case NSAlertFirstButtonReturn:
            {
                // Create payment
                
                Payment * payment = [Payment newObjectWithMoc:self.documentMoc];
                payment.account = self.account;
                [self editNewTransaction:payment];
                break;
            }
            case NSAlertSecondButtonReturn:
            {
                // Create sale
                Sale * sale = [Sale newObjectWithMoc:self.documentMoc];
                sale.account = self.account;
                [self editNewTransaction:sale];
                break;
            }
            default:
                break;
        }
     }];
}
- (IBAction)removeItem:(id)sender {
    NSInteger row = self.dataTable.selectedRow;
    if (row < 0 || row == NSNotFound) {
        return;
    }
    AMCAccountStatementItem * item = self.arrayController.arrangedObjects[row];
    item.payment.voided = @YES;
    [self.arrayController removeObjectAtArrangedObjectIndex:row];
}
-(void)dismissController:(id)sender {
    [self.salonDocument commitAndSave:nil];
    [super dismissController:sender];
}
- (IBAction)recalculate:(id)sender {
    [self reloadData];
}

-(BOOL)writeAccountStatementToFile:(NSString*)filename error:(NSError**)error {
    // Ensure balances are up to date
    [self reloadData];

    // Create column headers
    NSMutableString *csv = [NSMutableString stringWithString:@"Date,Account,Gross Amount,Transaction Fee,Net Amount,Category,Note,Balance"];
    NSNumberFormatter * nf = [[NSNumberFormatter alloc] init];
    nf.numberStyle = NSNumberFormatterDecimalStyle;
    nf.minimumFractionDigits = 2;
    nf.maximumFractionDigits = 2;
    nf.hasThousandSeparators = NO;
    NSDateFormatter * df = [[NSDateFormatter alloc] init];
    df.dateStyle = NSDateFormatterMediumStyle;
    df.timeStyle = NSDateFormatterNoStyle;
    NSString * c = @",";
    for (AMCAccountStatementItem * item in self.statementItems) {
        NSString * date = [df stringFromDate:item.date];
        NSString * account = self.account.friendlyName;
        NSString * grossAmount = [nf stringFromNumber:@(item.amountGross)];
        NSString * fee = [nf stringFromNumber:@(item.transactionFee)];
        NSString * netAmount = [nf stringFromNumber:@(item.amountNet)];
        NSString * category = item.categoryName;
        NSString * note = [item.note stringByReplacingOccurrencesOfString:@"," withString:@" "];
        NSString * balance = [nf stringFromNumber:@(item.balance)];
        [csv appendFormat:@"\n%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@",date,c,account,c,grossAmount,c,fee,c,netAmount,c,category,c,note,c,balance];
    }
    return [csv writeToFile:filename atomically:YES encoding:NSUTF8StringEncoding error:error];
}
- (IBAction)showCashBook:(id)sender {
    self.cashBookViewController.statementItems = self.statementItems;
    self.cashBookViewController.account = self.account;
    self.cashBookViewController.firstDay = self.fromDatePicker.dateValue;
    self.cashBookViewController.lastDay = self.toDatePicker.dateValue;
    self.cashBookViewController.balanceBroughtForward = self.amountBroughtForward;
    self.cashBookViewController.balancePerBank = self.balance;
    self.cashBookViewController.account = self.account;
    [self.cashBookViewController prepareForDisplayWithSalon:self.salonDocument];
    [self presentViewControllerAsSheet:self.cashBookViewController];
}
- (IBAction)reconcileStatement:(id)sender {
    self.bankStatementReconciliationViewController.account = self.account;
    self.bankStatementReconciliationViewController.computerRecords = [self.statementItems mutableCopy];
    [self.bankStatementReconciliationViewController prepareForDisplayWithSalon:self.salonDocument];
    [self presentViewControllerAsSheet:self.bankStatementReconciliationViewController];
}
- (IBAction)recalculateFees:(id)sender {
    for (Account * account in [Account allObjectsWithMoc:self.documentMoc]) {
        if (account == self.salonDocument.salon.cardPaymentAccount) {
            account.transactionFeePercentageIncoming = @(2.75/100.0);
            for (Payment * payment in account.payments) {
                [payment recalculateNetAmountWithFeePercentage:account.transactionFeePercentageIncoming];
            }
        }
        
        for (Sale * sale in account.sales) {
            if (!sale.isQuote.boolValue) {
                [sale makePaymentInFull];
            }
        }
        for (Payment * payment in account.payments) {
            [payment recalculateNetAmountWithFee:payment.transactionFee];
            payment.reconciledWithBankStatement = @NO;
        }
        if (account == self.salonDocument.salon.cardPaymentAccount) {
            for (Payment * payment in account.payments) {
                if (payment.isIncoming) {
                    if (!payment.transactionFee || payment.transactionFee.doubleValue < 0) {
                        NSLog(@"Problem");
                    }
                }
            }
        }
    }
}
- (IBAction)addReconciliationPoint:(id)sender {
    AccountReconciliation * reconciliation = [AccountReconciliation newObjectWithMoc:self.documentMoc];
    reconciliation.actualBalance = @(self.balance);
    reconciliation.reconciliationDate = self.endDate;
    [self.account addReconciliationsObject:reconciliation];
    [self reloadData];
}

@end
