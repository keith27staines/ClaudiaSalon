//
//  AMCViewController.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 21/02/2015.
//  Copyright (c) 2015 Keith Staines. All rights reserved.
//
@class AMCSalonDocument,BusinessFunction;

#import <Cocoa/Cocoa.h>

@interface AMCViewController : NSViewController

@property BOOL cancelled;
@property (weak) IBOutlet AMCSalonDocument * salonDocument;
@property (weak, readonly) NSManagedObjectContext * documentMoc;
-(void)prepareForDisplayWithSalon:(AMCSalonDocument*)salonDocument;
-(void)reloadData;
-(void)reloadDataMaintainingSelection:(BOOL)maintainSelection;
-(NSString*)editModeVerb;
@property (strong,readonly) BusinessFunction * businessFunction;
@property (readonly) BOOL permissionDeniedNeedsOKButton;
-(IBAction)showRolesToCodeUnitMapping:(id)sender;

@end
