//
//  AMCCompleteAppointmentViewController.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 31/08/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "AMCCompleteAppointmentViewController.h"
#import "AMCConstants.h"
#import "Appointment+Methods.h"
#import "AMCAppointmentCompletionBoilerPlate.h"
#import "AMCAppointmentCompletionBoilerPlate.h"
#import "Note+Methods.h"
#import "AMCSalonDocument.h"

@interface AMCCompleteAppointmentViewController ()
{
    Appointment * _appointment;
    NSMutableDictionary * operationTypesForTitles;
}

@end

static NSString * const kAMCCancelTheOperationButton = @"kAMCCancelTheOperationButton";
static NSString * const kAMCProceedWithOperationButton = @"kAMCProceedWithOperationButton";
static NSString * const kAMCExplanationText = @"kAMCExplanationText";

@implementation AMCCompleteAppointmentViewController

-(NSString *)nibName {
    return @"AMCCompleteAppointmentViewController";
}
-(NSView *)view {
    return [super view];
}
-(void)reloadData {
    [self view];
    [self loadOperationTypePopup];
    [self configureControls];
}
-(Appointment *)appointment {
    return _appointment;
}
-(void)setAppointment:(Appointment *)appointment {
    _appointment = appointment;
    [self view];
    [self loadOperationTypePopup];
    [self configureControls];
}
-(void)loadOperationTypePopup {
    operationTypesForTitles = [NSMutableDictionary dictionary];
    [self.operationTypePopupButton removeAllItems];
    NSString * title= @"";
    
    // AMCompletionTypeNoteCompleted
    title = [self titleForOperationType:AMCompletionTypeNotCompleted];
    [self.operationTypePopupButton addItemWithTitle:title];
    operationTypesForTitles[title] = @(AMCompletionTypeNotCompleted);
    
    // AMCancellationTypeCustomerCancelledLongNotice
    title = [self titleForOperationType:AMCompletionTypeCompletedWithoutConversionToQuote];
    [self.operationTypePopupButton addItemWithTitle:title];
    operationTypesForTitles[title] = @(AMCompletionTypeCompletedWithoutConversionToQuote);
    
    // AMCancellationTypeCustomerCancelledShortNotice
    title = [self titleForOperationType:AMCompletionTypeCompletedWithConversionToQuote];
    [self.operationTypePopupButton addItemWithTitle:title];
    operationTypesForTitles[title] = @(AMCompletionTypeCompletedWithConversionToQuote);
    
    if (self.appointment) {
        title = [self titleForOperationType:AMCompletionTypeCompletedWithConversionToQuote];
        [self selectOperationTypeWithTitle:title];
    }
}
-(NSInteger)selectedOperationType {
    NSString * title = self.operationTypePopupButton.selectedItem.title;
    return [self operationTypeFromTitle:title];
}
-(NSInteger)operationTypeFromTitle:(NSString*)title {
    NSNumber * type = operationTypesForTitles[title];
    return type.integerValue;
}
-(void)selectOperationTypeWithTitle:(NSString*)title {
    [self.operationTypePopupButton selectItemWithTitle:title];
    AMCancellationType cancelType = [self operationTypeFromTitle:title];
    self.explanationText.stringValue = [self explanationForOperationType:cancelType];
    [self configureControlsForOperationType:cancelType];
}
-(void)configureControls {
    NSInteger operationType = [self selectedOperationType];
    [self configureControlsForOperationType:operationType];
}
-(void)configureControlsForOperationType:(NSInteger)operationType {
    NSDictionary * d = [self controlAvailabilityDictionaryForOperationType:operationType];
    [self.noButton setEnabled:((NSNumber*)(d[kAMCCancelTheOperationButton])).boolValue];
    [self.yesButton setEnabled:((NSNumber*)(d[kAMCProceedWithOperationButton])).boolValue];
    [self.explanationText setEnabled:((NSNumber*)(d[kAMCExplanationText])).boolValue];
    self.explanationText.stringValue = [self explanationForOperationType:operationType];
}
-(NSString*)titleForOperationType:(NSInteger)operationType {
    AMCompletionType completionType = operationType;
    switch (completionType) {
        case AMCompletionTypeNotCompleted:
        {
            return @"Appointment has not been completed!";
            break;
        }
        case AMCompletionTypeCompletedWithoutConversionToQuote:
        {
            return @"Appointment completed - create sale manually";
            break;
        }
        case AMCancellationTypeCustomerCancelledShortNotice:
        {
            return @"Appointment completed - create sale automatically";
            break;
        }
    }
}
-(NSString*)explanationForOperationType:(NSInteger)operationType {
    return [AMCAppointmentCompletionBoilerPlate boilerPlateExplanationForCompletionType:operationType];
}
-(NSDictionary*)controlAvailabilityDictionaryForOperationType:(NSInteger)operationType {
    AMCompletionType completionType = operationType;
    NSMutableDictionary * controlAvailability = [@{kAMCCancelTheOperationButton: @(NO),
                                                   kAMCProceedWithOperationButton: @(NO),
                                                   kAMCExplanationText: @(NO)} mutableCopy];
    switch (completionType) {
        case AMCompletionTypeNotCompleted:
        {
            controlAvailability[kAMCCancelTheOperationButton] = @(YES);
            controlAvailability[kAMCProceedWithOperationButton] = @(NO);
            controlAvailability[kAMCExplanationText] = @(NO);
            break;
        }
        case AMCompletionTypeCompletedWithConversionToQuote:
        {
            controlAvailability[kAMCCancelTheOperationButton] = @(YES);
            controlAvailability[kAMCProceedWithOperationButton] = @(YES);
            controlAvailability[kAMCExplanationText] = @(NO);
            break;
        }
        case AMCompletionTypeCompletedWithoutConversionToQuote:
        {
            controlAvailability[kAMCCancelTheOperationButton] = @(YES);
            controlAvailability[kAMCProceedWithOperationButton] = @(YES);
            controlAvailability[kAMCExplanationText] = @(NO);
            break;
        }
    }
    return [controlAvailability copy];
}
- (IBAction)operationTypeChanged:(id)sender {
    [self configureControls];
}
- (IBAction)noButtonClicked:(id)sender {
    self.cancelled = YES;
    [self dismissController:self];
}
- (IBAction)yesButtonClicked:(id)sender {
    self.cancelled = NO;
    Note * note = [Note newObjectWithMoc:self.documentMoc];
    self.appointment.completed = @(YES);
    self.appointment.completionType = @([self selectedOperationType]);
    if ([self.explanationText.stringValue isEqualToString:[AMCAppointmentCompletionBoilerPlate boilerPlateExplanationForCompletionType:[self selectedOperationType]]]) {
        self.appointment.completionNote = self.explanationText.stringValue;
    } else {
        self.appointment.completionNote = @"";
    }
    note.title = @"Appointment was completed";
    note.text = self.explanationText.stringValue;
    [self.appointment addNotesObject:note];
    self.appointment.cancellationNote = @"";
    self.appointment.cancellationType = AMCancellationTypeNotCancelled;
    [self dismissController:self];
}
@end
