//
//  AMCAutoCloseViewController.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 04/03/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "AMCAutoCloseViewController.h"
#import "AppDelegate.h"
#import "NSDate+AMCDate.h"

@interface AMCAutoCloseViewController ()
@property (weak) IBOutlet NSTextField *countdownLabel;

@property NSTimer * countdownTimer;
@property NSDate * countdownStart;
@property NSDate * countdownEnd;
@end

@implementation AMCAutoCloseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    self.countdownStart = [NSDate date];
    self.countdownEnd = [self.countdownStart dateByAddingTimeInterval:60];
    self.countdownTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timerFired:) userInfo:nil repeats:YES];
}
-(void)timerFired:(id)sender {
    int timeRemaining = 60 - [[NSDate date] timeIntervalSinceDate:self.countdownStart];
    self.countdownLabel.stringValue = [NSString stringWithFormat:@"%i s",timeRemaining];
    if ([[NSDate date] isGreaterThan:self.countdownEnd]) {
        [self closeNow:self];
    }
}
-(NSString *)nibName {
    return @"AMCAutoCloseViewController";
}
- (IBAction)closeNow:(id)sender {
    [self invalidateTimerAndDismissController];
    [self.appDelegate closeApplicationNow];
}
- (IBAction)postponeByOneHour:(id)sender {
    [self invalidateTimerAndDismissController];
    [self.appDelegate attemptApplicationClosureAfter:[[NSDate date] dateByAddingTimeInterval:3600]];
}
- (IBAction)postponeUntilMidnight:(id)sender {
    [self invalidateTimerAndDismissController];
    [self.appDelegate attemptApplicationClosureAfter:[[NSDate date] endOfDay]];
}
-(void)invalidateTimerAndDismissController {
    [self.countdownTimer invalidate];
    self.countdownTimer = nil;
    [self.view.window close];
}
@end
