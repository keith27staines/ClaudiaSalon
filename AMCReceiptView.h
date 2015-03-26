//
//  AMCReceiptView.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 15/08/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AMCSalonDocument.h"
@class Sale;

@interface AMCReceiptView : NSView

@property Sale * sale;
-(void)printReceipt;
@end
