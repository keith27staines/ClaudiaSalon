//
//  AMCStatementParser.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 06/04/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

@class Account;

#import <Foundation/Foundation.h>

@interface AMCStatementParser : NSObject

-(instancetype)initWithCSVString:(NSString*)string account:(Account*)account;
@property (copy) NSString * csvString;
@property NSInteger rowCount;
@property (copy,readonly) NSDate * date;
@property NSInteger headerRows;
@property NSInteger dateCol;
@property NSInteger grossAmountColumn;
@property NSInteger noteColumn;
@property NSInteger feeColumn;
@property NSInteger netAmountColumn;
@property (readonly) NSMutableArray* transactionDictionaries;
@property NSArray * sortDescriptorsForTransactionDictionaries;
@property NSInteger statusColumn;
@property NSString * statusInclude;
@property NSString * statusExclude;

-(NSString*)csvStringForIdentifier:(NSString*)identifier row:(NSInteger)row;
-(NSDate*)dateForRow:(NSInteger)row;
-(NSNumber*)amountForRow:(NSInteger)row;
-(NSString*)noteForRow:(NSInteger)row;
-(NSString*)pairedForRow:(NSInteger)row;
@end
