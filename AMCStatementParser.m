//
//  AMCStatementParser.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 06/04/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "AMCStatementParser.h"
#import <Cocoa/Cocoa.h>
#import "Account.h"

@interface AMCStatementParser()
{
    NSString * _csvString;
    NSMutableArray * _transactionDictionaries;
    NSArray * _sortDescriptorsForTransactionDictionaries;
}
@property NSMutableArray * rows;
@property (readonly) NSMutableArray * filteredRows;
@property Account * account;
@end

@implementation AMCStatementParser

-(instancetype)initWithCSVString:(NSString*)string account:(Account*)account {
    self = [super init];
    if (self) {
        self.account = account;
        self.csvString = string;
        self.dateCol = account.csvDateColumn.integerValue;
        self.grossAmountColumn = account.csvAmountColumn.integerValue;
        self.noteColumn = account.csvNoteColumn.integerValue;
        self.feeColumn = account.csvFeeColumn.integerValue;
        self.netAmountColumn = account.csvNetAmountColumn.integerValue;
        self.statusColumn = account.csvStatusColumn.integerValue;
        self.statusInclude = account.csvStatusInclude;
        self.statusExclude = @"";
    }
    return self;
}
-(NSArray *)sortDescriptorsForTransactionDictionaries {
    return _sortDescriptorsForTransactionDictionaries;
}
-(void)setSortDescriptorsForTransactionDictionaries:(NSArray *)sortDescriptorsForTransactionDictionaries {
    _sortDescriptorsForTransactionDictionaries = sortDescriptorsForTransactionDictionaries;
    [self.transactionDictionaries sortUsingDescriptors:_sortDescriptorsForTransactionDictionaries];
}
-(NSInteger)dateCol {
    return self.account.csvDateColumn.integerValue;
}
-(void)setDateCol:(NSInteger)dateCol {
    self.account.csvDateColumn = @(dateCol);
    _transactionDictionaries = nil;
}
-(NSInteger)headerRows {
    return self.account.csvHeaderLines.integerValue;
}
-(void)setHeaderRows:(NSInteger)headerRows {
    self.account.csvHeaderLines = @(headerRows);
    _transactionDictionaries = nil;
}
-(NSInteger)noteColumn {
    return self.account.csvNoteColumn.integerValue;
}
-(void)setNoteColumn:(NSInteger)noteColumn {
    self.account.csvNoteColumn = @(noteColumn);
    _transactionDictionaries = nil;
}
-(NSInteger)grossAmountColumn {
    return self.account.csvAmountColumn.integerValue;
}
-(void)setGrossAmountColumn:(NSInteger)grossAmountColumn {
    self.account.csvAmountColumn = @(grossAmountColumn);
    _transactionDictionaries = nil;
}
-(NSInteger)feeColumn {
    return self.account.csvFeeColumn.integerValue;
}
-(void)setFeeColumn:(NSInteger)feeColumn {
    self.account.csvFeeColumn = @(feeColumn);
    _transactionDictionaries = nil;
}
-(NSInteger)netAmountColumn {
    return self.account.csvNetAmountColumn.integerValue;
}
-(void)setNetAmountColumn:(NSInteger)netAmountColumn {
    self.account.csvNetAmountColumn = @(netAmountColumn);
    _transactionDictionaries = nil;
}
-(NSInteger)statusColumn {
    return self.account.csvStatusColumn.integerValue;
}
-(void)setStatusColumn:(NSInteger)statusColumn {
    self.account.csvStatusColumn = @(statusColumn);
}
-(NSString *)statusInclude {
    if (self.account.csvStatusInclude && self.account.csvStatusInclude.length > 0) {
        return self.account.csvStatusInclude;
    }
    return @"";
}
-(void)setStatusInclude:(NSString *)statusInclude {
    self.account.csvStatusInclude = statusInclude;
    _transactionDictionaries = nil;
}
-(NSString *)statusExclude {
    if (self.account.csvStatusExclude && self.account.csvStatusExclude.length > 0) {
        return self.account.csvStatusExclude;
    }
    return @"";
}
-(void)setStatusExclude:(NSString *)statusExclude {
    self.account.csvStatusExclude = statusExclude;
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
            NSDictionary * transactionDictionary = [self transactionDictionaryForTransactionRow:i-firstRow];
            if (transactionDictionary) {
                [_transactionDictionaries addObject:transactionDictionary];
            }
        }
        if (self.dateCol < 0) {
            // Can't sort
        } else {
            // sort on date
            [_transactionDictionaries sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES]]];
        }
    }
    return _transactionDictionaries;
}
-(NSDictionary*)transactionDictionaryForTransactionRow:(NSInteger)transactionRow {
    NSInteger row = (self.headerRows > 0)?transactionRow + self.headerRows:transactionRow;
    if (![self includeRow:row]) {return nil;}
    NSMutableDictionary * dictionary = [NSMutableDictionary dictionary];
    dictionary[@"paired"] = [self pairedForRow:row];
    dictionary[@"date"] = [self dateForRow:row];
    dictionary[@"amount"] = [self amountForRow:row];
    dictionary[@"note"] = [self noteForRow:row];
    return dictionary;
}
-(BOOL)includeRow:(NSInteger)row {
    if (self.statusColumn < 0) {return YES;}
    NSString * rowString = self.rows[row];
    NSDictionary * columnDictionary = [self columnDictionaryForCSVRowString:rowString];
    NSString * key = [self keyForColumn:self.statusColumn];
    NSString * state = columnDictionary[key];
    if ([state isEqualToString:@""] || [state isEqualToString:@"*"] || [state isEqualToString:self.statusInclude]) {
        return YES;
    }
    return NO;
}
-(NSString*)keyForColumn:(NSInteger)column {
    return [NSString stringWithFormat:@"Column %lu",column];
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
    NSArray * columns = [self columnsFromRowString:rowString];
    NSMutableDictionary * dictionary = [NSMutableDictionary dictionary];
    NSInteger i = 0;
    for (NSString * columnString in columns) {
        NSString * key = [self keyForColumn:i];
        dictionary[key] = columnString;
        i++;
    }
    dictionary[@"paired"] = @"";
    return dictionary;
}
-(NSString*)csvStringForIdentifier:(NSString*)identifier row:(NSInteger)row {
    NSString * string = [self columnDictionaryForRow:row][identifier];
    if (!string) return nil;
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
        NSString * key = [self keyForColumn:self.dateCol];
        NSString * dateString = [self csvStringForIdentifier:key row:row];
        return [self dateFromString:dateString];
    }
    return nil;
}
-(NSNumber*)amountForRow:(NSInteger)row {
    if (self.grossAmountColumn >=0) {
        NSString * key = [self keyForColumn:self.grossAmountColumn];
        NSString * stringAmount = [self csvStringForIdentifier:key row:row];
        stringAmount = [stringAmount stringByReplacingOccurrencesOfString:@"\"" withString:@""];
        return @(stringAmount.doubleValue);
    }
    return nil;
}
-(NSString*)noteForRow:(NSInteger)row {
    if (self.noteColumn >=0) {
        NSString * key = [self keyForColumn:self.noteColumn];
        NSString * note = [self csvStringForIdentifier:key row:row];
        return note;
    }
    return nil;
}
-(NSString*)pairedForRow:(NSInteger)row {
    return [self csvStringForIdentifier:@"paired" row:row];
}

#pragma mark - CSV processing functions
-(NSArray*)columnsFromRowString:(NSString*)rowString {
    NSMutableArray * columnStrings = [NSMutableArray array];
    NSRange nextFieldRange = [self nextStringRangeInCSVRowString:rowString beginningAtIndex:0];
    while (nextFieldRange.length < rowString.length) {
        NSString * field = [rowString substringWithRange:nextFieldRange];
        [columnStrings addObject:field];
        nextFieldRange = [self nextStringRangeInCSVRowString:rowString beginningAtIndex:NSMaxRange(nextFieldRange)+1];
    }
    return [columnStrings copy];
}
-(NSRange)nextStringRangeInCSVRowString:(NSString*)rowstring beginningAtIndex:(NSInteger)index {
    if (index >= rowstring.length) {
        return NSMakeRange(rowstring.length, 0);
    }
    NSInteger firstNonDelimiterCharacter = [self firstNonDelimiterCharacter:rowstring beginningAtIndex:index];
    if (firstNonDelimiterCharacter < 0) {
        return NSMakeRange(0, rowstring.length);
    }
    NSString * delimiter = [self expectedDelimiterForString:rowstring beginningAtIndex:firstNonDelimiterCharacter];
    NSInteger lastNonDelimiterCharacter = [self lastNonDelimiterCharacter:rowstring beginningAtIndex:firstNonDelimiterCharacter delimiter:delimiter];
    return NSMakeRange(firstNonDelimiterCharacter, 1+lastNonDelimiterCharacter-firstNonDelimiterCharacter);
}
-(NSString*)expectedDelimiterForString:(NSString*)string beginningAtIndex:(NSInteger)index {
    NSString * delimiter = [self firstDelimiterInString:string priorToIndex:index];
    delimiter = (delimiter)?delimiter:@",";
    return delimiter;
}
-(NSString*)firstDelimiterInString:(NSString*)string priorToIndex:(NSInteger)index {
    while (index >0) {
        NSString * previousChar = [string substringWithRange:NSMakeRange(index-1, 1)];
        if ([previousChar isEqualToString:@","] || [previousChar isEqualToString:@"\""]) {
            return previousChar;
        }
        index--;
    }
    return nil;
}
-(NSInteger)firstNonDelimiterCharacter:(NSString*)string beginningAtIndex:(NSInteger)index {
    NSString * nextChar;
    while (index < string.length) {
        nextChar = [string substringWithRange:NSMakeRange(index, 1)];
        if (![nextChar isEqualToString:@","] && ![nextChar isEqualToString:@"\""]) {
            return index;
        }
        index++;
    }
    return -1;
}
-(NSInteger)lastNonDelimiterCharacter:(NSString*)string  beginningAtIndex:(NSInteger)index delimiter:(NSString*)fieldDelimiter {
    NSString * nextChar;
    while (index < string.length) {
        nextChar = [string substringWithRange:NSMakeRange(index, 1)];
        if ([nextChar isEqualToString:fieldDelimiter]) {
            return index-1;
        }
        index++;
    }
    return -1;
}

@end
