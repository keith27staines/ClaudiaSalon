//
//  PaymentCategory+Methods.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 19/01/2015.
//  Copyright (c) 2015 Keith Staines. All rights reserved.
//

#import "PaymentCategory+Methods.h"
#import "Salon+Methods.h"

@implementation PaymentCategory (Methods)

+(NSArray*)allObjectsWithMoc:(NSManagedObjectContext*)moc {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"PaymentCategory" inManagedObjectContext:moc];
    [fetchRequest setEntity:entity];
    
    // Specify how the fetched objects should be sorted
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"categoryName"
                                                                   ascending:YES];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];
    
    NSError *error = nil;
    NSArray *fetchedObjects = [moc executeFetchRequest:fetchRequest error:&error];
    if (fetchedObjects == nil) {
        [NSApp presentError:error];
    }
    return fetchedObjects;
}
+(id)newObjectWithMoc:(NSManagedObjectContext*)moc
{
    PaymentCategory * paymentCategory = [NSEntityDescription insertNewObjectForEntityForName:@"PaymentCategory" inManagedObjectContext:moc];
    paymentCategory.createdDate = [NSDate date];
    return paymentCategory;
}
+(PaymentCategory*)paymentWithName:(NSString*)name inMoc:(NSManagedObjectContext*)moc {
    NSArray * allPayments = [PaymentCategory allObjectsWithMoc:moc];
    NSArray * matches = [allPayments filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"categoryName = %@",name]];
    NSAssert(matches.count <= 1, @"Unexpected number of matches");
    return matches.firstObject;
}

-(Salon*)salon {
    return [Salon salonWithMoc:self.managedObjectContext];
}
@end
