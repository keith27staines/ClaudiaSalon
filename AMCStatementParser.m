//
//  AMCStatementParser.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 06/04/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "AMCStatementParser.h"

@interface AMCStatementParser()
{
    NSString * _csvString;
}
@property NSArray * rows;
@end

@implementation AMCStatementParser

-(instancetype)initWithCSVString:(NSString*)string {
    self = [super init];
    if (self) {
        self.csvString = string;
        self.dateCol = -1;
    }
    return self;
}

-(NSString *)csvString {
    return _csvString;
}
-(void)setCsvString:(NSString *)csvString {
    _csvString = csvString;
    [self splitIntoRows];
}
-(void)splitIntoRows {
    self.rows = [self.csvString componentsSeparatedByString:@"\n"];
    self.rowCount = self.rows.count;
}
-(NSDictionary*)dictionaryForRow:(NSInteger)row {
    NSString * rowString = self.rows[row];
    NSArray * columns = [rowString componentsSeparatedByString:@","];
    NSMutableDictionary * dictionary = [NSMutableDictionary dictionary];
    NSInteger i = 0;
    for (NSString * columnString in columns) {
        NSString * key = [NSString stringWithFormat:@"Col%lu",i];
        dictionary[key] = columnString;
        i++;
    }
    return dictionary;
}
-(id)objectForColumnWithIdentifier:(NSString *)identifier row:(NSInteger)row {
    NSString * string = [self dictionaryForRow:row][identifier];
    if (!string) return nil;
    NSError *error = nil;
    NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeDate
                                                               error:&error];
    NSArray *matches = [detector matchesInString:string
                                         options:0
                                           range:NSMakeRange(0, [string length])];
    NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateStyle = NSDateFormatterShortStyle;
    dateFormatter.timeStyle = NSDateFormatterShortStyle;
    for (NSTextCheckingResult *match in matches) {
        if ([match resultType] == NSTextCheckingTypeDate) {
            
            return [dateFormatter stringFromDate:[match date]];
        }
    }
    return string;
    
}
@end
