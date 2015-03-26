//
//  AMCViewController.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 21/02/2015.
//  Copyright (c) 2015 Keith Staines. All rights reserved.
//
@class AMCSalonDocument;

#import <Cocoa/Cocoa.h>

@interface AMCViewController : NSViewController

@property BOOL cancelled;
@property (weak) IBOutlet AMCSalonDocument * salonDocument;
@property (weak, readonly) NSManagedObjectContext * documentMoc;
-(void)prepareForDisplayWithSalon:(AMCSalonDocument*)salonDocument;
-(void)reloadData;
@end
