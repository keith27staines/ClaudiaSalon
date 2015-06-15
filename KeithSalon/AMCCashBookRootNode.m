//
//  AMCCashBookRootNode.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 14/06/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "AMCCashBookRootNode.h"
#import "Salon+Methods.h"
#import "AccountingPaymentGroup+Methods.h"

@interface AMCCashBookRootNode()
{
    
}
@property (readwrite) Salon * salon;
@property (readwrite) AMCCashBookNode * expenditureRoot;
@property (readwrite) AMCCashBookNode * incomeRoot;
@property (readwrite) AMCCashBookNode * expenditureOtherNode;
@property (readwrite) AMCCashBookNode * incomeOtherNode;

@end

@implementation AMCCashBookRootNode
-(instancetype)initWithSalon:(Salon*)salon {
    self.salon = salon;
    self.moc = salon.managedObjectContext;
    return [self initWithAccountancyGroup:salon.rootAccountingGroup];
}
-(instancetype)initWithAccountancyGroup:(AccountingPaymentGroup *)group {
    NSAssert(self.salon,@"Salon not initialised. Use initWithSalon:");
    NSAssert(group == self.salon.rootAccountingGroup,@"Group must be the root group");
    self = [super initWithAccountancyGroup:group];
    if (self) {
        // Identify incomeRoot and expenditureRoot nodes
        for (AMCCashBookNode * childNode in self.childNodes) {
            if (childNode.representedObject == self.salon.rootIncomeGroup) {
                self.incomeRoot = childNode;
            }
            if (childNode.representedObject == self.salon.rootExpenditureGroup) {
                self.expenditureRoot = childNode;
            }
        }
        // Identify incomeOther node
        for (AMCCashBookNode * childNode in self.incomeRoot.childNodes) {
            if (childNode.representedObject == self.salon.incomeOtherGroup) {
                self.incomeOtherNode = childNode;
                break;
            }
        }
        // Identify expenditureOther node
        for (AMCCashBookNode * childNode in self.expenditureRoot.childNodes) {
            if (childNode.representedObject == self.salon.expenditureOtherGroup) {
                self.expenditureOtherNode = childNode;
                break;
            }
        }
    }
    return self;
}
@end
