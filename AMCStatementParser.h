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
@property NSInteger dateRow;
@property NSInteger dateCol;
@property NSInteger broughtForwardRow;
@property NSInteger broughtForwardCol;
@property NSInteger carryForwardRow;
@property NSInteger carryForwardCol;
-(id)objectForColumnWithIdentifier:(NSString*)identifier row:(NSInteger)row;
@end
