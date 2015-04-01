//
//  RecurringItem+Methods.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 01/04/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "RecurringItem+Methods.h"
#import "Payment+Methods.h"

@implementation RecurringItem (Methods)

+(void)processOutstandingItemsFor:(NSManagedObjectContext*)moc error:(NSError**)error {
    for (RecurringItem * item in [self outstandingItemsInMoc:moc]) {
        [self processRecurringItem:item];
    }
    return;
}
+(void)processRecurringItem:(RecurringItem*)item {
    if ([item.nextActionDate isGreaterThan:[NSDate date]]) return;
    [self payRecurringBillForItem:item];
    [self updateRecurringItemToNextPeriod:item];
    [self processRecurringItem:item];
}
+(void)updateRecurringItemToNextPeriod:(RecurringItem*)item {
    item.nextActionDate = [self nextRecurrenceForItem:item];
}
+(NSDate*)nextRecurrenceForItem:(RecurringItem*)item {
    AMCRecurrencePeriod period = item.period.integerValue;
    NSDate * nextDate = item.nextActionDate;
    switch (period) {
        case AMCRecurrencePeriodNever: {
            nextDate = [NSDate distantFuture];
            break;
        }
        case AMCRecurrencePeriodWeekly: {
            NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
            NSDateComponents *components = [gregorian components: NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:nextDate];
            components.day = components.day+7;
            nextDate = [gregorian dateFromComponents:components];
            break;
        }
        case AMCRecurrencePeriodMonthly: {
            NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
            NSDateComponents *components = [gregorian components: NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:nextDate];
            components.month = components.month+1;
            nextDate = [gregorian dateFromComponents:components];
            break;
        }
    }
    return nextDate;
}
+(void)payRecurringBillForItem:(RecurringItem*)item {
    if (!item.isActive.boolValue) return;
    if ([item.nextActionDate isGreaterThan:[NSDate date]]) return;
    Payment * paymentTemplate = item.paymentTemplate;
    Payment * newPayment = [Payment newObjectWithMoc:item.managedObjectContext];
    newPayment.createdDate = item.nextActionDate;
    newPayment.paymentDate = item.nextActionDate;
    newPayment.account = paymentTemplate.account;
    newPayment.paymentCategory = paymentTemplate.paymentCategory;
    newPayment.direction = paymentTemplate.direction;
    newPayment.payeeName = paymentTemplate.payeeName;
    newPayment.reason = paymentTemplate.reason;
    newPayment.amount = [paymentTemplate.amount copy];
}
+(NSArray*)outstandingItemsInMoc:(NSManagedObjectContext*)moc {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"RecurringItem" inManagedObjectContext:moc];
    [fetchRequest setEntity:entity];
    // Specify criteria for filtering which objects to fetch
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isActive == %@ AND nextActionDate <= %@", @(YES),[NSDate date]];
    [fetchRequest setPredicate:predicate];
    // Specify how the fetched objects should be sorted
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"nextActionDate"
                                                                   ascending:YES];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];
    
    NSArray *fetchedObjects = [moc executeFetchRequest:fetchRequest error:nil];
    return fetchedObjects;
}
+(NSString*)nameOfReccurencePeriod:(AMCRecurrencePeriod)period {
    switch (period) {
        case AMCRecurrencePeriodNever:
            return @"never";
        case AMCRecurrencePeriodWeekly:
            return @"weekly";
        case AMCRecurrencePeriodMonthly:
            return @"monthly";
    }
}
+(NSString*)nameOfReccurenceAction:(AMCRecurrenceActionType)action {
    switch (action) {
        case AMCRecurrenceActionPayBill:
            return @"pay bill";
    }
}
-(void)setPeriod:(NSNumber *)period {
    [self willChangeValueForKey:@"nameOfRecurrencePeriod"];
    [self willChangeValueForKey:@"period"];
    [self setPrimitiveValue:period forKey:@"period"];
    [self didChangeValueForKey:@"period"];
    [self didChangeValueForKey:@"nameOfRecurrencePeriod"];
}
-(NSString*)nameOfRecurringAction {
    return AMCRecurrenceActionPayBill;
}
-(NSString*)nameOfRecurrencePeriod {
    return [RecurringItem nameOfReccurencePeriod:self.period.integerValue];
}
@end
