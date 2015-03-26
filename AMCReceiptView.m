//
//  AMCReceiptView.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 15/08/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "AMCReceiptView.h"
#import "Sale+Methods.h"
#import "SaleItem+Methods.h"
#import "Customer+Methods.h"
#import "Payment+Methods.h"
#import "Employee+Methods.h"
#import "Service+Methods.h"
#import "AMCDiscountCalculator.h"


@interface AMCReceiptView()
{
    Sale * _sale;
    NSImage * _pdfImage;
    NSImage * _textImage;
    double pWidth;
    double pHeight;
    double sideMargin;
    double topMargin;
    double bottomMargin;
}

@property (readonly) NSRect headerRect;
@property (readonly) NSRect bodyRect;
@property (readonly) NSRect footerRect;
@property (readonly) NSRect pageRect;
@property (readonly) NSRect leftMarginRect;
@property (readonly) NSRect rightMarginRect;
@property (readonly) NSRect topMarginRect;
@property (readonly) NSRect bottomMarginRect;

@property (readonly) NSRect sourceRect;
@property (readonly) NSImage * pdfImage;
@property (readonly) NSImage * textImage;

@end

@implementation AMCReceiptView


-(void)viewDidMoveToWindow
{
    if (self.window) {
        _pdfImage = [[NSBundle mainBundle] imageForResource:@"png"];
        pWidth = [self paperSize].width;
        pHeight = [self paperSize].height;
        sideMargin = 58;
        topMargin = 190;
        bottomMargin = pHeight - topMargin - 510;
        [self setFrameSize:[self paperSize]];
        [self drawTextImage];
    }
}
- (void)drawRect:(NSRect)dirtyRect
{
    NSGraphicsContext * context;
    context = [NSGraphicsContext currentContext];
    [context saveGraphicsState];
    [super drawRect:dirtyRect];
    [self.pdfImage drawInRect:self.bounds fromRect:self.sourceRect operation:NSCompositeSourceOver fraction:1 respectFlipped:YES hints:nil];
    [self.textImage drawInRect:self.bounds fromRect:self.sourceRect operation:NSCompositeSourceOver fraction:1 respectFlipped:YES hints:nil];
    [context restoreGraphicsState];
}

-(BOOL)isFlipped
{
    return YES;
}
-(void)setSale:(Sale *)sale
{
    _sale = sale;
    _textImage = nil;
    [self drawTextImage];
    [self setNeedsDisplay:YES];
}
-(Sale *)sale
{
    return _sale;
}
-(NSImage*)pdfImage
{
    if (!_pdfImage) {
        _pdfImage = [[NSBundle mainBundle] imageForResource:@"pdf"];
    }
    return _pdfImage;
}
-(NSRect)sourceRect
{
    return NSMakeRect(0, 0, self.pdfImage.size.width, self.pdfImage.size.height);
}
-(NSSize)paperSize
{
    NSPrintOperation * op = [NSPrintOperation printOperationWithView:self];
    NSPrintInfo * info = op.printInfo;
    return info.imageablePageBounds.size;
}
-(NSRect)imageArea
{
    NSPrintOperation * op = [NSPrintOperation printOperationWithView:self];
    NSPrintInfo * info = op.printInfo;
    return info.imageablePageBounds;
}
-(BOOL)knowsPageRange:(NSRangePointer)range
{
    return NO;
}
-(NSRect)rectForPage:(NSInteger)page
{
    if (page==1) {
        return [self imageArea];
    } else {
        return NSZeroRect;
    }
}
-(void)printReceipt
{
    //[self setBoundsSize:[self paperSize]];
    NSPrintOperation * op = [NSPrintOperation printOperationWithView:self printInfo:[NSPrintInfo sharedPrintInfo]];

    NSPrintInfo * info = op.printInfo;
    [info setPaperSize:[self paperSize]];
    info.topMargin = 0;
    info.bottomMargin = 0;
    info.leftMargin = 0;
    info.rightMargin = 0;
    info.scalingFactor = 1.;
    info.horizontalPagination = NSFitPagination;
    info.verticalPagination = NSFitPagination;
    [op setShowsPrintPanel:NO];
    [op setShowsProgressPanel:YES];
    [op runOperation];
    [op cleanUpOperation];
}
-(void)drawTextImage
{
    if (!self.sale) return;
    _textImage = [NSImage imageWithSize:self.pdfImage.size flipped:YES drawingHandler:^BOOL(NSRect dstRect){
        NSGraphicsContext * context = [NSGraphicsContext currentContext];
        [context saveGraphicsState];
        
        [[NSColor whiteColor] set];
        NSRectFill(self.bodyRect);
        
        Sale * sale = self.sale;
        NSDateFormatter * df = [[NSDateFormatter alloc] init];
        df.dateStyle = NSDateFormatterMediumStyle;
        df.timeStyle = NSDateFormatterShortStyle;
        NSString * dateString = [df stringFromDate:sale.createdDate];
        NSString * titleString1;
        NSString * titleString2 = @"";
        if (sale.customer.fullName && sale.customer.fullName.length > 0) {
            titleString2 = [NSString stringWithFormat:@"For: %@",sale.customer.fullName];
        }
        if (sale.isQuote.boolValue) {
            titleString1 = [NSString stringWithFormat:@"  Quote for services"];
        } else {
            titleString1 = [NSString stringWithFormat:@"  Payment receipt"];
        }
        dateString = [dateString stringByAppendingString:titleString1];
        double y = self.bodyRect.origin.y;
        NSRect col0;
        NSRect col1;
        NSRect col2;
        NSString * string0 = @"";
        NSString * string1 = @"";
        NSString * string2 = @"";
        col0 = [self writeString:dateString atY:y inColumn:0];
        col1 = [self writeString:titleString2 atY:y inColumn:1];
        double rowHeight;
        rowHeight = fmax(col0.size.height, col1.size.height);
        rowHeight = fmax(rowHeight, col2.size.height);
        y += rowHeight + 30;
        int i = 0;
        NSString * discountDescr = @"";
        NSUInteger saleActualCharge = floor(sale.actualCharge.doubleValue * 100.0);
        NSUInteger saleItemActualCharge = 0;
        NSUInteger saleItemNominalCharge = 0;
        NSUInteger individualDiscounts = 0;
        NSUInteger totalUndiscounted = 0;
        NSUInteger chargeAfterIndividualDiscounts = 0;
        for (SaleItem * item in sale.saleItem) {
            saleItemActualCharge = floor(item.actualCharge.doubleValue * 100);
            saleItemNominalCharge = floor(item.nominalCharge.doubleValue * 100);
            if (i == 0) {
                string0 = @"Service";
                string1 = @"Notes";
                string2 = @"Price";
                col0 = [self writeString:string0 atY:y inColumn:0];
                col1 = [self writeString:string1 atY:y inColumn:1];
                col2 = [self writeString:string2 atY:y inColumn:2];
                rowHeight = fmax(col0.size.height, col1.size.height);
                rowHeight = fmax(rowHeight, col2.size.height);
                i++;
                y += rowHeight + 6;
                [[NSColor blackColor] set];
                [NSBezierPath strokeLineFromPoint:NSMakePoint(sideMargin, y) toPoint:NSMakePoint(pWidth, y)];
                y += 10;
            }
            string0 = item.service.name;
            NSUInteger discountThisItem = saleItemNominalCharge - saleItemActualCharge;
            if (discountThisItem > 0) {
                individualDiscounts += discountThisItem;
                discountDescr = [AMCDiscountCalculator discountDescriptionforDiscount:item.discountType.integerValue];
                string1 = [NSString stringWithFormat:@"with %@ discount",discountDescr];
            } else {
                totalUndiscounted += saleItemActualCharge;
                string1 = @"";
            }
            chargeAfterIndividualDiscounts += saleItemActualCharge;
            string2 = [NSString stringWithFormat:@"£%1.2f",saleItemActualCharge/100.0];
            col0 = [self writeString:string0 atY:y inColumn:0];
            col1 = [self writeString:string1 atY:y inColumn:1];
            col2 = [self writeString:string2 atY:y inColumn:2];
            rowHeight = fmax(col0.size.height, col1.size.height);
            rowHeight = fmax(rowHeight, col2.size.height);
            i++;
            y += rowHeight + 10;
        }
        NSUInteger extraDiscount = chargeAfterIndividualDiscounts - saleActualCharge;
        if (sale.discountType.doubleValue > AMCDiscountNone && extraDiscount > 0.005) {
            string0 = @"";
            string1 = @"Sub total:";
            string2 = [NSString stringWithFormat:@"£%1.2f",sale.chargeAfterIndividualDiscounts.doubleValue];
            col0 = [self writeString:string0 atY:y inColumn:0];
            col1 = [self writeString:string1 atY:y inColumn:1];
            col2 = [self writeString:string2 atY:y inColumn:2];
            rowHeight = fmax(col0.size.height, col1.size.height);
            rowHeight = fmax(rowHeight, col2.size.height);
            y += rowHeight + 10;
            string0 = @"";
            if (individualDiscounts == 0) {
                string1 = [NSString stringWithFormat:@"Discount %@",[AMCDiscountCalculator discountDescriptionforDiscount:sale.discountType.integerValue]];
            } else {
                string1 = [NSString stringWithFormat:@"Additional %@ discount",[AMCDiscountCalculator discountDescriptionforDiscount:sale.discountType.integerValue]];
            }
            string2 = [NSString stringWithFormat:@"-£%1.2f",extraDiscount/100.0];
            col0 = [self writeString:string0 atY:y inColumn:0];
            col1 = [self writeString:string1 atY:y inColumn:1];
            col2 = [self writeString:string2 atY:y inColumn:2];
            rowHeight = fmax(col0.size.height, col1.size.height);
            rowHeight = fmax(rowHeight, col2.size.height);
            y += rowHeight + 6;
        }
        [[NSColor blackColor] set];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(sideMargin, y) toPoint:NSMakePoint(pWidth, y)];
        y += 16;
        string0 = @"";
        string1 = @"Total:";
        string2 = [NSString stringWithFormat:@"£%1.2f",saleActualCharge/100.0];
        col0 = [self writeString:string0 atY:y inColumn:0];
        col1 = [self writeString:string1 atY:y inColumn:1];
        col2 = [self writeString:string2 atY:y inColumn:2];
        [context restoreGraphicsState];
        
        return YES;
    }];
}
-(double)columnWidth:(NSUInteger)col
{
    switch (col) {
        case 0:
        {
            return self.bodyRect.size.width / 2.0;
            break;
        }
        case 1:
        {
            return self.bodyRect.size.width / 4.0;
            break;
        }
        case 2:
        {
            return self.bodyRect.size.width / 12.0;
            break;
        }
    }
    return 0;
}
-(double)spaceBetweenColumns
{
    return (self.bodyRect.size.width - [self columnWidth:0] - [self columnWidth:1] - [self columnWidth:2])/2.0;
}
-(double)xPositionOfColumn:(NSUInteger)col
{
    switch (col) {
        case 0:
        {
            return self.bodyRect.origin.x;
            break;
        }
        case 1:
        {
            return [self columnWidth:0] + [self spaceBetweenColumns];
            break;
        }
        case 2:
        {
            return [self xPositionOfColumn:1] + [self columnWidth:1] + [self spaceBetweenColumns];
            break;
        }
    }
    return 0;
}
-(NSRect)writeString:(NSString*)string atY:(double)y inColumn:(NSUInteger)col
{
    NSPoint p = NSMakePoint([self xPositionOfColumn:col], y);
    NSSize maxSize = NSMakeSize([self columnWidth:col],NSUIntegerMax);
    NSRect rect = [string boundingRectWithSize:maxSize options:NSStringDrawingUsesLineFragmentOrigin attributes:nil];
    rect.origin = p;
    rect = [self backingAlignedRect:rect options:NSAlignAllEdgesOutward];
    [string drawInRect:rect withAttributes:nil];
    return rect;
}
-(NSRect)bodyRect
{
    return NSMakeRect(sideMargin, topMargin, pWidth, pHeight - topMargin - bottomMargin);
}

@end
