//
//  EditObjectViewControllerDelegate.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 24/02/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol EditObjectViewControllerDelegate
@optional
-(void)editObjectViewController:(EditObjectViewController*)controller didCancelObjectCreation:(BOOL)yn;

-(void)editObjectViewController:(EditObjectViewController*)controller didCancelCreationOfObject:(id)object;
-(void)editObjectViewController:(EditObjectViewController *)controller didCompleteCreationOfObject:(id)object;
-(void)editObjectViewController:(EditObjectViewController *)controller didEditObject:(id)object;

@end
