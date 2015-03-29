//
//  Salon+Methods.h
//  ClaudiasSalon
//
//  Created by service on 16/09/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

@class AMCSalonDocument;

#import "Salon.h"
#import "AMCConstants.h"

@interface Salon (Methods)
+(Salon*)salonWithMoc:(NSManagedObjectContext*)moc;
@end
