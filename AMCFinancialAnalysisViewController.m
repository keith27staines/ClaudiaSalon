//
//  AMCFinancialAnalysisViewController.m
//  ClaudiasSalon
//
//  Created by service on 18/01/2015.
//  Copyright (c) 2015 Keith Staines. All rights reserved.
//

#import "AMCFinancialAnalysisViewController.h"
#import "PaymentCategory.h"
#import "Payment.h"
#import "PaymentCategory.h"
#import "Sale.h"
#import "Account.h"
#import "Customer.h"
#import "NSDate+AMCDate.h"
#import "AMCConstants.h"
#import "EditPaymentViewController.h"

@interface AMCFinancialAnalysisViewController ()
@property PaymentCategory * category;
@property NSArray * data;
@property BOOL salesMode;
@property NSView * contentView;
@property NSDate * fromDate;
@property NSDate * toDate;
@end

@implementation AMCFinancialAnalysisViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.

}
-(NSString *)windowNibName {
    return @"AMCFinancialAnalysisViewController";
}
-(void)prepareForDisplayWithSalon:(AMCSalonDocument *)salonDocument {
    [super prepareForDisplayWithSalon:salonDocument];
    [self viewSelectorChanged:self];
}
-(void)populateCategoryPopup {
    [self.categoryPopup removeAllItems];
    NSMenuItem * menuItem = [[NSMenuItem alloc] init];
    menuItem.title = @"- Select category -";
    [self.categoryPopup.menu addItem:menuItem];
    [self.categoryPopup selectItem:menuItem];
    menuItem = [NSMenuItem separatorItem];
    [self.categoryPopup.menu addItem:menuItem];
    NSArray *fetchedObjects = [PaymentCategory allObjectsWithMoc:self.documentMoc];
    for (PaymentCategory * category in fetchedObjects) {
        NSMenuItem * menuItem = [[NSMenuItem alloc] init];
        menuItem.title = category.categoryName;
        menuItem.representedObject = category;
        [self.categoryPopup.menu addItem:menuItem];
    }
    menuItem = [NSMenuItem separatorItem];
    [self.categoryPopup.menu addItem:menuItem];
    
    menuItem = [[NSMenuItem alloc] init];
    menuItem.title = @"Sales";
    menuItem.representedObject = @"Sales";
    [self.categoryPopup.menu addItem:menuItem];
}
-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.data.count;
}
-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSTableCellView * view = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    if (self.salesMode) {
        [self populateTableCellView:view forColumn:tableColumn sale:self.data[row]];
    } else {
        [self populateTableCellView:view forColumn:tableColumn payment:self.data[row]];
    }
    return view;
}
-(void)populateTableCellView:(NSTableCellView*)view forColumn:(NSTableColumn *)tableColumn sale:(Sale*)sale {
    if ([tableColumn.identifier isEqualToString:@"paymentDate"]) {
        view.textField.stringValue = [sale.createdDate dateStringWithMediumDateFormat];
        return;
    }
    if ([tableColumn.identifier isEqualToString:@"in"]) {
        view.textField.stringValue = [NSString stringWithFormat:@"£%1.2f",sale.actualCharge.doubleValue];
        return;
    }
    if ([tableColumn.identifier isEqualToString:@"out"]) {
        view.textField.stringValue = @"";
        return;
    }
    if ([tableColumn.identifier isEqualToString:@"explanation"]) {
        if (sale.customer) {
            view.textField.stringValue = sale.customer.fullName;
        } else {
            view.textField.stringValue = @"Unrecorded customer";        }
        return;
    }
    if ([tableColumn.identifier isEqualToString:@"payee"]) {
        view.textField.stringValue = (sale.customer)?sale.customer.fullName:@"";
        return;
    }
    if ([tableColumn.identifier isEqualToString:@"account"]) {
        view.textField.stringValue = sale.account.bankName;
        return;
    }
    NSAssert(NO, @"shouldn't get to here");
    return;
}
-(void)populateTableCellView:(NSTableCellView*)view forColumn:(NSTableColumn *)tableColumn payment:(Payment*)payment {
    if ([tableColumn.identifier isEqualToString:@"paymentDate"]) {
        view.textField.stringValue = [payment.paymentDate dateStringWithMediumDateFormat];
        return;
    }
    if ([tableColumn.identifier isEqualToString:@"in"]) {
        if (payment.isIncoming) {
            view.textField.stringValue = [NSString stringWithFormat:@"£%1.2f",payment.amount.doubleValue];
        } else {
            view.textField.stringValue = @"";
        }
        return;
    }
    if ([tableColumn.identifier isEqualToString:@"out"]) {
        if (payment.isOutgoing) {
            view.textField.stringValue = [NSString stringWithFormat:@"£%1.2f",payment.amount.doubleValue];
        } else {
            view.textField.stringValue = @"";
        }
        return;
    }
    if ([tableColumn.identifier isEqualToString:@"explanation"]) {
        view.textField.stringValue = payment.reason;
        return;
    }
    if ([tableColumn.identifier isEqualToString:@"payee"]) {
        if (payment.payeeName) {
            view.textField.stringValue = payment.payeeName;
        } else {
            view.textField.stringValue = @"";
        }
        return;
    }
    if ([tableColumn.identifier isEqualToString:@"account"]) {
        view.textField.stringValue = payment.account.friendlyName;
        return;
    }
    NSAssert(NO, @"shouldn't get to here");
    return;
}
-(void)tableViewSelectionDidChange:(NSNotification *)notification {
    NSInteger row = self.dataTable.selectedRow;
    if (row >= 0) {
        id object = self.data[row];
        if ([object isKindOfClass:[Payment class]]) {
            self.viewPaymentDetailsButton.enabled = YES;
        } else {
            self.viewPaymentDetailsButton.enabled = NO;
        }
    }
}
-(void)reloadSummaryViewData {
    self.startupCostLabel.stringValue = [NSString stringWithFormat:@"£%1.2f",[self calculateStartupCosts]];
    self.directorsLoanLabel.stringValue =  [NSString stringWithFormat:@"£%1.2f",[self calculateDirectorsLoan]];
    NSArray * categories = [PaymentCategory allObjectsWithMoc:self.documentMoc];
    NSMutableArray * summaries = [NSMutableArray array];
    for (PaymentCategory * category in categories) {
        [summaries addObject:[self summaryDictionaryForCategory:category]];
    }
    NSSortDescriptor * sortBalance = [NSSortDescriptor sortDescriptorWithKey:@"out" ascending:NO];
    NSSortDescriptor * sortName = [NSSortDescriptor sortDescriptorWithKey:@"category" ascending:YES];
    [self.summaryArrayController setContent:summaries];
    [self.summaryArrayController setSortDescriptors:@[sortBalance,sortName]];
    [self summarisePeriodFromCategories:categories];
}
-(void)summarisePeriodFromCategories:(NSArray*)categories {
    double expenditure = [self calculateExpenditureFromCategories:categories];
    double sales = [self calculateSales];
    self.expenditureInPeriodLabel.doubleValue = expenditure;
    self.salesInPeriodLabel.doubleValue = sales;
    self.profitInPeriodLabel.doubleValue = sales - expenditure;
}
-(double)calculateExpenditureFromCategories:(NSArray*)categories {
    double balance = 0.0;
    for (PaymentCategory * category in categories) {
        if (category.isDirectorsLoan.boolValue) continue;
        if (category.isStartupCost.boolValue) continue;
        if (category.isTransferBetweenAccounts.boolValue) continue;
        NSNumber * balanceNumber = [self summaryDictionaryForCategory:category][@"balance"];
        balance += balanceNumber.doubleValue;
    }
    return -balance;
}
-(double)calculateSales {
    self.salesMode = YES;
    self.data = [self fetchSales];
    [self.dataTable reloadData];
    double sales = 0;
    for (Sale * sale in self.data) {
        double amount = sale.actualCharge.doubleValue;
        sales += amount;
    }
    return sales;
}
-(double)calculateStartupCosts {
    NSArray * payments = [Payment allObjectsWithMoc:self.documentMoc];
    double startupCost = 0.0;
    for (Payment * payment in payments) {
        if (payment.paymentCategory.isStartupCost.boolValue == YES && payment.voided.boolValue == NO) {
            if (payment.isIncoming) {
                startupCost -= payment.amount.doubleValue;
            } else {
                startupCost += payment.amount.doubleValue;
            }
        }
    }
    return startupCost;
}
-(double)calculateDirectorsLoan {
    NSArray * payments = [Payment allObjectsWithMoc:self.documentMoc];
    double loan = 0.0;
    for (Payment * payment in payments) {
        if (payment.paymentCategory.isDirectorsLoan.boolValue == YES && payment.voided.boolValue == NO) {
            if (payment.isIncoming) {
                loan += payment.amount.doubleValue;
            } else {
                loan -= payment.amount.doubleValue;
            }
        }
    }
    return loan;
}
-(void)reloadCategoryViewData {
    [self populateCategoryPopup];
    [self reloadItemsInSelectedCategory];
}
-(void)reloadItemsInSelectedCategory {
    if (!self.categoryPopup.selectedItem.representedObject) {
        // The selected item is the instruction to select an option
        [self clearDisplayedCategoryData];
        return;
    } else {
        if ([self.categoryPopup.selectedItem.representedObject isKindOfClass:[NSString class]]) {
            // The selected item represents a sale
            [self reloadItemsInSaleCategories];
        } else {
            // The selected item represents a payment category
            [self reloadItemsInPaymentsCategories];
        }
    }
}
-(void)clearDisplayedCategoryData {
    self.data = @[];
    [self.dataTable reloadData];
    self.moneyInLabel.doubleValue = 0;
    self.moneyOutLabel.doubleValue = 0;
    self.balanceLabel.doubleValue = 0;
}
-(void)reloadItemsInSaleCategories {
    self.salesMode = YES;
    self.data = [self fetchSales];
    [self.dataTable reloadData];
    double balance = 0;
    double paymentsIn = 0;
    double paymentsOut = 0;
    for (Sale * sale in self.data) {
        double amount = sale.actualCharge.doubleValue;
        paymentsIn += amount;
        balance += amount;
    }
    self.moneyInLabel.stringValue = [NSString stringWithFormat:@"£%1.2f",paymentsIn];
    self.moneyOutLabel.stringValue = [NSString stringWithFormat:@"£%1.2f",paymentsOut];
    self.balanceLabel.stringValue = [NSString stringWithFormat:@"£%1.2f",balance];
}
-(NSArray*)fetchSales {
    NSManagedObjectContext * moc = self.documentMoc;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Sale" inManagedObjectContext:moc];
    [fetchRequest setEntity:entity];
    // Specify criteria for filtering which objects to fetch
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"voided == %@ and isQuote == %@ and createdDate > %@ and createdDate < %@", @(NO),@(NO),self.fromDate,self.toDate];
    
    [fetchRequest setPredicate:predicate];
    // Specify how the fetched objects should be sorted
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createdDate"
                                                                   ascending:YES];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];
    
    NSError *error = nil;
    NSArray * sales = [moc executeFetchRequest:fetchRequest error:&error];
    if (sales == nil) {
        NSLog(@"Unexpected error: %@",error);
    }
    return sales;
}
-(NSArray*)fetchPayments {
    NSManagedObjectContext * moc = self.documentMoc;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Payment" inManagedObjectContext:moc];
    [fetchRequest setEntity:entity];
    // Specify criteria for filtering which objects to fetch
    NSPredicate *predicate = nil;
    if (self.category) {
        predicate = [NSPredicate predicateWithFormat:@"paymentCategory == %@ AND voided == %@ and paymentDate > %@ and paymentDate < %@", self.category,@(NO),self.fromDate,self.toDate];
    } else {
        predicate = [NSPredicate predicateWithFormat:@"voided == %@ and paymentDate > %@ and paymentDate < %@", @(NO),self.fromDate,self.toDate];
    }
    [fetchRequest setPredicate:predicate];
    // Specify how the fetched objects should be sorted
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"paymentDate"
                                                                   ascending:YES];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];
    
    NSError *error = nil;
    NSArray * payments = [moc executeFetchRequest:fetchRequest error:&error];
    if (self.data == nil) {
        NSLog(@"Unexpected error: %@",error);
    }
    return payments;
}
-(void)reloadItemsInPaymentsCategories {
    self.category = self.categoryPopup.selectedItem.representedObject;
    self.salesMode = NO;
    self.data = [self fetchPayments];
    [self.dataTable reloadData];
    double balance = 0;
    double paymentsIn = 0;
    double paymentsOut = 0;
    for (Payment * payment in self.data) {
        double amount = payment.amount.doubleValue;
        if (payment.isIncoming) {
            paymentsIn += amount;
            balance += amount;
        } else {
            paymentsOut += payment.amount.doubleValue;
            balance -= amount;
        }
    }
    self.moneyInLabel.stringValue = [NSString stringWithFormat:@"£%1.2f",paymentsIn];
    self.moneyOutLabel.stringValue = [NSString stringWithFormat:@"£%1.2f",paymentsOut];
    self.balanceLabel.stringValue = [NSString stringWithFormat:@"£%1.2f",balance];
}

-(NSDictionary*)summaryDictionaryForCategory:(PaymentCategory*)category {
    NSManagedObjectContext * moc = self.documentMoc;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Payment" inManagedObjectContext:moc];
    [fetchRequest setEntity:entity];
    // Specify criteria for filtering which objects to fetch
    NSPredicate * predicate = [NSPredicate predicateWithFormat:@"sale = nil AND paymentCategory == %@ AND voided == %@ and paymentDate > %@ and paymentDate <%@",category,@(NO),self.fromDate,self.toDate];
    [fetchRequest setPredicate:predicate];
    // Specify how the fetched objects should be sorted
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"paymentDate"
                                                                   ascending:YES];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];
    
    NSError *error = nil;
    NSArray * payments = [moc executeFetchRequest:fetchRequest error:&error];
    if (payments == nil) {
        NSLog(@"Unexpected error: %@",error);
    }
    double balance = 0;
    double paymentsIn = 0;
    double paymentsOut = 0;
    for (Payment * payment in payments) {
        double amount = payment.amount.doubleValue;
        if (payment.isIncoming) {
            paymentsIn += amount;
            balance += amount;
        } else {
            paymentsOut += payment.amount.doubleValue;
            balance -= amount;
        }
    }
    return @{@"category":category.categoryName, @"in":@(paymentsIn), @"out":@(paymentsOut), @"balance":@(balance)};
}
-(void)reloadData {
    if (self.viewSelector.selectedSegment == 0) {
        [self reloadCategoryViewData];
    } else {
        [self reloadSummaryViewData];
    }
}
-(void)updateWindowForTimeDependencies {
    if (self.viewSelector.selectedSegment == 0) {
        [self reloadItemsInSelectedCategory];
    } else {
        [self reloadSummaryViewData];
    }
}
- (IBAction)categoryChanged:(id)sender {
    [self reloadItemsInSelectedCategory];
}
- (IBAction)viewSelectorChanged:(id)sender {
    NSView * subView;
    NSDictionary * views;
    NSArray * constraints;
    if (self.contentView) {
        [self.contentView removeFromSuperview];
    }
    NSBox * box;
    if (self.viewSelector.selectedSegment == 0) {
        self.contentView = self.analysisViewController.view;
        box = self.categoryDateRangeBox;
        subView = self.categoryDateRangeViewController.view;
        [self reloadItemsInSelectedCategory];
    } else {
        self.contentView = self.summaryViewController.view;
        box = self.summaryDateRangeBox;
        subView = self.summaryDateRangeViewController.view;
        [self reloadSummaryViewData];
    }
    
    [subView setTranslatesAutoresizingMaskIntoConstraints:NO];
    box.contentView = subView;
    
    views = NSDictionaryOfVariableBindings(subView);
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[subView]|" options:0 metrics:nil views:views];
    [box.superview addConstraints:constraints];
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[subView]|" options:0 metrics:nil views:views];
    [box.superview addConstraints:constraints];

    [self.contentView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.containerView addSubview:self.contentView];
    subView = self.contentView;
    views = NSDictionaryOfVariableBindings(subView);
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[subView]|" options:0 metrics:nil views:views];
    [self.containerView addConstraints:constraints];
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[subView]|" options:0 metrics:nil views:views];
    [self.containerView addConstraints:constraints];
}
-(void)dateRangeSelectorDidChange:(AMCDateRangeSelectorViewController *)dateRangeSelector {
    self.fromDate = dateRangeSelector.fromDate;
    self.toDate = dateRangeSelector.toDate;
    [self updateWindowForTimeDependencies];
}
-(void)dismissViewController:(NSViewController *)viewController {
    if (viewController == self.editPaymentWindowController) {
        NSInteger row = self.dataTable.selectedRow;
        [self reloadItemsInSelectedCategory];
        [self.dataTable  selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    }
    [super dismissViewController:viewController];
}
- (IBAction)viewPaymentsButtonClicked:(id)sender {
    if (self.dataTable.selectedRow < 0) {
        return;
    }
    id objectToEdit = self.data[self.dataTable.selectedRow];
    if ([objectToEdit isKindOfClass:[Payment class]]) {
        self.editPaymentWindowController.objectToEdit = objectToEdit;
        self.editPaymentWindowController.editMode = EditModeView;
        self.editPaymentWindowController.panelTitle.stringValue = @"Edit payment";
        [self.editPaymentWindowController prepareForDisplayWithSalon:self.salonDocument];
        [self presentViewControllerAsSheet:self.editPaymentWindowController];
    }
}
@end
