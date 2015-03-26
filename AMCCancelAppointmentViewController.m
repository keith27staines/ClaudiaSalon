//
//  AMCCancelAppointmentViewController.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 30/08/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "AMCCancelAppointmentViewController.h"
#import "AMCConstants.h"
#import "Appointment+Methods.h"
#import "Customer+Methods.h"
#import "AMCAppointmentCompletionBoilerPlate.h"
#import "Note+Methods.h"
#import "NSDate+AMCDate.h"
#import "AMCSalonDocument.h"

@interface AMCCancelAppointmentViewController ()
{
    Appointment * _appointment;
    NSMutableDictionary * cancellationTypesForTitles;
}

@end

static NSString * const kAMCNoButton = @"kAMCNoButton";
static NSString * const kAMCYesButton = @"kAMCYesButton";
static NSString * const kAMCExplanationText = @"kAMCExplanationText";

@implementation AMCCancelAppointmentViewController

-(NSString *)nibName {
    return @"AMCCancelAppointmentViewController";
}
-(NSView *)view {
    return [super view];
}
-(void)reloadData {
    [self view];
    [self loadCancellationTypePopup];
    [self configureControls];
}
-(Appointment *)appointment {
    return _appointment;
}
-(void)setAppointment:(Appointment *)appointment {
    _appointment = appointment;
    [self view];
    [self loadCancellationTypePopup];
    [self configureControls];
    if (appointment.cancelled.boolValue) {
        self.titleField.stringValue = @"Reinstate this Appointment?";
        self.noButton.title = @"No";
        self.yesButton.title = @"YES";
    } else {
        self.titleField.stringValue = @"Cancel this Appointment?";
        self.noButton.title = @"No";
        self.yesButton.title = @"YES";
    }
}
-(void)loadCancellationTypePopup {
    cancellationTypesForTitles = [NSMutableDictionary dictionary];
    [self.cancellationTypePopupButton removeAllItems];
    NSString * title= @"";
    
    // AMCancellationTypeNotCancelled
    title = [self titleForCancellationType:AMCancellationTypeNotCancelled];
    [self.cancellationTypePopupButton addItemWithTitle:title];
    cancellationTypesForTitles[title] = @(AMCancellationTypeNotCancelled);
    
    if (!self.appointment.cancelled.boolValue) {
        // AMCancellationTypeCustomerCancelledLongNotice
        title = [self titleForCancellationType:AMCancellationTypeCustomerCancelledLongNotice];
        [self.cancellationTypePopupButton addItemWithTitle:title];
        cancellationTypesForTitles[title] = @(AMCancellationTypeCustomerCancelledLongNotice);
        
        // AMCancellationTypeCustomerCancelledShortNotice
        title = [self titleForCancellationType:AMCancellationTypeCustomerCancelledShortNotice];
        [self.cancellationTypePopupButton addItemWithTitle:title];
        cancellationTypesForTitles[title] = @(AMCancellationTypeCustomerCancelledShortNotice);
        
        // AMCancellationTypeCustomerNoShow
        title = [self titleForCancellationType:AMCancellationTypeCustomerNoShow];
        [self.cancellationTypePopupButton addItemWithTitle:title];
        cancellationTypesForTitles[title] = @(AMCancellationTypeCustomerNoShow);
        
        // AMCancellationTypeSalonUnavailable
        title = [self titleForCancellationType:AMCancellationTypeSalonUnavailable];
        [self.cancellationTypePopupButton addItemWithTitle:title];
        cancellationTypesForTitles[title] = @(AMCancellationTypeSalonUnavailable);
        
        // AMCancellationTypeSalonEquipmentFailure
        title = [self titleForCancellationType:AMCancellationTypeSalonEquipmentFailure];
        [self.cancellationTypePopupButton addItemWithTitle:title];
        cancellationTypesForTitles[title] = @(AMCancellationTypeSalonEquipmentFailure);
        
        // AMCancellationTypeSalonStaffAbsence
        title = [self titleForCancellationType:AMCancellationTypeSalonStaffAbsence];
        [self.cancellationTypePopupButton addItemWithTitle:title];
        cancellationTypesForTitles[title] = @(AMCancellationTypeSalonStaffAbsence);
        
        // AMCancellationTypeOther
        title = [self titleForCancellationType:AMCancellationTypeOther];
        [self.cancellationTypePopupButton addItemWithTitle:title];
        cancellationTypesForTitles[title] = @(AMCancellationTypeOther);
    }
    
    if (self.appointment) {
        if (self.appointment.cancelled.boolValue) {
            AMCancellationType cancelType = AMCancellationTypeNotCancelled;
            title = [self titleForCancellationType:cancelType];
            [self selectCancelTypeWithTitle:title];
        } else {
            AMCancellationType cancelType = AMCancellationTypeCustomerCancelledLongNotice;
            title = [self titleForCancellationType:cancelType];
            [self selectCancelTypeWithTitle:title];
        }
    }
}
-(AMCancellationType)selectedCancellationType {
    NSString * title = self.cancellationTypePopupButton.selectedItem.title;
    return [self cancellationTypeFromTitle:title];
}
-(NSInteger)cancellationTypeFromTitle:(NSString*)title {
    NSNumber * type = cancellationTypesForTitles[title];
    return type.integerValue;
}
-(void)selectCancelTypeWithTitle:(NSString*)title {
    [self.cancellationTypePopupButton selectItemWithTitle:title];
    AMCancellationType cancelType = [self cancellationTypeFromTitle:title];
    self.explanationText.stringValue = [self explanationForCancellationType:cancelType];
    [self configureControlsForCancelType:cancelType];
}
-(void)configureControls {
    AMCancellationType cancelType = [self selectedCancellationType];
    [self configureControlsForCancelType:cancelType];
}
-(void)configureControlsForCancelType:(AMCancellationType)cancelType {
    NSDictionary * d = [self controlAvailabilityDictionaryForCancellationType:cancelType];
    [self.noButton setEnabled:((NSNumber*)(d[kAMCNoButton])).boolValue];
    [self.yesButton setEnabled:((NSNumber*)(d[kAMCYesButton])).boolValue];
    self.explanationText.stringValue = [self explanationForCancellationType:cancelType];
}
-(NSString*)titleForCancellationType:(AMCancellationType)cancellationType {
    switch (cancellationType) {
        case AMCancellationTypeNotCancelled:
        {
            return @"Appointment not cancelled!";
            break;
        }
        case AMCancellationTypeCustomerCancelledLongNotice:
        {
            return @"Customer cancelled with long notice (24 hours or more)";
            break;
        }
        case AMCancellationTypeCustomerCancelledShortNotice:
        {
            return @"Customer cancelled with short notice (less than 24 hours)";
            break;
        }
        case AMCancellationTypeCustomerNoShow:
        {
            return @"Customer failed to arrive";
            break;
        }
        case AMCancellationTypeSalonUnavailable:
        {
            return @"Problem with Salon";
            break;
        }
        case AMCancellationTypeSalonEquipmentFailure:
        {
            return @"Problem with Salon equipment";
            break;
        }
        case AMCancellationTypeSalonStaffAbsence:
        {
            return @"Staff absence";
            break;
        }
        case AMCancellationTypeOther:
        {
            return @"Other reason (specify)";
            break;
        }
    }
}
-(NSString*)explanationForCancellationType:(AMCancellationType)cancellationType {
    return [AMCAppointmentCompletionBoilerPlate boilerPlateExplanationForCancellationType:cancellationType];
}
-(NSDictionary*)controlAvailabilityDictionaryForCancellationType:(AMCancellationType)cancellationType {
    
    NSMutableDictionary * controlAvailability = [@{kAMCNoButton: @(NO),
                                           kAMCYesButton: @(NO),
                                           kAMCExplanationText: @(NO)} mutableCopy];
    switch (cancellationType) {
        case AMCancellationTypeNotCancelled:
        {
            controlAvailability[kAMCNoButton] = @(YES);
            if (self.appointment.cancelled.boolValue) {
                controlAvailability[kAMCYesButton] = @(YES);
            } else {
                controlAvailability[kAMCYesButton] = @(NO);
            }
            controlAvailability[kAMCExplanationText] = @(YES);
            break;
        }
        case AMCancellationTypeCustomerCancelledLongNotice:
        {
            controlAvailability[kAMCNoButton] = @(YES);
            controlAvailability[kAMCYesButton] = @(YES);
            controlAvailability[kAMCExplanationText] = @(YES);
            break;
        }
        case AMCancellationTypeCustomerCancelledShortNotice:
        {
            controlAvailability[kAMCNoButton] = @(YES);
            controlAvailability[kAMCYesButton] = @(YES);
            controlAvailability[kAMCExplanationText] = @(YES);
            break;
        }
        case AMCancellationTypeCustomerNoShow:
        {
            controlAvailability[kAMCNoButton] = @(YES);
            controlAvailability[kAMCYesButton] = @(YES);
            controlAvailability[kAMCExplanationText] = @(YES);
            break;
        }
        case AMCancellationTypeSalonUnavailable:
        {
            controlAvailability[kAMCNoButton] = @(YES);
            controlAvailability[kAMCYesButton] = @(YES);
            controlAvailability[kAMCExplanationText] = @(YES);
            break;
        }
        case AMCancellationTypeSalonEquipmentFailure:
        {
            controlAvailability[kAMCNoButton] = @(YES);
            controlAvailability[kAMCYesButton] = @(YES);
            controlAvailability[kAMCExplanationText] = @(YES);
            break;
        }
        case AMCancellationTypeSalonStaffAbsence:
        {
            controlAvailability[kAMCNoButton] = @(YES);
            controlAvailability[kAMCYesButton] = @(YES);
            controlAvailability[kAMCExplanationText] = @(YES);
            break;
        }
        case AMCancellationTypeOther:
        {
            controlAvailability[kAMCNoButton] = @(YES);
            controlAvailability[kAMCYesButton] = @(YES);
            controlAvailability[kAMCExplanationText] = @(YES);
            break;
        }
    }
    return [controlAvailability copy];
}
- (IBAction)cancellationTypeChanged:(id)sender {
    [self configureControls];
}
- (IBAction)noButtonClicked:(id)sender {
    self.cancelled = YES;
    [self dismissController:self];
}

- (IBAction)yesButtonClicked:(id)sender {
    self.cancelled = NO;
    Note * note = [Note newObjectWithMoc:self.documentMoc];
    note.isAuditNote = @(NO);
    self.appointment.cancellationType = @([self selectedCancellationType]);
    if (self.appointment.cancellationType.integerValue == AMCancellationTypeNotCancelled) {
        note.title = @"Cancelled appointment was reinstated";
        self.appointment.cancelled = @(NO);
    } else {
        note.title = @"Appointment was cancelled";
        self.appointment.cancelled = @(YES);
    }
    if ([self.explanationText.stringValue isEqualToString:[AMCAppointmentCompletionBoilerPlate boilerPlateExplanationForCancellationType:[self selectedCancellationType]]]) {
        self.appointment.cancellationNote = @"";
    } else {
        self.appointment.cancellationNote = self.explanationText.stringValue;
    }
    note.text = [NSString stringWithFormat:@"Appointment on %@ - ",[self.appointment.appointmentDate dateStringWithMediumDateFormatShortTimeFormat]];
    note.text = [note.text stringByAppendingString:self.explanationText.stringValue];
    self.appointment.completed = @(NO);
    self.appointment.completionNote = @"";
    self.appointment.completionType = AMCompletionTypeNotCompleted;
    [self.appointment.customer addNotesObject:note];
    [self.salonDocument commitAndSave:nil];
    [self dismissController:self];
}

@end
