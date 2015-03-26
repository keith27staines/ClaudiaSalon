//
//  NSViewController+SalonMethods.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 23/02/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//
@class AMCSalonDocument;

#import <Cocoa/Cocoa.h>

@interface NSWindowController (SalonMethods)
@property (weak) AMCSalonDocument * document;
-(NSManagedObjectContext*)documentMoc;
@end
