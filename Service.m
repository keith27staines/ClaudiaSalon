//
//  Service.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 25/01/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

#import "Service.h"
#import "Employee.h"
#import "Note.h"
#import "Product.h"
#import "SaleItem.h"
#import "ServiceCategory.h"

#import "ServiceCategory.h"
#import "AMCConstants.h"
#import "Account.h"

@implementation Service
+(id)newObjectWithMoc:(NSManagedObjectContext*)moc
{
    Service * service = [NSEntityDescription insertNewObjectForEntityForName:@"Service" inManagedObjectContext:moc];
    NSDate * rightNow = [NSDate date];
    service.createdDate = rightNow;
    service.lastUpdatedDate = rightNow;
    return service;
}
+(NSArray*)allObjectsWithMoc:(NSManagedObjectContext*)moc {
    NSArray * array = nil;
    NSFetchRequest * fetch = [NSFetchRequest fetchRequestWithEntityName:@"Service"];
    array = [moc executeFetchRequest:fetch error:nil];
    return array;
}
-(NSString*)displayText
{
    return self.name;
}
-(NSString*)bracketedString
{
    NSString * bracketedString;
    bracketedString = [self commaSeperatedstringFromString:bracketedString byAppendingString:self.hairLengthDescription];
    
    bracketedString = [self commaSeperatedstringFromString:bracketedString byAppendingString:self.deluxeDescription];
    // enclose in brackets
    if (bracketedString.length > 0) {
        bracketedString = [@"(" stringByAppendingString:bracketedString];
        bracketedString = [bracketedString stringByAppendingString:@")"];
    }
    return bracketedString;
}
-(NSString*)hairLengthDescription
{
    HairLength hairLength = (HairLength)self.hairLength.integerValue;
    NSString * descr;
    switch (hairLength) {
        case HairLengthNotApplicable:
            descr = @"";
            break;
        case HairLengthShort:
            descr = @"Short";
            break;
        case HairLengthMedium:
            descr = @"Medium";
            break;
        case HairLengthLong:
            descr = @"Long";
            break;
    }
    return descr;
}
-(NSString*)deluxeDescription
{
    if (self.deluxe.boolValue == YES) {
        return @"deluxe";
    }
    return @"";
}
-(NSString*)commaSeperatedstringFromString:(NSString*)string byAppendingString:(NSString*)nextString
{
    if (!string || string.length == 0) {
        return nextString;
    }
    if (!nextString || nextString.length == 0) {
        return string;
    }
    string = [string stringByAppendingString:@", "];
    string = [string stringByAppendingString:nextString];
    return string;
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
#pragma mark - AMCTreeNodeProtocol
-(id<AMCTreeNode>)rootNode {
    return self.serviceCategory.rootNode;
}
-(ServiceCategory *)parentNode {
    return self.serviceCategory;
}
-(void)setParentNode:(ServiceCategory *)parentNode {
    self.serviceCategory = parentNode;
}
-(Service*)addChild:(Service*)child {
    NSAssert(NO, @"Services do not have children");
    return nil;
}
-(Service*)removeChild:(Service*)child {
    NSAssert(NO, @"Services do not have children");
    return nil;
}
-(NSInteger)nodesCount {
    return 0;
}
-(NSInteger)leavesCount {
    return 0;
}
-(NSArray *)leaves {
    return @[];
}
-(NSArray *)nodes {
    return @[];
}
-(BOOL)isLeaf {
    return YES;
}
-(BOOL)isSystemNode {
    return NO;
}
@end

