//
//  AMCReceiptWindowController.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 15/08/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "AMCReceiptWindowController.h"
#import "Sale+Methods.h"
#import <Quartz/Quartz.h>

@interface AMCReceiptWindowController ()
{
}
@end

@implementation AMCReceiptWindowController

-(void)showWindow:(id)sender
{
    self.receiptView.sale = self.sale;
    [super showWindow:sender];
}
-(Sale *)sale
{
    return self.receiptView.sale;
}
-(void)setSale:(Sale *)sale
{
    [self window];
    self.receiptView.sale = sale;
}
- (void)windowDidLoad {
    [super windowDidLoad];
}

-(NSString *)windowNibName
{
    return @"AMCReceiptWindowController";
}
- (IBAction)cancel:(id)sender {
    self.sale = nil;
    [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseCancel];
}
- (IBAction)printReceipt:(id)sender {
    [self.receiptView printReceipt];
    self.sale = nil;
    [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseOK];
}

@end
