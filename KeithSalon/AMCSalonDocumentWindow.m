//
//  AMCSalonDocumentWindow.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 30/05/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "AMCSalonDocumentWindow.h"

@implementation AMCSalonDocumentWindow

+ (NSButton *)standardWindowButton:(NSWindowButton)windowButtonKind forStyleMask:(NSUInteger)windowStyle {
    if (windowButtonKind == NSWindowDocumentVersionsButton) {
        return nil;
    }
    return [super standardWindowButton:windowButtonKind forStyleMask:windowStyle];
}

@end
