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

@property (weak) IBOutlet NSTextField *feeTextField;

@property (weak) IBOutlet NSTextField *amountLabel;

@property (weak) IBOutlet NSSegmentedControl *directionSelector;

@property (weak) IBOutlet NSTextField *note;
@property (weak) IBOutlet NSTextField *noteLabel;


@property (weak) IBOutlet NSTextField *name;
@property (weak) IBOutlet NSTextField *nameLabel;

@property (weak) IBOutlet NSButton *cancelButton;
@property (weak) IBOutlet NSButton *doneButton;
@property (weak) IBOutlet NSButton * reconciledCheckbox;

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
    if (self.editMode == EditModeCreate) {
        self.header.stringValue = @"Create a new payment";
    } else {
        if (self.payment.isReconciled) {
            self.header.stringValue = @"This payment is reconciled";
        } else {
            self.header.stringValue = @"Edit payment";
        }
    }
    [self loadCategoryPopup];
    [self loadAccountPopup];
    [self resetToObject];
    [self enableControls];
}
-(void)resetToObject {
    [self selectItemWithRepresentedObject:self.payment.account inPopup:self.accountSelector];
    [self selectItemWithRepresentedObject:self.payment.paymentCategory inPopup:self.categorySelector];
    [self.directionSelector selectSegmentWithTag:([self.payment.direction isEqualToString:kAMCPaymentDirectionIn])?0:1];
    self.reconciledCheckbox.state = (self.payment.isReconciled)?NSOnState:NSOffState;
    self.transactionDate.dateValue = self.payment.paymentDate;
    self.name.stringValue = self.payment.payeeName;
    self.note.stringValue = self.payment.reason;
    self.amountTextField.doubleValue = self.payment.amount.doubleValue;
    self.feeTextField.doubleValue = self.payment.transactionFee.doubleValue;
    [self enableControls];
}
-(void)enableControls {
    BOOL enabled = !self.payment.isReconciled;
    self.accountSelector.enabled = self.allowUserToChangeAccount & enabled;
    self.accountLabel.enabled = enabled;
    self.categorySelector.enabled = enabled;
    self.categoryLabel.enabled = enabled;
    self.transactionDate.enabled = enabled;
    self.transactionDateLabel.enabled = enabled;
    self.directionSelector.enabled = enabled;
    self.amountTextField.enabled = enabled;
    self.feeTextField.enabled = enabled;
    self.amountLabel.enabled = enabled;
    self.name.enabled = enabled;
    self.nameLabel.enabled = enabled;
    self.note.enabled = enabled;
    self.noteLabel.enabled = enabled;
    if ([self isValid] && self.changesMade) {
        self.doneButton.enabled = YES;
    } else {
        self.doneButton.enabled = NO;
    }
    // The reconciled state is computed and cannot be manually set
    self.reconciledCheckbox.enabled = NO;
}
-(void)updateObject {
    Account * account = self.accountSelector.selectedItem.representedObject;

    self.payment.account = account;
    self.payment.paymentCategory = self.categorySelector.selectedItem.representedObject;
    self.payment.amount = @(self.amountTextField.doubleValue);
    [self.payment recalculateNetAmountWithFee:@(self.feeTextField.doubleValue)];
    self.payment.transactionFee = self.feeTextField.objectValue;
    self.payment.reason = self.note.stringValue;
    self.payment.payeeName = self.name.stringValue;
    self.payment.direction = (self.directionSelector.selectedSegment==0)?kAMCPaymentDirectionIn:kAMCPaymentDirectionOut;
    self.payment.createdDate = self.transactionDate.dateValue;
    self.payment.paymentDate = self.transactionDate.dateValue;

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
    self.cancelled = NO;
    [self.view.window makeFirstResponder:self.view.window];
    [self.salonDocument commitAndSave:nil];
    [self dismissController:self];
}
@end
