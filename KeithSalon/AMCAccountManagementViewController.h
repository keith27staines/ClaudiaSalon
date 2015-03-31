//
//  AMCAccountManagementViewController.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 31/03/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "AMCViewController.h"

@interface AMCAccountManagementViewController : AMCViewController

@property (weak) IBOutlet NSButton *isPrimaryAccountCheckbox;
@property (weak) IBOutlet NSButton *isTillAccountCheckbox;
@property (weak) IBOutlet NSButton *isCardPaymentAccountCheckbox;


@end
