//
//  AMCRecurringEventManagementViewController.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 31/03/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "AMCRecurringEventManagementViewController.h"
#import "RecurringItem.h"
#import "Payment+Methods.h"
#import "Salon+Methods.h"
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
    [self tableViewSelectionDidChange:nil];
}
- (IBAction)addRecurringItem:(id)sender {
    RecurringItem * item = [NSEntityDescription insertNewObjectForEntityForName:@"RecurringItem" inManagedObjectContext:self.documentMoc];
    item.createdDate = [NSDate date];
    item.name = @"Payee";
    item.explanation = @"Reason for payment";
    item.period = @(0);
    item.nextActionDate = [NSDate date];
    item.isActive = @(NO);
    item.paymentTemplate = [Payment newObjectWithMoc:self.documentMoc];
    item.paymentTemplate.voided = @(YES);
    item.paymentTemplate.payeeName = item.name;
    item.paymentTemplate.amount = @(1);
    item.paymentTemplate.reason = item.explanation;
    item.paymentTemplate.paymentDate = item.nextActionDate;
    item.paymentTemplate.account = self.salonDocument.salon.primaryBankAccount;
    [self.arrayController addObject:item];
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
    RecurringItem * recurringItem = [self selectedRecurringItem];
    if (recurringItem) {
        Payment * payment = recurringItem.paymentTemplate;
        self.payeeNameField.stringValue = payment.payeeName;
        self.reasonField.stringValue = payment.reason;
        self.amountField.doubleValue = payment.amount.doubleValue;
        [self selectAccount:payment.account];
        [self selectCategory:payment.paymentCategory];
    } else {
        self.payeeNameField.stringValue = @"";
        self.reasonField.stringValue = @"";
        [self.accountPopup selectItemAtIndex:-1];
        [self.categoryPopup selectItemAtIndex:-1];
        self.accountPopup.title = @"Select account";
        self.categoryPopup.title = @"Select category";
    }
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


@end
