//
//  AMCJobsColumnView.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 26/08/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "AMCJobsColumnView.h"

@implementation AMCJobsColumnView

-(void)stylistChanged:(id)sender {
    [self.delegate jobsColumnView:self selectedStylist:self.stylistPopup.selectedItem.representedObject];
}
@end
