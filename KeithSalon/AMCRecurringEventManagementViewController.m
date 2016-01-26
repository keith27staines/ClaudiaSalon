//
//  AMCRecurringEventManagementViewController.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 31/03/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "AMCRecurringEventManagementViewController.h"
#import "RecurringItem+Methods.h"
#import "Payment+Methods.h"
#import "Salon.h"
#import "Account+Methods.h"
#import "PaymentCategory+Methods.h"

@interface AMCRecurringEventManagementViewController () <NSTableViewDelegate>
@property (strong) IBOutlet NSArrayController *arrayController;
@property (strong) IBOutlet NSViewController *paymentDetailsViewController;
@property (weak) IBOutlet NSView *detailsContainerView;

@property (weak) IBOutlet NSTextField *payeeNameField;

@property (weak) IBOutlet NSTextField *reasonField;

@property (weak) IBOutlet NSTextField *amountField;
@property (weak) IBOutlet NSPopUpButton *accountPopup;
@property (weak) IBOutlet NSPopUpButton *categoryPopup;
@property (weak) IBOutlet NSPopUpButton *periodPopupButton;

@end

@implementation AMCRecurringEventManagementViewController

-(NSString *)nibName {
    return @"AMCRecurringEventManagementViewController";
}
-(void)prepareForDisplayWithSalon:(AMCSalonDocument *)salonDocument {
    [super prepareForDisplayWithSalon:salonDocument];
    self.paymentDetailsViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    NSView * detailView = self.paymentDetailsViewController.view;
    [self.detailsContainerView addSubview:detailView];
    NSDictionary * views = NSDictionaryOfVariableBindings(detailView);
    [self.detailsContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[detailView]|" options:0 metrics:nil views:views]];
    [self.detailsContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[detailView]" options:0 metrics:nil views:views]];
    [self loadAccountPopup];
    [self loadCategoryPopup];
    [self loadPeriodPopup];
    [self tableViewSelectionDidChange];
}
- (IBAction)addRecurringItem:(id)sender {
    RecurringItem * recurringItem = [NSEntityDescription insertNewObjectForEntityForName:@"RecurringItem" inManagedObjectContext:self.documentMoc];
    recurringItem.isActive = @(NO);
    recurringItem.createdDate = [NSDate date];
    recurringItem.nextActionDate = recurringItem.createdDate;
    recurringItem.period = @(AMCRecurrencePeriodMonthly);

    // We make a voided payment as a template for future payments of this recurring item
    recurringItem.paymentTemplate = [Payment newObjectWithMoc:self.documentMoc];
    recurringItem.paymentTemplate.voided = @(YES);
    recurringItem.paymentTemplate.payeeName = recurringItem.name;
    recurringItem.paymentTemplate.amount = @(0);
    recurringItem.paymentTemplate.direction = kAMCPaymentDirectionOut;
    recurringItem.paymentTemplate.reason = recurringItem.explanation;
    recurringItem.paymentTemplate.paymentDate = recurringItem.nextActionDate;
    recurringItem.paymentTemplate.account = self.salonDocument.salon.primaryBankAccount;

    [self.arrayController addObject:recurringItem];
}
-(void)loadPeriodPopup {
    [self.periodPopupButton removeAllItems];
    for (NSInteger i = 0; i < 3; i++) {
        [self.periodPopupButton insertItemWithTitle:[RecurringItem nameOfReccurencePeriod:i] atIndex:i];
    }
}
-(void)loadAccountPopup {
    [self.accountPopup removeAllItems];
    for (Account * account in [Account allObjectsWithMoc:self.documentMoc]) {
        NSMenuItem * menuItem = [[NSMenuItem alloc] init];
        menuItem.title = account.friendlyName;
        menuItem.representedObject = account;
        [self.accountPopup.menu addItem:menuItem];
    }
}
-(void)loadCategoryPopup {
    [self.categoryPopup removeAllItems];
    for (PaymentCategory * category in [PaymentCategory allObjectsWithMoc:self.documentMoc]) {
        NSMenuItem * menuItem = [[NSMenuItem alloc] init];
        menuItem.title = category.categoryName;
        menuItem.representedObject = category;
        [self.categoryPopup.menu addItem:menuItem];
    }
}
-(void)tableViewSelectionDidChange:(NSNotification *)notification {
    [self tableViewSelectionDidChange];
}
-(void)tableViewSelectionDidChange {
    RecurringItem * recurringItem = [self selectedRecurringItem];
    if (recurringItem) {
        Payment * payment = recurringItem.paymentTemplate;
        [self selectAccount:payment.account];
        [self selectCategory:payment.paymentCategory];
        [self selectPeriod:recurringItem.period.integerValue];
    } else {
        [self.accountPopup selectItemAtIndex:-1];
        [self.categoryPopup selectItemAtIndex:-1];
        [self.periodPopupButton selectItemAtIndex:-1];
        self.accountPopup.title = @"Select account";
        self.categoryPopup.title = @"Select category";
    }
}
-(void)selectPeriod:(AMCRecurrencePeriod)period {
    [self.periodPopupButton selectItemAtIndex:period];
}
-(void)selectAccount:(Account*)account {
    [self.accountPopup selectItemAtIndex:-1];
    for (NSMenuItem * menuItem in self.accountPopup.itemArray) {
        if (menuItem.representedObject == account) {
            [self.accountPopup selectItem:menuItem];
            return;
        }
    }
}
-(void)selectCategory:(PaymentCategory*)category {
    [self.categoryPopup selectItemAtIndex:-1];
    for (NSMenuItem * menuItem in self.categoryPopup.itemArray) {
        if (menuItem.representedObject == category) {
            [self.categoryPopup selectItem:menuItem];
            return;
        }
    }
}
-(RecurringItem*)selectedRecurringItem {
    if (self.arrayController.selectedObjects.count > 0) {
        return self.arrayController.selectedObjects[0];
    }
    return nil;
}
- (IBAction)accountChanged:(id)sender {
    RecurringItem * item = [self selectedRecurringItem];
    item.paymentTemplate.account = self.accountPopup.selectedItem.representedObject;
}
- (IBAction)categoryChanged:(id)sender {
    RecurringItem * item = [self selectedRecurringItem];
    item.paymentTemplate.paymentCategory = self.categoryPopup.selectedItem.representedObject;
}
- (IBAction)periodChanged:(id)sender {
    RecurringItem * item = [self selectedRecurringItem];
    item.period = @(self.periodPopupButton.indexOfSelectedItem);
}

- (IBAction)process:(id)sender {
    [RecurringItem processOutstandingItemsFor:self.documentMoc error:nil];
}

@end
