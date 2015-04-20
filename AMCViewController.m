//
//  AMCViewController.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 21/02/2015.
//  Copyright (c) 2015 Keith Staines. All rights reserved.
//

#import "AMCViewController.h"
#import "AMCSalonDocument.h"

@interface AMCViewController ()

@end

@implementation AMCViewController


-(NSManagedObjectContext *)documentMoc {
    NSAssert(self.salonDocument, @"Salon is nil");
    return self.salonDocument.managedObjectContext;
}

-(void)reloadData {

}

-(void)prepareForDisplayWithSalon:(AMCSalonDocument*)salonDocument {
    NSAssert(salonDocument, @"The salonDocument should not be nill");
    self.salonDocument = salonDocument;
    [self view];
    [self reloadData];
}

@end
