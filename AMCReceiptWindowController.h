//
//  AMCReceiptWindowController.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 15/08/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AMCSalonDocument.h"
#import "AMCReceiptView.h"

@class Sale, AMCReceiptWindowController;

@protocol AMCReceiptPrinterWindowControllerDelegate <NSObject>

-(void)receiptPrinter:(AMCReceiptWindowController*)receiptPrinter didFinishWithPrint:(BOOL)yn;

@end

@interface AMCReceiptWindowController : NSWindowController <NSWindowDelegate>

@property (weak) Sale * sale;

@property (weak) IBOutlet AMCReceiptView *receiptView;
@property (weak) IBOutlet NSButton *printReceiptButton;
@property (weak) IBOutlet NSButton *cancelButton;
- (IBAction)printReceipt:(id)sender;
- (IBAction)cancel:(id)sender;

@property (weak) IBOutlet id<AMCReceiptPrinterWindowControllerDelegate>delegate;

@end
