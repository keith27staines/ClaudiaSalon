//
//  EditObjectViewControllerDelegate.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 21/07/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "EditObjectViewController.h"
#import "AppDelegate.h"

@interface EditObjectViewController ()
{
    __weak id _objectToEdit;
}
@end

@implementation EditObjectViewController


-(NSString *)objectTypeAndName
{
    [NSException raise:@"Subclasses must override this method" format:@"Subclasses are expected to return the name of the object type they are responsible for editing"];
    return nil;
}
#pragma mark - must override
/**
 *  Override but call this first
 */
-(void)setObjectToEdit:(id)objectToEdit {
    _objectToEdit = objectToEdit;
}
-(void)prepareForDisplayWithSalon:(AMCSalonDocument *)salonDocument
{
    [super prepareForDisplayWithSalon:salonDocument];
    switch (self.editMode) {
        case EditModeView:
        {
            self.panelTitle.stringValue = [NSString stringWithFormat:@"View %@",self.objectTypeAndName];
            [self enableEditableControls:NO];
            [self.editButton setHidden:NO];
            [self.cancelButton setHidden:NO];
            [self.doneButton setHidden:YES];
            break;
        }
        case EditModeCreate:
        {
            self.panelTitle.stringValue = [NSString stringWithFormat:@"New %@",self.objectTypeAndName];
            [self enableEditableControls:YES];
            [self.editButton setHidden:YES];
            [self.cancelButton setHidden:NO];
            [self.doneButton setHidden:NO];
            [self.doneButton setEnabled:NO];
            break;
        }
        case EditModeEdit:
        {
            self.panelTitle.stringValue = [NSString stringWithFormat:@"Edit %@",self.objectTypeAndName];
            [self enableEditableControls:YES];
            [self.editButton setHidden:YES];
            [self.cancelButton setHidden:NO];
            [self.doneButton setHidden:NO];
            break;
        }
    }
    if (self.doneButton.enabled && !self.doneButton.hidden) {
        [self.view.window setDefaultButtonCell:self.doneButton.cell];
    }
}
-(NSArray*)editableControls
{
    return @[];
}
-(void)updateObject
{
    
}
-(void)clear {
    
}
-(void)enableEditableControls:(BOOL)yn
{
    NSArray * allEditControls = [self editableControls];
    for (NSControl * control in allEditControls) {
        if ([control isKindOfClass:[NSTextField class]]) {
            NSTextField * tf = (NSTextField*)control;
            [tf setEditable:yn];
        } else {
            [control setEnabled:yn];
        }
    }
}
#pragma mark - Actions
-(IBAction)enterEditMode:(NSButton*)sender
{
    self.editMode = EditModeEdit;
    [self prepareForDisplayWithSalon:self.salonDocument];
}
-(IBAction)cancelButton:(NSButton*)sender
{
    if (self.editMode == EditModeCreate) {
//        [self.salonDocument deleteObject:self.objectToEdit];
//        self.objectToEdit = nil;
        id delegate = self.delegate;
        if ([delegate respondsToSelector:@selector(editObjectViewController:didCancelObjectCreation:)]) {
            [delegate editObjectViewController:self didCancelObjectCreation:YES];
        }
        if ([delegate respondsToSelector:@selector(editObjectViewController:didCancelCreationOfObject:)]) {
            [delegate editObjectViewController:self didCancelCreationOfObject:self.objectToEdit];
        }
        self.objectToEdit = nil;
    }
    [self dismissController:sender];
}
-(void)dismissController:(id)sender {
    [self.presentingViewController dismissViewController:self];
}
-(IBAction)doneButton:(NSButton*)sender
{
    if (![self.view.window makeFirstResponder:nil]) {
        [self.view.window endEditingFor:nil];
    }
    if (self.editMode == EditModeCreate || self.editMode == EditModeEdit) {
        [self updateObject];
    }
    [self dismissController:sender];
    if (self.editMode == EditModeCreate) {
        [self.delegate editObjectViewController:self didCompleteCreationOfObject:self.objectToEdit];
    }
    if (self.editMode == EditModeEdit) {
        [self.delegate editObjectViewController:self didEditObject:self.objectToEdit];
    }
}
#pragma mark - validation
-(void)enableDoneButton {
    if ([self isValid]) {
        self.doneButton.enabled = YES;
        [self.doneButton.window setDefaultButtonCell:self.doneButton.cell];
    } else {
        self.doneButton.enabled = NO;
    }
}
-(BOOL)isValid {
    return NO;
}
-(NSString*)extractPhoneNumber:(NSString*)string
{
    NSError *error = nil;
    NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypePhoneNumber error:&error];
    __block NSString * phoneNumber = @"";
    [detector enumerateMatchesInString:string
                               options:kNilOptions
                                 range:NSMakeRange(0, [string length])
                            usingBlock:
     ^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
         phoneNumber = result.phoneNumber;
     }];
    return phoneNumber;
}
-(BOOL)validateName:(NSString*)name
{
    if (!name) return NO;
    NSCharacterSet * whiteSpace = [NSCharacterSet whitespaceCharacterSet];
    name = [name stringByTrimmingCharactersInSet:whiteSpace];
    if (name.length == 0) return NO;
    return YES;
}
-(BOOL)validatePhoneNumber:(NSString*)possibleNumber
{
    NSString * phoneNumber = [self extractPhoneNumber:possibleNumber];
    if (phoneNumber || phoneNumber.length == 0) {
        return YES;
    }
    return NO;
}
-(BOOL)validateEmailAddress:(NSString*)possibleAddress
{
    if (!possibleAddress || possibleAddress.length == 0) {
        return YES;
    }

    NSString* pattern = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]+";
    
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", pattern];
    if ([predicate evaluateWithObject:possibleAddress] == YES) {
        return YES;
    } else {
        return NO;
    }
}
#pragma mark - helpers not designed to be overriden
-(id)objectToEdit {
    return _objectToEdit;
}

#pragma mark - Helpers

@end
