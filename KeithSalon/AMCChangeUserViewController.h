//
//  AMCChangeUserViewController.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 22/06/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "AMCViewController.h"

@interface AMCChangeUserViewController : AMCViewController

@property (weak) IBOutlet NSLayoutConstraint *verticalGap;
@property (weak) IBOutlet NSBox *currentUserBox;
@property (readonly,copy) NSString * switchUserTitle;
-(void)displayCurrentUserBox:(BOOL)displayCurrentUserBox;
@property BOOL authorizingMode;
@end
