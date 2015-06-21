//
//  EditObjectViewControllerDelegate.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 21/07/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

@class EditObjectViewController;

#import <Cocoa/Cocoa.h>
#import "AMCSalonDocument.h"
#import "EditObjectViewControllerDelegate.h"

@interface EditObjectViewController : AMCViewController <NSControlTextEditingDelegate>

@property id<EditObjectViewControllerDelegate>delegate;

#pragma mark - Outlets for controls common to all windows
@property (weak) IBOutlet NSTextField * panelTitle;
@property (weak) IBOutlet NSButton * editButton;
@property (weak) IBOutlet NSButton * cancelButton;
@property (weak) IBOutlet NSButton * doneButton;

#pragma mark - Actions for controls common to all windows
-(IBAction)enterEditMode:(NSButton*)sender;
-(IBAction)cancelButton:(NSButton*)sender;
-(IBAction)doneButton:(NSButton*)sender;

#pragma mark - Posible overrides
-(void)enableEditableControls:(BOOL)yn;
-(void)updateObject;
-(NSArray*)editableControls;
-(void)enableDoneButton;

#pragma mark - other properties common to all object editors
@property (weak) id objectToEdit;
@property (copy,readonly) NSString * objectTypeAndName;
@property EditMode editMode;

#pragma mark - validation
-(NSString*)extractPhoneNumber:(NSString*)string;
-(BOOL)validateName:(NSString*)name;
-(BOOL)validatePhoneNumber:(NSString*)possibleNumber;
-(BOOL)validateEmailAddress:(NSString*)possibleAddress;
-(BOOL)isValid;

#pragma mark - helpers not designed to be overriden
-(void)clear;
@end
