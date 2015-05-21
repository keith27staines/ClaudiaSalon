//
//  AMCShoppingListPrintView.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 04/01/2015.
//  Copyright (c) 2015 Keith Staines. All rights reserved.
//

#import "AMCShoppingListPrintView.h"
#import "NSDate+AMCDate.h"
#import "StockedProduct+Methods.h"
#import "StockedBrand+Methods.h"
#import "StockedCategory+Methods.h"
#import "AMCSalonDocument.h"

@interface AMCShoppingListPrintView()
{
    AMCShoppingListPrintView * _printView;
}
@property NSFont * bodyTextFont;
@property NSDictionary * bodyTextAttributes;
@property NSSize paperSize;
@property NSRect bodyRect;
@property NSMutableArray * cellRectangles;
@property NSInteger drawingOptions;
@property NSInteger pageNumber;
@property NSPrintInfo * printInfo;
@property BOOL isDrawingToScreen;
@property NSInteger pageCount;
@property float pageDown;
@property NSArray * categories;
@property NSMutableDictionary * productsByCategory;
@property AMCShoppingListPrintView * printView;
@end

@implementation AMCShoppingListPrintView

- (void)drawRect:(NSRect)dirtyRect {
    NSLog(@"Drawing %@",self);
    [super drawRect:dirtyRect];
    NSGraphicsContext * context = [NSGraphicsContext currentContext];
    [context saveGraphicsState];
    
    _printInfo = [NSPrintInfo sharedPrintInfo];
    _paperSize = _printInfo.paperSize;
    self.pageNumber = 0;
    self.isDrawingToScreen = [context isDrawingToScreen];
    if (self.isDrawingToScreen) {
        self.pageCount = 1;
        NSAffineTransform* xform = [NSAffineTransform transform];
        float xScale = self.bounds.size.width / _paperSize.width;
        float yScale = self.bounds.size.height / _paperSize.height;
        [xform scaleXBy:xScale yBy:yScale];
        [xform concat];
        _bodyRect = NSMakeRect(_printInfo.leftMargin, _printInfo.topMargin, _paperSize.width - _printInfo.leftMargin - _printInfo.rightMargin, _paperSize.height - _printInfo.topMargin - _printInfo.bottomMargin);
        self.pageDown = _paperSize.height;
    } else {
        _bodyRect = NSMakeRect(0, 0, _paperSize.width - _printInfo.leftMargin - _printInfo.rightMargin, _paperSize.height - _printInfo.topMargin - _printInfo.bottomMargin);
        self.pageDown = _bodyRect.size.height;
    }
    
    NSFont * font = [NSFont fontWithName:@"Helvetica" size:11];
    self.bodyTextAttributes = @{NSFontAttributeName: font};
    _drawingOptions = NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingTruncatesLastVisibleLine;
    
    NSRect textRect;
    float unit = _bodyRect.size.width / 14;
    textRect = [self drawShoppingListTitle];
    textRect.origin.y += 2*textRect.size.height;
    
    NSRect rectColumn0 = NSMakeRect(_bodyRect.origin.x, 0, 2 * unit, 1);
    NSRect rectColumn1 = NSMakeRect(NSMaxX(rectColumn0) + unit/2, 0, 8 * unit, 1);
    NSRect rectColumn2 = NSMakeRect(NSMaxX(rectColumn1) + unit/2, 0, 2 * unit, 1);
    NSRect rectColumn3 = NSMakeRect(NSMaxX(rectColumn2) + unit/2, 0, 1 * unit, 1);
    NSRect rectColumn4 = NSMakeRect(NSMaxX(rectColumn3) + unit/2, 0, 0.01 * unit, 1);
    self.cellRectangles = [@[[NSValue valueWithRect:rectColumn0],
                             [NSValue valueWithRect:rectColumn1],
                             [NSValue valueWithRect:rectColumn2],
                             [NSValue valueWithRect:rectColumn3],
                             [NSValue valueWithRect:rectColumn4]] mutableCopy];
    [self shiftCellRectanglesDownTo:NSMaxY(textRect)];
    
    self.pageNumber = 0;
    NSArray * textArray;
    for (StockedCategory * category in self.categories) {
        NSDictionary * productsInCategory = self.productsByCategory[category.categoryName];
        if (productsInCategory.count > 0) {
            [self safelyWriteToCells:@[@"",@"", @"",@"",@""]];
            [self safelyWriteToCells:@[@"",@"", @"",@"",@""]];
            //[self safelyWriteHeading:category.categoryName level:2];
            [self safelyWriteToCells:@[@"Brand",@"Product",@"Code",@"Qty",@""]];
            [self drawLine:[NSColor blackColor] width:1];
            for (StockedProduct * product in productsInCategory) {
                if (product.numberToBuy.integerValue > 0) {
                    textArray = @[product.stockedBrand.shortBrandName,
                                            product.name, product.code,product.numberToBuy.stringValue,@""];
                    [self safelyWriteToCells:textArray];
                }
            }
            
        }

    }
    [context restoreGraphicsState];
}
-(void)drawLine:(NSColor*)color width:(NSInteger)width {
    NSValue * value = self.cellRectangles[0];
    NSRect leftRect = value.rectValue;
    value = self.cellRectangles[self.cellRectangles.count-1];
    NSRect rightRect = value.rectValue;
    [color set];
    [NSBezierPath setDefaultLineWidth:width];
    [NSBezierPath strokeLineFromPoint:leftRect.origin toPoint:rightRect.origin];
}
-(void)safelyWriteHeading:(NSString*)heading level:(NSInteger)level {
    NSArray * textArray = @[@"heading",@"",@"",@"",@""];
    if ([self doesWriteToCellsExceedPageLength:textArray]) {
        [self addPage];
    }
    NSValue * rectValue = self.cellRectangles[0];
    NSRect rect = rectValue.rectValue;
    [heading drawAtPoint:rect.origin withAttributes:_bodyTextAttributes];
    [self shiftCellRectanglesDownByAmount:rect.size.height];
}
-(void)safelyWriteToCells:(NSArray*)textArray {
    BOOL pageAdded = NO;
    if ([self doesWriteToCellsExceedPageLength:textArray]) {
        [self addPage];
        pageAdded = YES;
    }
    BOOL textArrayEmpty = YES;
    for (NSString * string in textArray) {
        if (!string || string.length == 0) {
            textArrayEmpty = NO;
            break;
        }
    }
    if (!pageAdded || !textArrayEmpty) {
        [self writeTextToCellsandMoveCellsDown:textArray inBold:NO];
        [self drawLine:[NSColor lightGrayColor] width:0];
    }
}
-(void)addPage {
    if (self.isDrawingToScreen) {
        self.pageCount++;
    }
    self.pageNumber++;
    float newYPos = [self topOfBodyTextForPage:self.pageNumber] + 5;
    [self shiftCellRectanglesDownTo:newYPos];
    [self writeTextToCellsandMoveCellsDown:@[@"Brand",@"Product",@"Code",@"Qty",@""] inBold:NO];
}
-(void)writeTextToCellsandMoveCellsDown:(NSArray*)textArray inBold:(BOOL)bold {
    [self writeTextToCells:textArray inBold:bold];
    [self shiftCellRectanglesDownByRowHeight];
}
-(BOOL)doesWriteToCellsExceedPageLength:(NSArray*)textArray {
    NSInteger index = 0;
    NSMutableArray * copy = [self.cellRectangles mutableCopy];
    NSRect cellRect;
    for (NSString * string in textArray) {
        cellRect = ((NSValue*)self.cellRectangles[index]).rectValue;
        cellRect.size.height = 100000;
        NSSize size = [string boundingRectWithSize:cellRect.size options:_drawingOptions attributes:_bodyTextAttributes].size;
        copy[index] = [NSValue valueWithRect:NSMakeRect(cellRect.origin.x,cellRect.origin.y,cellRect.size.width,size.height) ];
    }
    cellRect = ((NSValue*)self.cellRectangles[0]).rectValue;
    float bottomOfRow = cellRect.origin.y + [self maxCellHeight:copy];
    return [self doesYPos:bottomOfRow exceedPage:self.pageNumber];
}
-(BOOL)doesYPos:(float)yPos exceedPage:(NSInteger)pageNumber {
    float bottomOfPage = [self bottomOfBodyTextForPage:pageNumber];
    return (yPos >= bottomOfPage)?YES:NO;
}
-(float)topOfBodyTextForPage:(NSInteger)pageNumber {
    if (self.isDrawingToScreen) {
        return _bodyRect.origin.y + pageNumber * _paperSize.height;
    } else {
        return _bodyRect.origin.y + pageNumber * _bodyRect.size.height;
    }
}
-(float)bottomOfBodyTextForPage:(NSInteger)pageNumber {
    return _bodyRect.size.height + [self topOfBodyTextForPage:pageNumber];
}
-(void)writeTextToCells:(NSArray*)textArray inBold:(BOOL)bold {
    NSInteger index = 0;
    NSMutableArray * copy = [self.cellRectangles mutableCopy];
    for (NSString * string in textArray) {
        NSRect cellRect = ((NSValue*)self.cellRectangles[index]).rectValue;
        cellRect.size.height = 100000;
        NSSize size = [string boundingRectWithSize:cellRect.size options:_drawingOptions attributes:_bodyTextAttributes].size;
        copy[index] = [NSValue valueWithRect:NSMakeRect(cellRect.origin.x,cellRect.origin.y,cellRect.size.width,size.height) ];
        if (bold) {
            
        } else {
            [string drawWithRect:cellRect options:_drawingOptions attributes:_bodyTextAttributes];
        }
        index++;
    }
    self.cellRectangles = copy;
}
-(void)shiftCellRectanglesDownTo:(float)yPos {
    NSInteger index = 0;
    NSMutableArray * copy = [self.cellRectangles mutableCopy];
    for (NSValue * value in self.cellRectangles) {
        NSRect rect = value.rectValue;
        rect.origin.y = yPos;
        copy[index] = [NSValue valueWithRect:rect];
        index++;
    }
    self.cellRectangles = copy;
}
-(void)shiftCellRectanglesDownByRowHeight {

    float maxCellHeight = [self maxCellHeight:self.cellRectangles];
    [self shiftCellRectanglesDownByAmount:maxCellHeight];
}
-(float)maxCellHeight:(NSArray*)cells {
    float maxCellHeight = 0;
    for (NSValue * value in cells) {
        NSRect rect = value.rectValue;
        if (rect.size.height > maxCellHeight) {
            maxCellHeight = rect.size.height;
        }
    }
    return maxCellHeight;
}

-(void)shiftCellRectanglesDownByAmount:(float)amount {
    NSInteger index = 0;
    NSMutableArray * copy = [self.cellRectangles mutableCopy];
    for (NSValue * value in self.cellRectangles) {
        NSRect rect = value.rectValue;
        rect.origin.y += amount;
        copy[index] = [NSValue valueWithRect:rect];
        index++;
    }
    self.cellRectangles = copy;
}
-(NSRect)fullWidthRectangleBeneathRectangle:(NSRect)rect {
    return NSMakeRect(_bodyRect.origin.x, rect.origin.y, _bodyRect.size.width, rect.origin.y + rect.size.height);
}

-(NSRect)drawShoppingListTitle {
    NSString * string = [NSString stringWithFormat:@"Claudia's Salon shopping list %@",[[NSDate date] dateStringWithMediumDateFormatShortTimeFormat]];
    NSRect rect = [string boundingRectWithSize:_bodyRect.size options:NSStringDrawingTruncatesLastVisibleLine attributes:_bodyTextAttributes];
    rect.origin = _bodyRect.origin;
    [string drawWithRect:_bodyRect options:_drawingOptions attributes:_bodyTextAttributes];
    return rect;
}
-(BOOL)acceptsFirstResponder {
    return YES;
}
-(BOOL)isFlipped {
    return YES;
}
-(AMCShoppingListPrintView *)printView {
    if (!_printView) {
        _printView = [[AMCShoppingListPrintView alloc] init];
    }
    return _printView;
}
-(void)setPrintView:(AMCShoppingListPrintView *)printView {
    _printView = printView;
}
-(void)print:(id)sender {
    NSPrintInfo * printInfo = [NSPrintInfo sharedPrintInfo];
    NSSize paperSize = printInfo.paperSize;
    NSRect paperRect = NSMakeRect(0, 0, paperSize.width, self.pageCount * (paperSize.height - printInfo.topMargin - printInfo.bottomMargin));
    self.printView = [[AMCShoppingListPrintView alloc] initWithFrame:paperRect];
    self.printView.products = self.products;
    self.printView.categories = self.categories;
    self.printView.productsByCategory = self.productsByCategory;
    NSPrintOperation * printOperation = [NSPrintOperation printOperationWithView:self.printView printInfo:printInfo];
    [printOperation setJobTitle:@"Print shopping list"];
    [printOperation runOperation];
}
-(void)reloadData {
    NSAssert(self.document,@"The document has not been set");
    self.productsByCategory = [NSMutableDictionary dictionary];
    self.categories = [StockedCategory allObjectsWithMoc:self.document.managedObjectContext];
    for (StockedCategory * category in self.categories) {
        NSArray * productsInCategory = [StockedProduct allProductsForCategory:category withMoc:self.document.managedObjectContext];
        NSPredicate * predicate = [NSPredicate predicateWithFormat:@"numberToBuy > 0"];
        productsInCategory = [productsInCategory filteredArrayUsingPredicate:predicate];
        self.productsByCategory[category.categoryName] = productsInCategory;
    }
    [self setNeedsDisplay:YES];
}
@end
