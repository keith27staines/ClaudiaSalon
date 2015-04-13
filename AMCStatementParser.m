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
    NSMutableArray * _transactionDictionaries;
    NSInteger _headerRows;
    NSInteger _dateCol;
}
@property NSMutableArray * rows;
@property (readonly) NSMutableArray * filteredRows;
@end

@implementation AMCStatementParser

-(instancetype)initWithCSVString:(NSString*)string {
    self = [super init];
    if (self) {
        self.csvString = string;
        self.dateCol = -1;
        self.grossAmountColumn = -1;
        self.noteColumn = -1;
        self.feeColumn = -1;
        self.netAmountColumn = -1;
    }
    return self;
}
-(NSInteger)dateCol {
    return _dateCol;
}
-(void)setDateCol:(NSInteger)dateCol {
    _dateCol = dateCol;
    _transactionDictionaries = nil;
}
-(NSInteger)headerRows {
    return _headerRows;
}
-(void)setHeaderRows:(NSInteger)headerRows {
    _headerRows = headerRows;
    _transactionDictionaries = nil;
}
-(NSInteger)transactionRows {
    if (self.headerRows > 0) {
        return self.rowCount - self.headerRows;
    }
    return self.rowCount;
}
-(NSMutableArray *)transactionDictionaries {
    if (!_transactionDictionaries) {
        _transactionDictionaries = [NSMutableArray array];
        NSInteger firstRow = 0;
        NSInteger lastRow = self.rowCount;
        if (self.headerRows > 0) {
            // header rows are excluded in the filtered rows array
            firstRow = self.headerRows;
            lastRow = lastRow - self.headerRows;
        }
        for (NSInteger i = firstRow; i < lastRow; i++) {
            [_transactionDictionaries addObject:[self transactionDictionaryForTransactionRow:i-firstRow]];
        }
        if (self.dateCol < 0) {
            // Can't sort
        } else {
            // sort on date
            [_transactionDictionaries sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"Date" ascending:YES]]];
        }
    }
    return _transactionDictionaries;
}
-(NSDictionary*)transactionDictionaryForTransactionRow:(NSInteger)transactionRow {
    NSInteger row = transactionRow;
    if (self.headerRows > 0) {
        row = transactionRow + self.headerRows;
    }
    NSMutableDictionary * dictionary = [NSMutableDictionary dictionary];
    dictionary[@"reconciled"] = [self reconciledForRow:row + self.headerRows];
    dictionary[@"date"] = [self dateForRow:row];
    dictionary[@"amount"] = [self amountForRow:row];
    dictionary[@"note"] = [self noteForRow:row];
    return dictionary;
}
-(NSString *)csvString {
    return _csvString;
}
-(void)setCsvString:(NSString *)csvString {
    _csvString = csvString;
    [self splitIntoRows];
}
-(void)splitIntoRows {
    NSArray * rowsIncludingHeaders = [[self.csvString componentsSeparatedByString:@"\n"] mutableCopy];
    self.rows = [NSMutableArray array];
    if (self.headerRows > 0) {
        for (NSInteger i = self.headerRows - 1; i < rowsIncludingHeaders.count; i++) {
            [self.rows addObject:rowsIncludingHeaders[i]];
        }
    } else {
        self.rows = [rowsIncludingHeaders mutableCopy];
    }
    self.rowCount = self.rows.count;
}
-(NSDictionary*)columnDictionaryForRow:(NSInteger)row {
    NSString * rowString;
    rowString = self.rows[row];
    return [self columnDictionaryForCSVRowString:rowString];
}
-(NSDictionary*)columnDictionaryForCSVRowString:(NSString*)rowString {
    NSArray * columns = [rowString componentsSeparatedByString:@","];
    NSMutableDictionary * dictionary = [NSMutableDictionary dictionary];
    NSInteger i = 0;
    for (NSString * columnString in columns) {
        NSString * key = [NSString stringWithFormat:@"Column %lu",i];
        dictionary[key] = columnString;
        i++;
    }
    dictionary[@"reconciled"] = @"";
    return dictionary;
}

-(NSString*)csvStringForIdentifier:(NSString*)identifier row:(NSInteger)row {
    NSString * string = [self columnDictionaryForRow:row][identifier];
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
-(NSDate*)dateFromString:(NSString*)string {
    NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeDate
                                                               error:nil];
    NSArray *matches = [detector matchesInString:string
                                         options:0
                                           range:NSMakeRange(0, [string length])];
    NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateStyle = NSDateFormatterShortStyle;
    dateFormatter.timeStyle = NSDateFormatterShortStyle;
    for (NSTextCheckingResult *match in matches) {
        if ([match resultType] == NSTextCheckingTypeDate) {
            return [match date];
        }
    }
    return nil;
}
-(NSDate*)dateForRow:(NSInteger)row {
    if (self.dateCol >=0) {
        NSString * key = [NSString stringWithFormat:@"Column %lu",self.dateCol];
        NSString * dateString = [self csvStringForIdentifier:key row:row];
        return [self dateFromString:dateString];
    }
    return nil;
}
-(NSNumber*)amountForRow:(NSInteger)row {
    if (self.grossAmountColumn >=0) {
        NSString * key = [NSString stringWithFormat:@"Column %lu",self.grossAmountColumn];
        NSString * stringAmount = [self csvStringForIdentifier:key row:row];
        return @(stringAmount.doubleValue);
    }
    return nil;
}
-(NSString*)noteForRow:(NSInteger)row {
    if (self.noteColumn >=0) {
        NSString * key = [NSString stringWithFormat:@"Column %lu",self.noteColumn];
        NSString * note = [self csvStringForIdentifier:key row:row];
        return note;
    }
    return nil;
}
-(NSString*)reconciledForRow:(NSInteger)row {
    return [self csvStringForIdentifier:@"reconciled" row:row];
}
@end
