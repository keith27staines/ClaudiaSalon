//
//  AMCSaleMiniEditorViewController.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 07/03/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "AMCSaleMiniEditorViewController.h"
#import "Sale+Methods.h"
#import "Payment+Methods.h"
#import "Customer+Methods.h"
#import "PaymentCategory+Methods.h"
#import "Account+Methods.h"

@interface AMCSaleMiniEditorViewController ()

@property (weak) IBOutlet NSTextField *header;
@property (weak) IBOutlet NSDatePicker *transactionDate;
@property (weak) IBOutlet NSTextField *transactionDateLabel;

@property (weak) IBOutlet NSPopUpButton *accountSelector;
@property (weak) IBOutlet NSTextField *accountLabel;

@property (weak) IBOutlet NSPopUpButton *categorySelector;
@property (weak) IBOutlet NSTextField *categoryLabel;

@property (weak) IBOutlet NSTextField *amountTextField;
@property (weak) IBOutlet NSTextField *amountLabel;

@property (weak) IBOutlet NSSegmentedControl *directionSelector;

@property (weak) IBOutlet NSTextField *note;
@property (weak) IBOutlet NSTextField *noteLabel;


@property (weak) IBOutlet NSTextField *name;
@property (weak) IBOutlet NSTextField *nameLabel;

@property (weak) IBOutlet NSButton *cancelButton;
@property (weak) IBOutlet NSButton *doneButton;
@property (weak) IBOutlet NSButton * reconciledCheckbox;
@property Sale * sale;
@property Payment * payment;

@property BOOL changesMade;
@end

@implementation AMCSaleMiniEditorViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}
-(NSString *)nibName {
    return @"AMCSaleMiniEditorViewController";
}
-(void)prepareForDisplayWithSalon:(AMCSalonDocument *)salonDocument {
    [super prepareForDisplayWithSalon:salonDocument];
    self.changesMade = NO;
    if ([self.transaction isKindOfClass:[Payment class]]) {
        self.payment = self.transaction;
        self.sale = nil;
    } else {
        self.payment = nil;
        self.sale = self.transaction;
    }
    NSString * header = @"";
    if (self.editMode == EditModeCreate) {
        header = @"Create ";
    } else {
        header = @"Edit ";
    }
    if (self.payment) {
        header = [header stringByAppendingString:@"Payment"];
    } else {
        header = [header stringByAppendingString:@"Sale"];
    }
    self.header.stringValue = header;
    [self loadCategoryPopup];
    [self loadAccountPopup];
    [self resetToObject];
    [self enableControls];
}
-(void)resetToObject {
    if (self.payment) {
        [self selectItemWithRepresentedObject:self.payment.account inPopup:self.accountSelector];
        [self selectItemWithRepresentedObject:self.payment.paymentCategory inPopup:self.categorySelector];
        [self.directionSelector selectSegmentWithTag:([self.payment.direction isEqualToString:kAMCPaymentDirectionIn])?0:1];
        self.reconciledCheckbox.state = (self.payment.isReconciled)?NSOnState:NSOffState;
        self.transactionDate.dateValue = self.payment.paymentDate;
        self.name.stringValue = self.payment.payeeName;
        self.note.stringValue = self.payment.reason;
        self.amountTextField.doubleValue = self.payment.amount.doubleValue;
    } else {
        [self selectItemWithRepresentedObject:self.sale.account inPopup:self.accountSelector];
        [self selectItemWithRepresentedObject:self.salonDocument.salon.defaultPaymentCategoryForSales inPopup:self.categorySelector];
        [self.directionSelector selectSegmentWithTag:0];
        self.reconciledCheckbox.state = NSOffState;
        self.directionSelector.selectedSegment = 1;
        if (self.sale.customer) {
            self.name.stringValue = self.sale.customer.fullName;
        } else {
            self.name.stringValue = @"Unrecorded customer";
        }
        self.note.stringValue = @"";
        self.amountTextField.doubleValue = self.sale.actualCharge.doubleValue;
        self.transactionDate.dateValue = self.sale.createdDate;
    }
    [self enableControls];
}
-(void)enableControls {
    if (self.payment) {
        if (self.editMode == EditModeCreate) {
            self.accountSelector.enabled = self.allowUserToChangeAccount;
            self.accountLabel.enabled = YES;
            self.categorySelector.enabled = YES;
            self.categoryLabel.enabled = YES;
            self.transactionDate.enabled = YES;
            self.transactionDateLabel.enabled = YES;
            self.directionSelector.enabled = YES;
            self.amountTextField.enabled = YES;
            self.amountLabel.enabled = YES;
            self.name.enabled = YES;
            self.nameLabel.enabled = YES;
            self.note.enabled = YES;
            self.noteLabel.enabled = YES;
            self.reconciledCheckbox.enabled = YES;
        } else {
            self.accountSelector.enabled = self.allowUserToChangeAccount;
            self.accountLabel.enabled = YES;
            self.categorySelector.enabled = YES;
            self.categoryLabel.enabled = YES;
            self.transactionDate.enabled = YES;
            self.transactionDateLabel.enabled = YES;
            self.directionSelector.enabled = YES;
            self.amountTextField.enabled = YES;
            self.amountLabel.enabled = YES;
            self.name.enabled = YES;
            self.nameLabel.enabled = YES;
            self.note.enabled = YES;
            self.noteLabel.enabled = YES;
            self.reconciledCheckbox.enabled = YES;
        }
    } else {
        if (self.editMode == EditModeCreate) {
            self.accountSelector.enabled = self.allowUserToChangeAccount;
            self.accountLabel.enabled = YES;
            self.categorySelector.enabled = NO;
            self.categoryLabel.enabled = NO;
            self.transactionDate.enabled = YES;
            self.transactionDateLabel.enabled = YES;
            self.directionSelector.enabled = NO;
            self.amountTextField.enabled = YES;
            self.amountLabel.enabled = YES;
            self.name.enabled = NO;
            self.nameLabel.enabled = NO;
            self.note.enabled = NO;
            self.noteLabel.enabled = NO;
            self.reconciledCheckbox.enabled = NO;
        } else {
            self.accountSelector.enabled = YES;
            self.accountLabel.enabled = YES;
            self.categorySelector.enabled = NO;
            self.categoryLabel.enabled = NO;
            self.transactionDate.enabled = YES;
            self.transactionDateLabel.enabled = YES;
            self.directionSelector.enabled = NO;
            self.amountTextField.enabled = YES;
            self.amountLabel.enabled = YES;
            self.name.enabled = NO;
            self.nameLabel.enabled = NO;
            self.note.enabled = NO;
            self.noteLabel.enabled = NO;
            self.reconciledCheckbox.enabled = NO;
        }
    }
    if ([self isValid] && self.changesMade) {
        self.doneButton.enabled = YES;
    } else {
        self.doneButton.enabled = NO;
    }
}
-(void)updateObject {
    if (self.payment) {
        self.payment.account = self.accountSelector.selectedItem.representedObject;
        self.payment.paymentCategory = self.categorySelector.selectedItem.representedObject;
        self.payment.amount = @(self.amountTextField.doubleValue);
        self.payment.reason = self.note.stringValue;
        self.payment.payeeName = self.name.stringValue;
        self.payment.direction = (self.directionSelector.selectedSegment==0)?kAMCPaymentDirectionIn:kAMCPaymentDirectionOut;
        self.payment.createdDate = self.transactionDate.dateValue;
        self.payment.paymentDate = self.transactionDate.dateValue;
    } else {
        self.sale.actualCharge = @(self.amountTextField.doubleValue);
        self.sale.account = self.accountSelector.selectedItem.representedObject;
        self.sale.createdDate = self.transactionDate.dateValue;
        self.sale.lastUpdatedDate = self.transactionDate.dateValue;
    }
    self.changesMade = YES;
    [self enableControls];
}
-(void)selectItemWithRepresentedObject:(id)object inPopup:(NSPopUpButton*)popup {
    for (NSMenuItem * menuItem in popup.itemArray) {
        if (menuItem.representedObject == object) {
            [popup selectItem:menuItem];
            return;
        }
    }
    [popup selectItem:nil];
    popup.title = @"Sale";
}
-(void)loadCategoryPopup {
    NSArray * categories = [PaymentCategory allObjectsWithMoc:self.documentMoc];
    [self.categorySelector removeAllItems];
    for (PaymentCategory * category in categories) {
        NSMenuItem * menuItem = [[NSMenuItem alloc] init];
        menuItem.representedObject = category;
        menuItem.title = category.categoryName;
        [self.categorySelector.menu addItem:menuItem];
    }
    if (self.editMode == EditModeCreate) {
        NSMenuItem * menuItem = [[NSMenuItem alloc] init];
        menuItem.representedObject = nil;
        menuItem.title = @"Select a category";
        [self.categorySelector.menu addItem:menuItem];
        [self.categorySelector selectItem:menuItem];
    }
}
-(void)loadAccountPopup {
    NSArray * accounts = [Account allObjectsWithMoc:self.documentMoc];
    [self.accountSelector removeAllItems];
    for (Account * account in accounts) {
        NSMenuItem * menuItem = [[NSMenuItem alloc] init];
        menuItem.representedObject = account;
        menuItem.title = account.friendlyName;
        [self.accountSelector.menu addItem:menuItem];
    }
    if (self.editMode == EditModeCreate) {
        NSMenuItem * menuItem = [[NSMenuItem alloc] init];
        menuItem.representedObject = nil;
        menuItem.title = @"Select an account";
        [self.accountSelector.menu addItem:menuItem];
        [self.accountSelector selectItem:menuItem];
    }
}
- (IBAction)transactionInformationChanged:(id)sender {
    if ([self isValid]) {
        [self updateObject];
    }
}
-(BOOL)isValid {
    if (self.payment) {
        if (!self.accountSelector.selectedItem.representedObject ||
            !self.categorySelector.selectedItem.representedObject) {
            return NO;
        }
    } else {
        if (!self.accountSelector.selectedItem.representedObject) {
            return NO;
        }
    }
    if (self.amountTextField.doubleValue <=0) {
        return NO;
    }
    if (self.name.stringValue.length == 0) {
        return NO;
    }
    return YES;
}
- (IBAction)cancelClicked:(id)sender {
    self.cancelled = YES;
    [self.view.window makeFirstResponder:self.view.window];
    [self dismissController:self];
}
- (IBAction)doneClicked:(id)sender {
    if (self.editMode == EditModeCreate && self.sale) {
        [self.sale makePaymentInFull];
    }
    self.cancelled = NO;
    [self.view.window makeFirstResponder:self.view.window];
    [self.salonDocument commitAndSave:nil];
    [self dismissController:self];
}
@end
