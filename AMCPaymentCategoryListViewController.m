//
//  AMCPaymentCategoryListViewController.m
//  ClaudiasSalon
//
//  Created by service on 17/01/2015.
//  Copyright (c) 2015 Keith Staines. All rights reserved.
//

#import "AMCPaymentCategoryListViewController.h"
#import "PaymentCategory.h"

@interface AMCPaymentCategoryListViewController ()
@property (weak) IBOutlet NSTableView *dataTable;
@property (strong) IBOutlet NSArrayController *paymentCategoryArrayController;

@end

@implementation AMCPaymentCategoryListViewController

-(NSString *)nibName {
    return @"AMCPaymentCategoryListViewController";
}
-(NSManagedObjectContext *)moc {
    return self.documentMoc;
}
-(void)prepareForDisplayWithSalon:(AMCSalonDocument *)salonDocument {
    [super prepareForDisplayWithSalon:salonDocument];
    [self.dataTable reloadData];
}
-(void)dismissController:(id)sender {
    BOOL defaultCategorySet = NO;
    for (PaymentCategory * category in [PaymentCategory allObjectsWithMoc:self.documentMoc]) {
        if (category.isDefault.boolValue) {
            if (!defaultCategorySet) {
                defaultCategorySet = YES;
                self.salonDocument.salon.defaultPaymentCategoryForPayments = category;
            } else {
                category.isDefault = @(NO);
            }
        }
    }
    self.salonDocument.salon.defaultPaymentCategoryForPayments.isDefault = @(YES);
    [super dismissController:sender];
}
@end
