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

@interface AMCAccountStatementViewController () <NSTableViewDataSource, NSTableViewDelegate>
{
    NSArray * _payments;
    NSArray * _sales;
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
@property Account * account;
@property (copy,readonly) NSArray * payments;
@property (copy,readonly) NSArray * sales;
@property NSMutableArray * statementItems;

@property (strong) IBOutlet NSArrayController *arrayController;

@property (weak) IBOutlet NSTextField *finalBalance;

@property (weak) IBOutlet NSDatePicker *fromDatePicker;
@property (weak) IBOutlet NSDatePicker *toDatePicker;
@property (strong) IBOutlet AMCCashBookViewController *cashBookViewController;
@property (readonly) NSDate * startDate;
@property (readonly) NSDate * endDate;
@property double balance;
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
    self.fromDatePicker.dateValue = self.fromDatePicker.minDate;
    self.toDatePicker.dateValue = [[NSDate date] endOfDay];
    [self populateAccounts];
    [self reloadData];
    if (!self.accountPopup.selectedItem.representedObject) {
        self.addTransactionButton.enabled = NO;
        self.viewTransactionButton.enabled = NO;
    }
}
-(void)reloadData {
    _sales = nil;
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
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Payment" inManagedObjectContext:self.documentMoc];
        [fetchRequest setEntity:entity];
        // Specify criteria for filtering which objects to fetch
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"account == %@ && voided == %@ && paymentDate >= %@ && paymentDate <= %@", self.account,@NO,self.startDate, self.endDate];
        [fetchRequest setPredicate:predicate];
        // Specify how the fetched objects should be sorted
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createdDate"
                                                                       ascending:YES];
        [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];
        
        NSError *error = nil;
        _payments = [self.documentMoc executeFetchRequest:fetchRequest error:&error];
    }
    
    return [_payments copy];
}
-(NSArray *)sales {
    if (!_sales) {
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Sale" inManagedObjectContext:self.documentMoc];
        [fetchRequest setEntity:entity];
        // Specify criteria for filtering which objects to fetch
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"account == %@ && isQuote == %@ && voided == %@ && createdDate >= %@ && createdDate <= %@", self.account,@NO,@NO,self.startDate,self.endDate];
        [fetchRequest setPredicate:predicate];
        // Specify how the fetched objects should be sorted
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createdDate"
                                                                       ascending:YES];
        [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];
        
        NSError *error = nil;
        _sales = [self.documentMoc executeFetchRequest:fetchRequest error:&error];

    }
    return [_sales copy];
}
- (IBAction)accountChanged:(NSPopUpButton *)sender {
    [self reloadData];
}
-(void)loadAccount {
    self.account = self.accountPopup.selectedItem.representedObject;
    if (!self.account) {
        return;
    }
    self.statementItems = [NSMutableArray array];
    NSArray * transactions = [self.payments copy];
    transactions = [transactions arrayByAddingObjectsFromArray:self.sales];
    for (id object in transactions) {
        AMCAccountStatementItem * statementItem = [[AMCAccountStatementItem alloc] initWithFinancialTransaction:object];
        [self.statementItems addObject:statementItem];
    }
    NSSortDescriptor * sort = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES];
    self.statementItems = [[self.statementItems sortedArrayUsingDescriptors:@[sort]] mutableCopy];
    self.balance = 0;
    for (AMCAccountStatementItem * item in self.statementItems) {
        self.balance += item.amountNet;
        item.balance = self.balance;
    }
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
    self.editSaleViewController.transaction = item.financialTransaction;
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
                AMCAccountStatementItem * item = [[AMCAccountStatementItem alloc] initWithFinancialTransaction:self.editSaleViewController.transaction];
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
        id transaction;
        switch (returnCode) {
            case NSAlertFirstButtonReturn:
            {
                // Create payment
                
                Payment * payment = [Payment newObjectWithMoc:self.documentMoc];
                payment.account = self.account;
                transaction = payment;
                break;
            }
            case NSAlertSecondButtonReturn:
            {
                // Create sale
                Sale * sale = [Sale newObjectWithMoc:self.documentMoc];
                sale.account = self.account;
                transaction = sale;
                break;
            }
            default:
                break;
        }
        if (transaction) {
            [self editNewTransaction:transaction];
        }
     }];
}
- (IBAction)removeItem:(id)sender {
    NSInteger row = self.dataTable.selectedRow;
    if (row < 0 || row == NSNotFound) {
        return;
    }
    AMCAccountStatementItem * item = self.arrayController.arrangedObjects[row];
    if ([item.financialTransaction isKindOfClass:[Sale class]]) {
        Sale * sale = item.financialTransaction;
        sale.voided = @YES;
    } else {
        Payment * payment = item.financialTransaction;
        payment.voided = @YES;
    }
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
    self.cashBookViewController.balanceBroughtForward = 0;
    self.cashBookViewController.balancePerBank = self.balance;
    self.cashBookViewController.account = self.account;
    [self.cashBookViewController prepareForDisplayWithSalon:self.salonDocument];
    [self presentViewControllerAsSheet:self.cashBookViewController];
}
- (IBAction)reconcileStatement:(id)sender {
    [self.bankStatementReconciliationViewController prepareForDisplayWithSalon:self.salonDocument];
    [self presentViewControllerAsSheet:self.bankStatementReconciliationViewController];
}

@end
