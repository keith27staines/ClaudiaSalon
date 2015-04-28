//
//  PaymentCategory+Methods.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 19/01/2015.
//  Copyright (c) 2015 Keith Staines. All rights reserved.
//

#import "PaymentCategory+Methods.h"

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
+(PaymentCategory*)paymentCategoryForSalaryWithMoc:(NSManagedObjectContext*)moc {
    PaymentCategory * salaryCategory = nil;
    NSArray * categories = [self allObjectsWithMoc:moc];
    for (PaymentCategory * category in categories) {
        if ([category.categoryName isEqualToString:@"Salary for self-employed staff"]) {
            category.isSalary = @YES;
        } else {
            category.isSalary = @NO;
        }
        if (category.isSalary.boolValue) {
            salaryCategory = category;
        }
    }
    NSAssert(salaryCategory, @"There is no payment category with the isSalary attribute set");
    return salaryCategory;
}
+(PaymentCategory*)transferCategoryWithMoc:(NSManagedObjectContext*)moc {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"PaymentCategory" inManagedObjectContext:moc];
    [fetchRequest setEntity:entity];
    // Specify criteria for filtering which objects to fetch
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isTransferBetweenAccounts == %@", @YES];
    [fetchRequest setPredicate:predicate];
    NSError *error = nil;
    NSArray *fetchedObjects = [moc executeFetchRequest:fetchRequest error:&error];
    if (fetchedObjects == nil) {
        [NSApp presentError:error];
    }
    if (fetchedObjects.count > 0) {
        return fetchedObjects[0];
    }
    return nil;
}
@end
