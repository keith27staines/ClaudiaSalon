//
//  AMCPaymentCategoryListViewController.m
//  ClaudiasSalon
//
//  Created by service on 17/01/2015.
//  Copyright (c) 2015 Keith Staines. All rights reserved.
//

#import "AMCPaymentCategoryListViewController.h"

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
@end
