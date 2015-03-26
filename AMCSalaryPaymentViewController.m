//
//  AMCSalaryPaymentViewController.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 29/01/2015.
//  Copyright (c) 2015 Keith Staines. All rights reserved.
//

@class AMCHoursWorkedEachDayOfWeekViewController;

#import "AMCSalaryPaymentViewController.h"
#import "AMCHoursWorkedEachDayOfWeekViewController.h"
#import "AMCHoursWorkedOnDayViewController.h"
#import "WorkRecord+Methods.h"
#import "Salary.h"
#import "Employee+Methods.h"
#import "Payment+Methods.h"
#import "Account+Methods.h"
#import "PaymentCategory+Methods.h"
#import "Sale+Methods.h"
#import "SaleItem+Methods.h"
#import "Service+Methods.h"
#import "NSDate+AMCDate.h"
#import "AMCSalaryCalculator.h"
#import "AMCPaymentAmountViewController.h"
#import "AMCConstants.h"

@interface AMCSalaryPaymentViewController () <NSTableViewDelegate,NSTableViewDataSource>
{
    NSArray * _employees;
    NSInteger _employeeIndex;
    AMCSalaryCalculator * _calculator;
    NSDate * _lastDayOfWeek;
}
@property (weak) IBOutlet NSButton *previousEmployeeButton;
@property (weak) IBOutlet NSButton *nextEmployeeButton;
@property (weak) IBOutlet NSTextField *employeeNameTextField;

@property (weak) IBOutlet NSTextField *daysWorkedTextField;

@property (weak) IBOutlet NSView *amountToPayViewContainer;
@property (strong) IBOutlet NSView *basicPayView;
@property (strong) IBOutlet NSView *percentagePayView;


@property (weak) IBOutlet NSTextField *standardHoursTextField;
@property (weak) IBOutlet NSTextField *extraHoursTextField;

@property (weak) IBOutlet NSTextField *payThisWeekTextField;
@property (weak) IBOutlet NSTextField *amountAlreadyPaid;
@property (weak) IBOutlet NSTextField *amountLeftToPay;

@property (readonly) NSArray * employees;
@property NSInteger employeeIndex;
@property Employee * employee;
@property (nonatomic)  WorkRecord * workRecord;

@property (strong) IBOutlet AMCHoursWorkedEachDayOfWeekViewController *weekViewController;

@property (weak) IBOutlet NSView *weekViewContainer;
@property NSDate * lastDayOfWeek;
@property (readonly) AMCSalaryCalculator * calculator;
@property (weak) IBOutlet NSTextField *totalBonusThisWeek;
@property (weak) IBOutlet NSTableView *bonusTable;
@property (weak) IBOutlet NSTextField *periodToPayLabel;

@property (weak) IBOutlet NSButton *nextPeriodButton;
@property (weak) IBOutlet NSButton *previousPeriodButton;

@property (weak) IBOutlet NSButton *paySalaryFromTillButton;
@property (weak) IBOutlet NSButton *paySalaryFromBankButton;
@property (weak) IBOutlet NSButton *addBonusButton;
@property (weak) IBOutlet NSButton *deleteBonusButton;

@property (strong) IBOutlet AMCPaymentAmountViewController *payAmountViewController;
@property (nonatomic)  NSArray * bonuses;

@property (weak) IBOutlet NSButton *creditBeforeDiscountCheckbox;
@property (weak) IBOutlet NSTextField *creditBeforeDiscountLabel;
@property (strong) IBOutlet NSTextField *valueOfServices;
@property (weak) IBOutlet NSTextField *percentageToEmployeeLabel;
@property (weak) IBOutlet NSTextField *amountToEmployeeLabel;
@property (weak) IBOutlet NSTextField *amountAlreadyPaid2;
@property (weak) IBOutlet NSTextField *amountLeftToPay2;

@end

@implementation AMCSalaryPaymentViewController
-(NSString *)nibName {
    return @"AMCSalaryPaymentViewController";
}
- (IBAction)creditBeforeDiscountCheckboxChanged:(id)sender {
    [self reloadPercentageBasedSalary];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hoursWorkedOnDayChangedNotification:) name:@"hours worked on day changed" object:nil];

    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    self.weekViewController.salonDocument = self.salonDocument;
    [self.weekViewController.view setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.weekViewContainer addSubview:self.weekViewController.view];
    self.employeeIndex = 0;
    self.lastDayOfWeek = [[[NSDate date] lastDayOfWeek] beginningOfDay];
}
-(void)prepareForDisplayWithSalon:(AMCSalonDocument *)salonDocument {
    [super prepareForDisplayWithSalon:salonDocument];
    [self displayEmployee];
}
-(void)hoursWorkedOnDayChangedNotification:(NSNotification*)notification {
    if (self.employee) {
        self.workRecord.hoursWorkedDictionary = self.weekViewController.hoursPerDayDictionary;
        [self displayEmployee];
    }
}
-(AMCSalaryCalculator*)calculator {
    if (!_calculator) {
        _calculator = [[AMCSalaryCalculator alloc] init];
    }
    return _calculator;
}
-(NSInteger)employeeIndex {
    return _employeeIndex;
}
-(NSDate *)lastDayOfWeek {
    if (!_lastDayOfWeek) {
        self.lastDayOfWeek = [[[NSDate date] lastDayOfWeek] beginningOfDay];
    }
    return _lastDayOfWeek;
}
-(void)setLastDayOfWeek:(NSDate *)lastDayOfWeek {
    _lastDayOfWeek = lastDayOfWeek;
    self.weekViewController.endDate = lastDayOfWeek;
    self.workRecord = [self.employee workRecordsForDate:lastDayOfWeek][0];
    self.periodToPayLabel.stringValue = [NSString stringWithFormat:@"Pay salary for week ending %@ %@",[lastDayOfWeek stringNamingDayOfWeek],[lastDayOfWeek dayAndMonthString]];
    self.nextPeriodButton.enabled = [lastDayOfWeek isLessThan:[[NSDate date] lastDayOfWeek]];
    [self displayEmployee];
}
-(WorkRecord *)workRecord {
    if (!_workRecord) {
        _workRecord = [self.employee workRecordsForDate:self.lastDayOfWeek][0];
    }
    return _workRecord;
}
-(void)setEmployeeIndex:(NSInteger)employeeIndex {
    Employee * employee = nil;
    if (employeeIndex < 0) employeeIndex = 0;
    if (self.employees.count > 0) {
        if (employeeIndex < self.employees.count) {
            _employeeIndex = employeeIndex;
            employee = self.employees[employeeIndex];
        } else {
            _employeeIndex = self.employees.count - 1;
            employee = nil;
        }
    } else {
        employeeIndex = -1;
        employee = nil;
    }
    [self.previousEmployeeButton setEnabled:YES];
    [self.nextEmployeeButton setEnabled:YES];
    if (employeeIndex <=0) {
        [self.previousEmployeeButton setEnabled:NO];
    }
    if (employeeIndex >= self.employees.count - 1) {
        [self.nextEmployeeButton setEnabled:NO];
    }
    self.workRecord = nil;
    self.employee = employee;
    self.weekViewController.workRecordTemplate = employee.workRecordTemplate;
    [self displayEmployee];
    [self reloadData];
}
-(void)displayEmployee {
    Employee * employee = self.employee;
    if (!employee) {
        self.employeeNameTextField.stringValue = @"There is no employee to pay";
        return;
    }
    self.employeeNameTextField.stringValue = employee.fullName;
    NSInteger daysWorked = [self.calculator daysWorkedForWorkRecord:self.workRecord];
    double pay = [self.calculator payForWorkRecord:self.workRecord];
    double standardHours = [self.calculator standardHoursWorkedForWorkRecord:self.workRecord];
    double totalExtraHours = [self.calculator extraHoursWorkedForWorkRecord:self.workRecord];
    self.daysWorkedTextField.stringValue = [NSString stringWithFormat:@"Days: %li",daysWorked];
    self.standardHoursTextField.stringValue = [NSString stringWithFormat:@"%1.2f",standardHours];
    self.extraHoursTextField.stringValue = [NSString stringWithFormat:@"%1.2f",totalExtraHours];
    self.payThisWeekTextField.doubleValue = pay;
    self.amountLeftToPay.doubleValue = [self.calculator amountOfPayOutstandingForWorkRecord:self.workRecord];
    self.amountAlreadyPaid.doubleValue = [self.calculator amountPaidForWorkRecord:self.workRecord];
    self.weekViewController.hoursPerDayDictionary = [[self.workRecord hoursWorkedDictionary] mutableCopy];
    [self configureSalaryPaymentButtons];
    [self reloadData];
    NSView * view;
    while (self.amountToPayViewContainer.subviews.count > 0) {
        view = self.amountToPayViewContainer.subviews.firstObject;
        if (view) {
            [view removeFromSuperview];
        }
    }
    if (employee.currentSalary.payByHour.boolValue) {
        view = self.basicPayView;
    } else {
        view = self.percentagePayView;
    }
    view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.amountToPayViewContainer addSubview:view];
    NSDictionary * views = NSDictionaryOfVariableBindings(view);
    [self.amountToPayViewContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[view]-|" options:0 metrics:nil views:views]];
    [self.amountToPayViewContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[view]-|" options:0 metrics:nil views:views]];
    [self reloadPercentageBasedSalary];
}
-(void)reloadPercentageBasedSalary {
    if (self.creditBeforeDiscountCheckbox.state == NSOnState) {
        self.creditBeforeDiscountLabel.stringValue = @"Services BEFORE discounts:";
    } else {
        self.creditBeforeDiscountLabel.stringValue = @"Services AFTER discounts:";
    }
    double percentToEmployee = self.employee.currentSalary.percentage.doubleValue;
    self.percentageToEmployeeLabel.stringValue = [NSString stringWithFormat:@"%@%% to employee:",@(percentToEmployee)];
    double amount = [self creditForEmployee];
    double creditForEmployee = percentToEmployee * amount/100;;
    self.valueOfServices.doubleValue = amount;
    self.amountToEmployeeLabel.doubleValue = creditForEmployee;
    double amountAlreadyPaid = [self.calculator amountPaidForWorkRecord:self.workRecord];
    self.amountAlreadyPaid2.doubleValue = amountAlreadyPaid;
    self.amountLeftToPay2.doubleValue = creditForEmployee - amountAlreadyPaid;
}
-(void)configureSalaryPaymentButtons {
    self.paySalaryFromTillButton.enabled = YES;
    self.paySalaryFromBankButton.enabled = YES;
    if ([self.calculator amountOfPayOutstandingForWorkRecord:self.workRecord] <= 0) {
        self.paySalaryFromTillButton.enabled = NO;
        self.paySalaryFromBankButton.enabled = NO;
    }
}
- (IBAction)nextPeriod:(id)sender {
    self.lastDayOfWeek = [self.lastDayOfWeek dateByAddingTimeInterval:7*24*3600];
    [self displayEmployee];
}

- (IBAction)previousPeriod:(id)sender {
    self.lastDayOfWeek = [self.lastDayOfWeek dateByAddingTimeInterval:-7*24*3600];
    [self displayEmployee];
}

- (IBAction)nextEmployee:(id)sender {
    self.employeeIndex += 1;
    [self displayEmployee];
}
- (IBAction)previousEmployee:(id)sender {
    self.employeeIndex -= 1;
    [self displayEmployee];
}
-(void)dismissController:(id)sender {
    [self.presentingViewController dismissViewController:self];
}
-(NSArray*)employees {
    if (!_employees) {
        NSManagedObjectContext * moc = self.documentMoc;
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Employee" inManagedObjectContext:moc];
        [fetchRequest setEntity:entity];
        // Specify criteria for filtering which objects to fetch
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isActive == %@", @(YES)];
        [fetchRequest setPredicate:predicate];
        // Specify how the fetched objects should be sorted
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"firstName"
                                                                       ascending:YES];
        [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];
        
        NSError *error = nil;
        _employees = [moc executeFetchRequest:fetchRequest error:&error];
        if (_employees == nil) {
            [NSApp presentError:error];
        }
    }
    return _employees;
}

- (IBAction)payFromTill:(id)sender {
    Account * till = [Account accountWithFriendlyName:kAMCTillAccountName withMoc:self.documentMoc];
    [self makePaymentOfAmount:[self.calculator amountOfPayOutstandingForWorkRecord:self.workRecord]
                  fromAccount:till
                  forEmployee:self.employee
                    bonusDate:nil];
    [self displayEmployee];
}
- (IBAction)payFromBank:(id)sender {
    Account * till = [Account accountWithFriendlyName:kAMCBarclaysAccountName withMoc:self.documentMoc];
    [self makePaymentOfAmount:[self.calculator amountOfPayOutstandingForWorkRecord:self.workRecord]
                  fromAccount:till
                  forEmployee:self.employee
                    bonusDate:nil];
    [self displayEmployee];
}
-(void)makePaymentOfAmount:(double)amount fromAccount:(Account*)account forEmployee:(Employee*)employee bonusDate:(NSDate*)bonusDate {
    Payment * payment = [Payment newObjectWithMoc:self.documentMoc];
    payment.account = [Account accountWithFriendlyName:kAMCTillAccountName withMoc:self.documentMoc];
    payment.amount = @(amount);
    payment.payeeName = self.employee.fullName;
    payment.isManagersBudgetItem = self.employee.paidFromManagersBudget;
    if (bonusDate) {
        payment.reason = [NSString stringWithFormat:@"Bonus for %@ %@",[bonusDate stringNamingDayOfWeek], [bonusDate dayAndMonthString]];
    } else {
        payment.reason = [NSString stringWithFormat:@"Remuneraton for week ending %@ %@",[self.lastDayOfWeek stringNamingDayOfWeek], [self.lastDayOfWeek dayAndMonthString]];
    }
    payment.paymentCategory = [PaymentCategory paymentCategoryForSalaryWithMoc:self.documentMoc];
    [self.workRecord addWagesObject:payment];
    NSAlert * alert = [[NSAlert alloc] init];
    alert.messageText = @"Payment has been recorded";
    alert.informativeText = [NSString stringWithFormat:@"A new salary payment has been recorded for %@ and is now visible in the Payments tab",self.employee.fullName];
    [alert beginSheetModalForWindow:self.view.window completionHandler:nil];
}
- (IBAction)addBonus:(id)sender {
    NSButton*button = (NSButton*)sender;
    AMCPaymentAmountViewController * vc = [AMCPaymentAmountViewController new];
    vc.salonDocument = self.salonDocument;
    PaymentCategory * category = [PaymentCategory paymentCategoryForSalaryWithMoc:self.documentMoc];
    Account * account = [Account accountWithFriendlyName:kAMCTillAccountName withMoc:self.documentMoc];
    [vc makePaymentWithTitle:[NSString stringWithFormat:@"Pay bonus to %@",self.employee.fullName] amount:5 allowingLowerPayment:YES inCategory:category fromAccount:account toPayee:self.employee.fullName withReason:@"Bonus for selling services"];
    [self presentViewController:vc asPopoverRelativeToRect:button.bounds ofView:button preferredEdge:NSMaxXEdge behavior:NSPopoverBehaviorTransient];
}
- (IBAction)deleteBonus:(id)sender {
    NSInteger row = [self.bonusTable selectedRow];
    Payment * bonus = self.bonuses[row];
    bonus.voided = @YES;
    [self reloadData];
}
-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.bonuses.count;
}
-(NSArray *)bonuses {
    if (!_bonuses) {
        NSSortDescriptor * sort = [NSSortDescriptor sortDescriptorWithKey:@"paymentDate" ascending:YES];
        _bonuses = [[self.workRecord.bonuses allObjects] sortedArrayUsingDescriptors:@[sort]];
        _bonuses = [_bonuses filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"voided == %@",@NO]];
        self.deleteBonusButton.enabled = (_bonuses.count>0)?YES:NO;
    }
    return _bonuses;
}
-(void)updateBonuesLabel {
    double amount = 0;
    for (Payment * payment in self.bonuses) {
        amount += payment.amount.doubleValue;
    }
    self.totalBonusThisWeek.doubleValue = amount;
}
-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    Payment * bonus = self.bonuses[row];
    if ([tableColumn.identifier isEqualToString:@"paymentDate"]) {
        return bonus.paymentDate;
    }
    if ([tableColumn.identifier isEqualToString:@"amount"]) {
        return bonus.amount;
    }
    if ([tableColumn.identifier isEqualToString:@"account"]) {
        return bonus.account.friendlyName;
    }
    if ([tableColumn.identifier isEqualToString:@"reconciledWithBankStatement"]) {
        return bonus.reconciledWithBankStatement;
    }
    return nil;
}
-(BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    Payment * bonus = self.bonuses[row];
    if (bonus.reconciledWithBankStatement.boolValue) {
        return NO;
    }
    return YES;
}
-(void)tableViewSelectionDidChange:(NSNotification *)notification {
    NSInteger row = [self.bonusTable selectedRow];
    if (row>=0) {
        Payment * bonus = self.bonuses[row];
        self.deleteBonusButton.enabled = (bonus.reconciledWithBankStatement.boolValue)? NO:YES;
    }
}
-(void)dismissViewController:(NSViewController *)viewController {
    AMCPaymentAmountViewController * vc = (AMCPaymentAmountViewController*)viewController;
    Payment * payment = vc.payment;
    if (payment) {
        payment.isManagersBudgetItem = @YES;
        [self.workRecord addBonusesObject:payment];
        [self reloadData];
        NSInteger row = [self.bonuses indexOfObject:payment];
        [self.bonusTable selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    }
    [super dismissViewController:viewController];
}
-(double)creditForEmployee {
    NSDate * endDate = [self.lastDayOfWeek endOfDay];
    NSDate * startDate = [endDate dateByAddingTimeInterval:-7*24*3600];
    NSArray * sales = [self salesInvolvingEmployee:self.employee inPeriodStarting:startDate ending:endDate];
    if (self.creditBeforeDiscountCheckbox.state == NSOnState) {
        return [self creditForEmployee:self.employee fromSales:sales];
    } else {
        return [self creditAfterFullDiscountForEmployee:self.employee fromSales:sales];
    }
}
-(double)creditForEmployee:(Employee*)employee fromSales:(NSArray*)sales {
    double credit = 0;
    for (Sale * sale in sales) {
        if (sale.isQuote.boolValue || sale.voided.boolValue) continue;
        for (SaleItem * saleItem in sale.saleItem) {
            if (saleItem.performedBy == employee) {
                credit += saleItem.nominalCharge.doubleValue;
            }
        }
    }
    return credit;
}
-(double)creditAfterFullDiscountForEmployee:(Employee*)employee fromSales:(NSArray*)sales {
    double credit = 0;
    for (Sale * sale in sales) {
        if (sale.isQuote.boolValue || sale.voided.boolValue) continue;
        for (SaleItem * saleItem in sale.saleItem) {
            if (saleItem.performedBy == employee) {
                credit += [self creditAfterFullDiscountForEmployee:employee forSaleItem:saleItem];
            }
        }
    }
    return credit;
}
-(double)creditAfterFullDiscountForEmployee:(Employee*)employee forSaleItem:(SaleItem*)saleItem {
    
    if (saleItem.performedBy != employee) return 0;

    double individuallyDiscounted = saleItem.actualCharge.doubleValue;
    double fullyDiscounted = individuallyDiscounted;
    Sale * sale = saleItem.sale;
    if (sale.actualCharge.doubleValue < sale.chargeAfterIndividualDiscounts.doubleValue) {
        double extraDiscount = sale.chargeAfterIndividualDiscounts.doubleValue - sale.actualCharge.doubleValue;
        if (extraDiscount > 0) {
            // Take off a portion of the extra discount calculated in strict proportion
            fullyDiscounted -= extraDiscount * saleItem.nominalCharge.doubleValue / sale.nominalCharge.doubleValue;
        }
    }
    return fullyDiscounted;
}
-(NSArray*)salesInvolvingEmployee:(Employee*)employee inPeriodStarting:(NSDate*)startDate ending:(NSDate*)endDate {
    NSArray * allSalesInPeriod = [Sale salesBetweenStartDate:startDate endDate:endDate withMoc:self.documentMoc];
    NSMutableArray * salesForEmployee = [NSMutableArray array];
    for (Sale * sale in allSalesInPeriod) {
        if (sale.voided.boolValue) continue;
        if (sale.isQuote.boolValue) continue;
        for (SaleItem * saleItem in sale.saleItem) {
            if (saleItem.performedBy == employee) {
                [salesForEmployee addObject:sale];
                continue;
            }
        }
    }
    return salesForEmployee;
}
-(void)reloadData {
    self.bonuses = nil;
    [self.bonusTable reloadData];
    [self.bonusTable deselectAll:self];
    self.deleteBonusButton.enabled = NO;
    [self updateBonuesLabel];
}
@end
