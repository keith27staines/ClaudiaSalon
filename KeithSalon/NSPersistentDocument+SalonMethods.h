//
//  NSPersistentDocument+SalonMethods.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 23/02/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSPersistentDocument (SalonMethods)
-(void)deleteObject:(NSManagedObject*)object;
-(BOOL)commitAndSave:(NSError**)error;
-(BOOL)islastUpdateByCurrentUserOnCurrentComputer;
@end
