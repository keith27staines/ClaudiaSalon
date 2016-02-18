//
//  AMCReportsViewController.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 21/08/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "AMCReportsViewController.h"
#import "AMCConstants.h"
#import "Sale+Methods.h"
#import "SaleItem+Methods.h"
#import "Payment+Methods.h"
#import "Service+Methods.h"
#import "ServiceCategory+Methods.h"
#import "NSDate+AMCDate.h"
#import "Salon.h"
#import "ClaudiaSalon-Swift.h"

@interface AMCReportsViewController ()
{
    NSMutableArray * _reportData;
}
@property NSMutableArray * categories;
@property (readonly) NSMutableArray * reportData;
@property NSOperationQueue * workQueue;
@property AMCReportWorkerOperation * workerOperation;
@end

@implementation AMCReportsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    return self;
}
-(NSString *)nibName
{
    return @"AMCReportsViewController";
}
-(void)dismissController:(id)sender  {
    [self.workQueue cancelAllOperations];
    [super dismissController:sender];
}
-(void)viewDidLoad {
    self.workQueue = [[NSOperationQueue alloc] init];
    self.workQueue.qualityOfService = NSQualityOfServiceUserInteractive;
}
-(void)viewDidDisappear {
    [self.workQueue cancelAllOperations];
}
#pragma mark - "PermissionDenied" Delegate
-(BOOL)permissionDeniedNeedsOKButton {
    return NO;
}
- (IBAction)reportPeriodChanged:(id)sender {
    [self reloadData];
}
- (IBAction)yearStartChanged:(id)sender {
    [self reloadData];
}
- (IBAction)monthStartChanged:(id)sender {
    [self reloadData];
}
- (IBAction)weekStartChanged:(id)sender {
    [self reloadData];
}
-(void)reloadData
{
    if (self.workerOperation) {
        [self.workerOperation cancel];
    }
    _reportData = nil;
    [self loadReportDataPlaceholders];
    [self.reportTable reloadData];
    [self loadReportDataDetail];
}

-(NSMutableArray*)loadReportDataPlaceholders {
    if (_reportData) return _reportData;
    _reportData = [NSMutableArray array];
    NSDate * startDate = [self currentPeriodStartDate];
    NSDate * endDate = [self endDateFromStartDate:startDate];
    NSDate * earliestDate = [self earliestDate];
    double salesTotal = 0;
    double paymentsTotal = 0;
    double hairTotal = 0;
    double beautyTotal = 0;
    while ([endDate isGreaterThan:earliestDate]) {
        NSDictionary * data = @{@"date": startDate,@"hairCategories":@(hairTotal), @"beautyCategories":@(beautyTotal) ,@"allCategories":@(salesTotal), @"payments": @(paymentsTotal), @"profits":@(salesTotal - paymentsTotal)};
        [_reportData addObject:data];
        startDate = [self previousStartDate:startDate];
        endDate = [self endDateFromStartDate:startDate];
    }
    return _reportData;
}
-(void)loadReportDataDetail {
    id strongSelf = self;
    NSDate * startDate = [self currentPeriodStartDate];
    NSDate * endDate = [self endDateFromStartDate:startDate];
    NSDate * earliestDate = [self earliestDate];

    self.workerOperation = [[AMCReportWorkerOperation alloc] initWithStartDate:startDate endDate:endDate earliestDate:earliestDate parentMoc:self.salonDocument.managedObjectContext reportingInterval:self.reportingInterval];
    
    self.workerOperation.subIntervalCompletionBlock = ^void(NSInteger row, NSDictionary*dictionary){
        dispatch_async(dispatch_get_main_queue(), ^{
            [strongSelf updateRow:row withDictionary:dictionary];
        });
    };
    [self.workQueue addOperation:self.workerOperation];
}
-(void)updateRow:(NSInteger)row withDictionary:(NSDictionary*)dictionary {
    if (self.workerOperation.cancelled) return;
    _reportData[row] = dictionary;
    NSRange columnRange = NSMakeRange(0, 7);
    NSIndexSet * columnsSet = [NSIndexSet indexSetWithIndexesInRange:columnRange];
    [self.reportTable reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:row] columnIndexes:columnsSet];
}
-(NSArray*)paymentsAtOrAfter:(NSDate*)after before:(NSDate*)before
{
    NSManagedObjectContext * moc = self.documentMoc;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Payment" inManagedObjectContext:moc];
    [fetchRequest setEntity:entity];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"paymentDate >= %@ and paymentDate < %@", after,before];
    [fetchRequest setPredicate:predicate];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"paymentDate" ascending:YES];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];
    NSArray *fetchedObjects = [moc executeFetchRequest:fetchRequest error:nil];
    return fetchedObjects;
}
-(NSArray*)salesAtOrAfter:(NSDate*)after before:(NSDate*)before
{
    NSManagedObjectContext * moc = self.documentMoc;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Sale" inManagedObjectContext:moc];
    [fetchRequest setEntity:entity];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"createdDate >= %@ and createdDate < %@ and isQuote == %@", after,before,@(NO)];
    [fetchRequest setPredicate:predicate];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createdDate" ascending:YES];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];
    NSArray *fetchedObjects = [moc executeFetchRequest:fetchRequest error:nil];
    return fetchedObjects;
}
-(NSDictionary*)reportLineForStartDate:(NSDate*)startDate endDate:(NSDate*)endDate
{
    return @{@"startDate": startDate, @"all":@(70)};
}
-(NSDate*)currentPeriodStartDate
{
    NSDate * now = [NSDate date];
    switch ([self reportingInterval]) {
        case AMCReportingIntervalDaily:
        {
            return [self beginningOfDayOnDate:now];
            break;
        }
        case AMCReportingIntervalWeekly:
        {
            return [self beginningOfWeek:now];
            break;
        }
        case AMCReportingIntervalMonthly:
        {
            return [self beginningOfMonth:now];
            break;
        }
        case AMCReportingIntervalYearly:
        {
            return [self beginningOfYear:now];
            break;
        }
    }
    return [NSDate date];
}
-(NSDate*)beginningOfYear:(NSDate*)date
{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents * dcDate = [gregorian components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:date];
    NSDateComponents * yearEnd = [gregorian components:(NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:self.yearStartStepper.dateValue];
    dcDate.month = yearEnd.month;
    dcDate.day = yearEnd.day;
    NSDate * firstOfYear = [gregorian dateFromComponents:dcDate];
    if ([firstOfYear isGreaterThan:date]) {
        firstOfYear = [gregorian dateByAddingUnit:NSCalendarUnitYear value:-1 toDate:firstOfYear options:NSCalendarWrapComponents];
    }
    return [self beginningOfDayOnDate:firstOfYear];
}
-(NSDate*)beginningOfMonth:(NSDate*)date
{
    NSCalendar *gregorian = [[NSCalendar alloc]
                             initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents * dc = [gregorian components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:date];
    dc.day = self.monthStartPopup.indexOfSelectedItem + 1;
    NSDate * firstOfMonth = [gregorian dateFromComponents:dc];
    if ([firstOfMonth isGreaterThan:date]) {
        firstOfMonth = [gregorian dateByAddingUnit:NSCalendarUnitMonth value:-1 toDate:firstOfMonth options:NSCalendarWrapComponents];
    }
    return [self beginningOfDayOnDate:firstOfMonth];
}
-(NSDate*)beginningOfWeek:(NSDate*)date
{
    return [date firstDayOfWeekWithFirstDay:[self.weekStartPopop indexOfSelectedItem]+1];
}
-(NSDate*)previousStartDate:(NSDate*)currentStartDate;
{
    NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
    NSCalendar *gregorian = [[NSCalendar alloc]
                             initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    switch ([self reportingInterval]) {
        case AMCReportingIntervalDaily:
        {
            [offsetComponents setDay:-1];
            break;
        }
        case AMCReportingIntervalWeekly:
        {
            [offsetComponents setDay:-7];
            break;
        }
        case AMCReportingIntervalMonthly:
        {
            [offsetComponents setMonth:-1];
            break;
        }
        case AMCReportingIntervalYearly:
        {
            [offsetComponents setYear:-1];
            break;
        }
    }
    return [gregorian dateByAddingComponents:offsetComponents toDate:currentStartDate options:0];
}
-(NSDate*)earliestDate
{
    Sale * sale = [Sale firstEverSaleWithMoc:self.documentMoc];
    if (sale) {
        return sale.createdDate;
    } else {
        return [NSDate date];
    }
}
-(NSDate*)beginningOfDayOnDate:(NSDate*)date
{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *components = [gregorian components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:date];
    return [gregorian dateFromComponents:components];
}
-(NSDate*)endDateFromStartDate:(NSDate*)startDate
{
    NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
    NSCalendar *gregorian = [[NSCalendar alloc]
                             initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    switch ([self reportingInterval]) {
        case AMCReportingIntervalDaily:
        {
            [offsetComponents setDay:1];
            break;
        }
        case AMCReportingIntervalWeekly:
        {
            [offsetComponents setDay:7];
            break;
        }
        case AMCReportingIntervalMonthly:
        {
            [offsetComponents setMonth:1];
            break;
        }
        case AMCReportingIntervalYearly:
        {
            [offsetComponents setYear:1];
            break;
        }
    }
    return [gregorian dateByAddingComponents:offsetComponents toDate:startDate options:0];
}
-(AMCReportingInterval)reportingInterval
{
    return self.reportPeriodPopup.indexOfSelectedItem;
}
#pragma mark - AMCRecportsViewDelegate
-(void)reportsViewDidAppear:(AMCReportsView *)reportsView
{
    [self loadPeriodPopup];
    [self loadWeekStartPopup];
    [self loadMonthStartPopup];
    self.yearStartStepper.dateValue = [self.salonDocument.salon.firstDayOfTrading beginningOfDay];
}
#pragma mark - NSTableViewDataSource
-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    NSUInteger rows = self.reportData.count;
    return rows;
}
-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSDictionary * data = self.reportData[row];
    if ([tableColumn.identifier isEqualToString:@"day"]) {
        NSDate * date = data[@"date"];
        return [date stringNamingDayOfWeek];
    }
    if ([tableColumn.identifier isEqualToString:@"date"]) {
        NSDate * date = data[@"date"];
        return [date dayAndMonthString];
    }
    if ([tableColumn.identifier isEqualToString:@"hairCategories"]) {
        return data[@"hairCategories"];
    }
    if ([tableColumn.identifier isEqualToString:@"beautyCategories"]) {
        return data[@"beautyCategories"];
    }
    if ([tableColumn.identifier isEqualToString:@"allCategories"]) {
        return data[@"allCategories"];
    }
    if ([tableColumn.identifier isEqualToString:@"payments"]) {
        return data[@"payments"];
    }
    if ([tableColumn.identifier isEqualToString:@"profits"]) {
        return data[@"profits"];
    }
    return nil;
}
#pragma mark - NSTableViewDelegate
-(BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    return NO;
}
#pragma mark - Helpers
-(void)loadPeriodPopup
{
    [self.reportPeriodPopup removeAllItems];
    [self.reportPeriodPopup addItemWithTitle:@"Daily totals"];
    [self.reportPeriodPopup addItemWithTitle:@"Weekly totals"];
    [self.reportPeriodPopup addItemWithTitle:@"Monthly totals"];
    [self.reportPeriodPopup addItemWithTitle:@"Yearly totals"];
    [self.reportPeriodPopup selectItemAtIndex:0];
    [self reportPeriodChanged:self];
}
-(void)loadMonthStartPopup
{
    [self.monthStartPopup removeAllItems];
    for (int i = 0; i < 28; i++) {
        [self.monthStartPopup addItemWithTitle:[NSString stringWithFormat:@"%@",@(i+1)]];
    }
    [self.monthStartPopup selectItemAtIndex:0];
}
-(NSUInteger)firstDayOfWeek
{
    return [self.weekStartPopop indexOfSelectedItem]+1;
}
-(void)loadWeekStartPopup
{
    [self.weekStartPopop removeAllItems];
    [self.weekStartPopop addItemWithTitle:@"Sunday"];
    [self.weekStartPopop addItemWithTitle:@"Monday"];
    [self.weekStartPopop addItemWithTitle:@"Tuesday"];
    [self.weekStartPopop addItemWithTitle:@"Wednesday"];
    [self.weekStartPopop addItemWithTitle:@"Thursday"];
    [self.weekStartPopop addItemWithTitle:@"Friday"];
    [self.weekStartPopop addItemWithTitle:@"Saturday"];
    [self.weekStartPopop selectItemAtIndex:self.salonDocument.salon.firstDayOfWeek.doubleValue-1];
}
@end

