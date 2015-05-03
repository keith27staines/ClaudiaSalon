//
//  AMCMatchingPaymentSelectorViewController.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 21/04/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "AMCMatchingPaymentSelectorViewController.h"
#import "AMCAccountStatementItem.h"
#import "Payment+Methods.h"
#import "Sale+Methods.h"

@interface AMCMatchingPaymentSelectorViewController ()
@property (weak) IBOutlet NSTextField *statementDateLabel;
@property (weak) IBOutlet NSTextField *statementAmountLabel;
@property NSPredicate * filterPredicate;
@property (weak) IBOutlet NSTableView *dataTable;
@property (weak) IBOutlet NSSegmentedControl *filterSelector;
@property (readwrite) AMCAccountStatementItem * computerRecord;
@property (strong) IBOutlet NSArrayController *arrayController;
@end

@implementation AMCMatchingPaymentSelectorViewController

-(NSString *)nibName {
    return @"AMCMatchingPaymentSelectorViewController";
}
-(void)prepareForDisplayWithSalon:(AMCSalonDocument *)salonDocument {
    [super prepareForDisplayWithSalon:salonDocument];
    self.dataTable.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"mismatch" ascending:YES]];
    [self changeFilter:self];
    self.statementDateLabel.objectValue = self.transactionDictionary[@"date"];
    self.statementAmountLabel.objectValue = self.transactionDictionary[@"amount"];
}
- (IBAction)okButtonClicked:(id)sender {
    NSInteger row = self.dataTable.selectedRow;
    if (row >= 0) {
        NSDictionary * dictionary = self.arrayController.arrangedObjects[row];
        self.computerRecord = dictionary[@"item"];
        NSNumber * mismatch = dictionary[@"mismatch"];
        NSNumber * dateMismatch = dictionary[@"dateMismatch"];
        NSNumber * amountMismatch = dictionary[@"amountMismatch"];
        NSNumber * feeMismatch = dictionary[@"feeMismatch"];
        NSNumber * amountNetMismatch = dictionary[@"amountNetMismatch"];
        NSDate * statementDate = self.transactionDictionary[@"date"];
        NSNumber * statementAmount = self.transactionDictionary[@"amount"];
        NSNumber * statementFee = self.transactionDictionary[@"fee"];
        NSNumber * statementAmountNet = self.transactionDictionary[@"amountNet"];
        
        NSDate * itemDate = self.computerRecord.date;
        NSNumber * itemAmount = @(self.computerRecord.signedAmountGross);
        NSNumber * itemFee = @(self.computerRecord.transactionFee);
        NSNumber * itemAmountNet = @(self.computerRecord.signedAmountNet);
        NSDateFormatter * df = [[NSDateFormatter alloc] init];
        df.dateStyle = NSDateFormatterShortStyle;
        df.timeStyle = NSDateFormatterNoStyle;
        NSNumberFormatter * nf = [[NSNumberFormatter alloc] init];
        nf.numberStyle = NSNumberFormatterCurrencyStyle;
        
        if (mismatch.doubleValue != 0) {
            NSAlert * alert = [[NSAlert alloc] init];
            alert.messageText = @"Statement item and computer record disagree";
            if (dateMismatch.doubleValue != 0) {
                alert.informativeText = [alert.informativeText stringByAppendingFormat:@"\n\nStatement date: %@  computer record date: %@",[df stringFromDate:statementDate],[df stringFromDate:itemDate]];
            }
            if (amountMismatch.doubleValue !=0) {
                alert.informativeText = [alert.informativeText stringByAppendingFormat:@"\n\nStatement amount: %@  computer record amount: %@",[nf stringFromNumber:statementAmount],[nf stringFromNumber:itemAmount]];
            }
            if (statementFee && feeMismatch.doubleValue != 0) {
                alert.informativeText = [alert.informativeText stringByAppendingFormat:@"\n\nStatement fee: %@  computer record fee: %@",[nf stringFromNumber:statementFee],[nf stringFromNumber:itemFee]];
            }
            if (statementAmountNet && amountNetMismatch.doubleValue !=0) {
                alert.informativeText = [alert.informativeText stringByAppendingFormat:@"\n\nStatement amount (net): %@  computer record amount (net): %@",[nf stringFromNumber:statementAmountNet],[nf stringFromNumber:itemAmountNet]];
            }
            alert.informativeText = [alert.informativeText stringByAppendingFormat:@"\n\n"];
            [alert addButtonWithTitle:@"Adjust computer record and pair with statement"];
            [alert addButtonWithTitle:@"Cancel"];
            switch ([alert runModal]) {
                case NSAlertFirstButtonReturn: {
                    Payment * payment = self.computerRecord.payment;
                    [self adjustPayment:payment toMatchStatement:self.transactionDictionary];
                    [self dismissController:self];
                    break;
                }
                default:
                    break;
            }
        }
    }
}
-(void)adjustPayment:(Payment*)payment toMatchStatement:(NSMutableDictionary*)transactionDictionary {
    NSDate * statementDate = transactionDictionary[@"date"];
    NSNumber * statementAmount = transactionDictionary[@"amount"];
    double statementAmountValue = statementAmount.doubleValue;
    NSNumber * absoluteAmount = @(fabs(statementAmountValue));
    NSNumber * fee = transactionDictionary[@"fee"];
    NSNumber * absoluteFee = (fee != nil)?@(fabs(fee.doubleValue)):@0;
    payment.direction = (statementAmountValue>=0)?kAMCPaymentDirectionIn:kAMCPaymentDirectionOut;
    payment.createdDate = statementDate;
    payment.paymentDate = statementDate;
    payment.amount = absoluteAmount;
    [payment recalculateNetAmountWithFee:absoluteFee];
    if (payment.sale) {
        payment.sale.createdDate = statementDate;
        payment.sale.actualCharge = absoluteAmount;
    }
}
- (IBAction)cancelButtonClicked:(id)sender {
    self.computerRecord = nil;
    [self dismissController:self];
}
- (IBAction)changeFilter:(id)sender {
    switch (self.filterSelector.selectedSegment) {
        case 0: {
            self.filterPredicate = [NSPredicate predicateWithFormat:@"mismatch = %@ and item.paired = %@",@(0),@NO];
            break;
        }
        case 1: {
            self.filterPredicate = [NSPredicate predicateWithFormat:@"dateMismatch = %@ and item.paired = %@",@(0),@NO];
            break;
        }
        case 2: {
            self.filterPredicate = [NSPredicate predicateWithFormat:@"amountMismatch = %@ and item.paired = %@",@(0),@NO];
            break;
        }
        default:
            self.filterPredicate = [NSPredicate predicateWithFormat:@"item.paired = %@",@NO];
            break;
    }
}

@end
