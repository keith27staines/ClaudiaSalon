//
//  AMCSaleMiniEditorViewController.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 07/03/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

@class Sale;

#import "AMCViewController.h"
#import "AMCConstants.h"

@interface AMCSaleMiniEditorViewController : AMCViewController
@property EditMode editMode;
@property BOOL allowUserToChangeAccount;
@property id transaction;
@end
