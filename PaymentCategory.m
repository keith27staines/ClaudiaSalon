//
//  PaymentCategory.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 25/01/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

#import "PaymentCategory.h"
#import "AccountingPaymentGroup.h"
#import "Payment.h"
#import "Salon.h"

@implementation PaymentCategory

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
        NSLog(@"Unexpected error while fetching payment categories: %@",error);
    }
    return fetchedObjects;
}
+(NSManagedObject*)createObjectInMoc:(NSManagedObjectContext*)moc
{
    PaymentCategory * paymentCategory = [NSEntityDescription insertNewObjectForEntityForName:@"PaymentCategory" inManagedObjectContext:moc];
    paymentCategory.createdDate = [NSDate date];
    return paymentCategory;
}
@end
