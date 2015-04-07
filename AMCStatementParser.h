//
//  AMCStatementParser.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 06/04/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AMCStatementParser : NSObject

-(instancetype)initWithCSVString:(NSString*)string;
@property (copy) NSString * csvString;
@property NSInteger rowCount;
@property (copy,readonly) NSDate * date;
@property NSInteger headerRows;
@property NSInteger dateCol;
@property NSInteger grossAmountColumn;
@property NSInteger feeColumn;
@property NSInteger netAmountColumn;
-(id)objectForColumnWithIdentifier:(NSString*)identifier row:(NSInteger)row;
@end
