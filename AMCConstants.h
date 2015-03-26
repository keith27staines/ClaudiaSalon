//
//  AMCConstants.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 20/07/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const kAMCTillAccountName;
extern NSString * const kAMCBarclaysAccountName;
extern NSString * const kAMCPayPalAccountName;

extern NSString * const kAMCPaymentDirectionIn;
extern NSString * const kAMCPaymentDirectionOut;

extern NSString * const kAMCSystemCategories;
extern NSString * const kAMCCashbookCategories;
extern NSString * const kAMCServiceCategories;

extern NSString * const kAMCCashbookCategoryExpenditure;
extern NSString * const kAMCCashbookCategoryIncome;

extern NSString * const kAMCServiceCategoryHair;
extern NSString * const kAMCServiceCategoryBeauty;

typedef NS_ENUM(NSInteger, EditMode) {
    EditModeCreate,
    EditModeEdit,
    EditModeView,
};

typedef NS_ENUM(NSInteger, HairLength) {
    HairLengthNotApplicable = 0,
    HairLengthShort = 1,
    HairLengthMedium = 2,
    HairLengthLong = 3,
};
typedef NS_ENUM(NSInteger, AMCDiscount) {
    AMCDiscountMinimum = 0,
    AMCDiscountNone = 0,
    AMCDiscount5pc = 1,
    AMCDiscount10pc = 2,
    AMCDiscount20pc = 3,
    AMCDiscount30pc = 4,
    AMCDiscount40pc = 5,
    AMCDiscount50pc = 6,
    AMCDiscount100pc = 7,
    AMCDiscountLowestPound = 8,
    AMCDiscount1Pound = 8,
    AMCDiscount2Pound = 9,
    AMCDiscount5Pound = 10,
    AMCDiscount10Pound = 11,
    AMCDiscount20Pound = 12,
    AMCDiscount50Pound = 13,
    AMCDiscountMaximum = 13
};
typedef NS_ENUM(NSInteger, AMCancellationType) {
    AMCancellationTypeNotCancelled = 0,
    AMCancellationTypeCustomerCancelledLongNotice = 1,
    AMCancellationTypeCustomerCancelledShortNotice = 2,
    AMCancellationTypeCustomerNoShow = 3,
    AMCancellationTypeSalonUnavailable = 4,
    AMCancellationTypeSalonEquipmentFailure = 5,
    AMCancellationTypeSalonStaffAbsence = 6,
    AMCancellationTypeOther = NSIntegerMax,
};
typedef NS_ENUM(NSInteger, AMCompletionType) {
    AMCompletionTypeNotCompleted = 0,
    AMCompletionTypeCompletedWithoutConversionToQuote = 1,
    AMCompletionTypeCompletedWithConversionToQuote = 2,
};


