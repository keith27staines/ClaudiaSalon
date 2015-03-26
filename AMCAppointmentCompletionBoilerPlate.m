//
//  AMCAppointmentCompletionBoilerPlate.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 30/08/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "AMCAppointmentCompletionBoilerPlate.h"

@implementation AMCAppointmentCompletionBoilerPlate
+(NSString*)boilerPlateExplanationForCompletionType:(AMCompletionType)completionType {
    NSString * explanation;
    switch (completionType) {
        case AMCompletionTypeNotCompleted:
        {
            explanation = @"This appointment has not been completed!";
            break;
        }
        case AMCompletionTypeCompletedWithoutConversionToQuote:
        {
            explanation = @"Sale generated manually";
            break;
        }
        case AMCompletionTypeCompletedWithConversionToQuote:
        {
            explanation = @"Sale generated automatically";
            break;
        }
    }
    return explanation;
}
+(NSString*)boilerPlateExplanationForCancellationType:(AMCancellationType)cancellationType {
    NSString * explanation = @"";
    switch (cancellationType) {
        case AMCancellationTypeNotCancelled:
        {
            explanation = @"This appointment is not cancelled!";
            break;
        }
        case AMCancellationTypeCustomerCancelledLongNotice:
        {
            explanation = @"The customer cancelled but kindly gave us more than 24 hours notice";
            break;
        }
        case AMCancellationTypeCustomerCancelledShortNotice:
        {
            explanation = @"The customer cancelled, giving us less than 24 hours notice";
            break;
        }
        case AMCancellationTypeCustomerNoShow:
        {
            explanation = @"The customer didn't arrive for the appointment and gave us no notice";
            break;
        }
        case AMCancellationTypeSalonUnavailable:
        {
            explanation = @"The salon cancelled the appointment because of a major problem in the Salon: (e.g. general power failure, affecting many services)";
            break;
        }
        case AMCancellationTypeSalonEquipmentFailure:
        {
            explanation = @"The Salon cancelled the appointment because a particular piece of equipment required for the appointment was broken or unavailable: (e.g. Pedicure unit broken)";
            break;
        }
        case AMCancellationTypeSalonStaffAbsence:
        {
            explanation = @"The Salon cancelled the appointment because a required member of staff was unavailable";
            break;
        }
        case AMCancellationTypeOther:
        {
            explanation = @"";
            break;
        }
    }
    return explanation;
}

@end
