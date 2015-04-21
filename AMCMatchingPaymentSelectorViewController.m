//
//  AMCMatchingPaymentSelectorViewController.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 21/04/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "AMCMatchingPaymentSelectorViewController.h"
#import "AMCAccountStatementItem.h"

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
    self.filterPredicate = [NSPredicate predicateWithFormat:@"mismatch = 0"];
    self.statementDateLabel.objectValue = self.transactionDictionary[@"date"];
    self.statementAmountLabel.objectValue = self.transactionDictionary[@"amount"];
}
- (IBAction)okButtonClicked:(id)sender {
    NSInteger row = self.dataTable.selectedRow;
    if (row >= 0) {
        NSDictionary * dictionary = self.arrayController.arrangedObjects[row];
        self.computerRecord = dictionary[@"item"];
        [self dismissController:self];
    }
}
- (IBAction)cancelButtonClicked:(id)sender {
    self.computerRecord = nil;
    [self dismissController:self];
}
- (IBAction)changeFilter:(id)sender {
    switch (self.filterSelector.selectedSegment) {
        case 0: {
            self.filterPredicate = [NSPredicate predicateWithFormat:@"mismatch = 0"];
            break;
        }
        case 1: {
            self.filterPredicate = [NSPredicate predicateWithFormat:@"dateMismatch = 0"];
            break;
        }
        case 2: {
            self.filterPredicate = [NSPredicate predicateWithFormat:@"amountMismatch = 0"];
            break;
        }
        default:
            self.filterPredicate = nil;
            break;
    }
}

@end
