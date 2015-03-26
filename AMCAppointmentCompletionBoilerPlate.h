//
//  AMCAppointmentCompletionBoilerPlate.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 30/08/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AMCSalonDocument.h"

@interface AMCAppointmentCompletionBoilerPlate : NSObject
+(NSString*)boilerPlateExplanationForCancellationType:(AMCancellationType)cancellationType;
+(NSString*)boilerPlateExplanationForCompletionType:(AMCompletionType)CompletionType;
@end
