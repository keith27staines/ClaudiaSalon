//
//  AMCSalonDetailsViewController.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 28/03/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "AMCSalonDetailsViewController.h"
#import "Salon.h"
#import "Employee+Methods.h"
#import "Account+Methods.h"
#import "NSDate+AMCDate.h"

@interface AMCSalonDetailsViewController ()
{

}

@property (strong) IBOutlet NSViewController *generalDetailsViewController;

@property (strong) IBOutlet NSViewController *financialDetailsViewController;

@property (strong) IBOutlet NSViewController *openingHoursViewController;
@property NSViewController * currentViewController;

@property (weak) IBOutlet NSSegmentedControl *viewSelector;

@property (weak) IBOutlet NSButton *doneButton;
@property NSArray * addedConstraints;
@property (weak) IBOutlet NSView *containerView;

@property (weak) IBOutlet NSTextField *salonNameField;

@property (weak) IBOutlet NSTextField *salonAddressLine1Field;

@property (weak) IBOutlet NSTextField *salonAddressLine2Field;

@property (weak) IBOutlet NSTextField *postcodeField;

@property (weak) IBOutlet NSTextField *telephoneField;

@property (weak) IBOutlet NSTextField *serviceEmailField;

@property (weak) IBOutlet NSPopUpButton *managerSelectorPopup;

@property (weak) IBOutlet NSDatePicker *startOfAccountingYearDatePicker;

@property (weak) IBOutlet NSDatePicker *firstDayOfTradingDatePicker;

@property (weak) IBOutlet NSPopUpButton *weekStartsOnPopup;
@property (weak) IBOutlet NSPopUpButton *primaryBankAccountPopup;
@property (weak) IBOutlet NSPopUpButton *tillAccountPopup;
@property (weak) IBOutlet NSPopUpButton *cardPaymentAccountPopup;

@end

@implementation AMCSalonDetailsViewController

-(void)viewDidLoad {

    [self addChildViewController:self.generalDetailsViewController];
    [self addChildViewController:self.financialDetailsViewController];
    [self addChildViewController:self.openingHoursViewController];
    self.currentViewController = self.generalDetailsViewController;
    NSView * subview = [self.currentViewController view];
    [subview setFrameOrigin:NSMakePoint(0,0)];
    [self.containerView addSubview:subview];
}

-(NSString *)nibName {
    return @"AMCSalonDetailsViewController";
}
-(void)prepareForDisplayWithSalon:(AMCSalonDocument *)salonDocument {
    [super prepareForDisplayWithSalon:salonDocument];
    [self populateSelectManagerPopup];
    [self populateAccountSelectorPopup:self.tillAccountPopup selectAccount:self.salonProperties.tillAccount];
    [self populateAccountSelectorPopup:self.cardPaymentAccountPopup selectAccount:self.salonProperties.cardPaymentAccount];
    [self populateAccountSelectorPopup:self.primaryBankAccountPopup selectAccount:self.salonProperties.primaryBankAccount];
    [self populateWeekStartsOnPopup];
    self.firstDayOfTradingDatePicker.dateValue = self.salonProperties.firstDayOfTrading;
    self.startOfAccountingYearDatePicker.dateValue = self.salonProperties.startOfAccountingYear;
}
- (IBAction)selectView:(NSSegmentedControl *)sender {
    NSInteger newSegment = sender.selectedSegment;
    NSViewController * vc;
    switch (newSegment) {
        case 0: {
            vc = self.generalDetailsViewController;
            break;
        }
        case 1: {
            vc = self.financialDetailsViewController;
            break;
        }
        case 2: {
            vc = self.openingHoursViewController;
            break;
        }
        default:
        {
            vc = self.generalDetailsViewController;
            break;
        }
    }
    if (vc != self.currentViewController) {
        NSUInteger transition;
        if ([self segmentForViewController:self.currentViewController] > newSegment) {
            transition = NSViewControllerTransitionSlideRight;
        } else {
            transition = NSViewControllerTransitionSlideLeft;
        }
        [self transitionFromViewController:self.currentViewController toViewController:vc options:transition completionHandler:^{
            self.currentViewController = vc;
        }];
    }
}
-(NSInteger)segmentForViewController:(NSViewController*)vc {
    if (vc == self.generalDetailsViewController) {
        return 0;
    }
    if (vc == self.financialDetailsViewController) {
        return 1;
    }
    if (vc == self.openingHoursViewController) {
        return 2;
    }
    return 0;
}
-(void)populateSelectManagerPopup {
    [self.managerSelectorPopup removeAllItems];
    NSMenuItem * menuItem;
    if (!self.salonProperties.manager) {
        menuItem = [[NSMenuItem alloc] init];
        menuItem.title = @"Select the Salon Manager";
        [self.managerSelectorPopup.menu addItem:menuItem];
        [self.managerSelectorPopup selectItem:menuItem];
    }
    for (Employee * employee in [self activeEmployees]) {
        menuItem = [[NSMenuItem alloc] init];
        menuItem.title = employee.fullName;
        menuItem.representedObject = employee;
        [self.managerSelectorPopup.menu addItem:menuItem];
        if (employee == self.salonProperties.manager) {
            [self.managerSelectorPopup selectItem:menuItem];
        }
    }
}
-(void)populateWeekStartsOnPopup {
    [self.weekStartsOnPopup removeAllItems];
    for (int i = 1; i < 8; i++) {
        NSMenuItem * menuItem = [[NSMenuItem alloc] init];
        NSString * dayName = [NSDate stringNamingDayOfWeek:i];
        menuItem.title = dayName;
        menuItem.representedObject = @(i);
        [self.weekStartsOnPopup.menu addItem:menuItem];
        if (i == self.salonDocument.salon.firstDayOfWeek.integerValue) {
            [self.weekStartsOnPopup selectItem:menuItem];
        }
    }
}
-(void)populateAccountSelectorPopup:(NSPopUpButton*)popup selectAccount:(Account*)selectAccount {
    [popup removeAllItems];
    NSMenuItem * menuItem;
    if (!selectAccount) {
        menuItem = [[NSMenuItem alloc] init];
        menuItem.title = @"Select Account";
        [popup.menu addItem:menuItem];
        [popup selectItem:menuItem];
    }
    for (Account * account in [self accounts]) {
        menuItem = [[NSMenuItem alloc] init];
        menuItem.title = account.friendlyName;
        menuItem.representedObject = account;
        [popup.menu addItem:menuItem];
        if (account == selectAccount) {
            [popup selectItem:menuItem];
        }
    }
}
-(NSArray*)accounts {
    return [Account allObjectsWithMoc:self.documentMoc];
}
-(NSArray*)activeEmployees {
    return  [Employee allActiveEmployeesWithMoc:self.documentMoc];
}
- (IBAction)managerChanged:(id)sender {
    self.salonProperties.manager = self.managerSelectorPopup.selectedItem.representedObject;
}

- (IBAction)primaryBankAccountChanged:(id)sender {
    self.salonProperties.primaryBankAccount = self.primaryBankAccountPopup.selectedItem.representedObject;
}
- (IBAction)tillAccountChanged:(id)sender {
    self.salonProperties.tillAccount = self.tillAccountPopup.selectedItem.representedObject;
}

- (IBAction)cardPaymentAccountChanged:(id)sender {
    self.salonProperties.cardPaymentAccount = self.cardPaymentAccountPopup.selectedItem.representedObject;
}

- (IBAction)weekStartDayChanged:(id)sender {
    self.salonProperties.firstDayOfWeek = self.weekStartsOnPopup.selectedItem.representedObject;
}

- (IBAction)accountingYearChanged:(id)sender {
    self.salonProperties.startOfAccountingYear = self.startOfAccountingYearDatePicker.dateValue;
}
- (IBAction)firstDayOfTradingChanged:(id)sender {
    self.salonProperties.firstDayOfTrading = self.firstDayOfTradingDatePicker.dateValue;
}






















@end
