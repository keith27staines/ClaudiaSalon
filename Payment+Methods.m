//
//  Payment+Methods.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 23/07/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "Payment+Methods.h"
#import "AMCConstants.h"
#import "Salon+Methods.h"

@implementation Payment (Methods)
+(id)newObjectWithMoc:(NSManagedObjectContext*)moc
{
    Payment * payment = [NSEntityDescription insertNewObjectForEntityForName:@"Payment" inManagedObjectContext:moc];
    NSDate * rightNow = [NSDate date];
    payment.createdDate = rightNow;
    payment.lastUpdatedDate = rightNow;
    payment.paymentDate = rightNow;
    payment.payeeName = @"";
    payment.reason = @"";
    payment.amount = @(0);
    payment.direction = kAMCPaymentDirectionOut;
    payment.paymentCategory = [Salon salonWithMoc:moc].defaultPaymentCategory;
    return payment;
}
+(NSArray*)allObjectsWithMoc:(NSManagedObjectContext*)moc {
    NSArray * array = nil;
    NSFetchRequest * fetch = [NSFetchRequest fetchRequestWithEntityName:@"Payment"];
    array = [moc executeFetchRequest:fetch error:nil];
    return array;
}
+(NSArray*)paymentsBetweenStartDate:(NSDate*)startDate endDate:(NSDate*)endDate withMoc:(NSManagedObjectContext*)moc {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Payment" inManagedObjectContext:moc];
    [fetchRequest setEntity:entity];
    // Specify criteria for filtering which objects to fetch
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"paymentDate <= %@ && paymentDate >= %@ && voided == %@", endDate,startDate,@NO];
    [fetchRequest setPredicate:predicate];
    // Specify how the fetched objects should be sorted
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"paymentDate"
                                                                   ascending:YES];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];
    
    NSError *error = nil;
    NSArray *fetchedObjects = [moc executeFetchRequest:fetchRequest error:&error];
    if (fetchedObjects == nil) {
        [NSApp presentError:error];
    }
    return fetchedObjects;
}
-(NSString*)refundYNString
{
    return (self.refunding)?@"Yes":@"No";
}
-(NSSet*)nonAuditNotes {
    NSMutableSet * nonAuditNotes = [NSMutableSet set];
    for (Note * note in self.notes) {
        if (!note.isAuditNote.boolValue) {
            [nonAuditNotes addObject:note];
        }
    }
    return nonAuditNotes;
}
@end
