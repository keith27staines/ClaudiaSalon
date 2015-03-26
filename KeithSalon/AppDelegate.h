//
//  AppDelegate.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 23/02/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>
-(IBAction)openDefaultSalon:(id)sender;
-(void)attemptApplicationClosureAfter:(NSDate*)date;
-(void)closeApplicationNow;
@end

