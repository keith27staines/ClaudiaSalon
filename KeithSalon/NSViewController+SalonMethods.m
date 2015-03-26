//
//  NSViewController+SalonMethods.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 23/02/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "NSViewController+SalonMethods.h"
#import "AMCSalonDocument.h"

@implementation NSWindowController (SalonMethods)

-(NSManagedObjectContext*)documentMoc {
    AMCSalonDocument * document = self.document;
    return document.managedObjectContext;
}

@end