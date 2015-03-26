//
//  AMCObjectWithNotesProtocol.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 29/08/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AMCSalonDocument.h"
#import "Note.h"

@protocol AMCObjectWithNotesProtocol <NSObject>
-(void)addNotesObject:(Note*)note;
-(void)removeNotesObject:(Note*)note;
-(NSSet*)notes;
-(NSSet*)nonAuditNotes;
@end
