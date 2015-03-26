//
//  AMCStorePopulator.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 11/08/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "AMCStorePopulator.h"
#import "AppDelegate.h"
#import "AMCConstants.h"
#import "Payment+Methods.h"
#import "Product+Methods.h"
#import "Sale+Methods.h"
#import "Customer+Methods.h"
#import "Payment+Methods.h"
#import "Service+Methods.h"
#import "ServiceCategory+Methods.h"
#import "Employee+Methods.h"
#import "AMCSalonDocument.h"

Employee * amcEmployeeClaudia;
Employee * amcEmployeeCorina;
Employee * amcEmployeeLuminita;

ServiceCategory * amcscHairCutMen;
ServiceCategory * amcscHairCutWomen;
ServiceCategory * amcscHairStyling;
ServiceCategory * amcscHairColouring;
ServiceCategory * amcscHairHighlighting;
ServiceCategory * amcscHairPerming;
ServiceCategory * amcscWaxing;
ServiceCategory * amcscMakeup;
ServiceCategory * amcscManicure;
ServiceCategory * amcscPedicure;
ServiceCategory * amcscMassage;
ServiceCategory * amcscPackages;

Product * amcProductOPIGel;
Product * amcProductOPINailPolish;
Product * amcProductLorealNailPolish;
Product * amcProductLorealColour;
Product * amcProductLorealDamagedHairTreatment;
Product * amcProductNXTColour;
Product * amcProductPedicureWax;

// Hair cutting
Service * amcServiceHairCutMen;
Service * amcServiceHairCutMenWithWashAndBlowDry;
Service * amcServiceHairCutWomenShort;
Service * amcServiceHairCutWomenMedium;
Service * amcServiceHairCutWomenLong;
Service * amcServiceWashAndBlowDryShort;
Service * amcServiceWashAndBlowDryMedium;
Service * amcServiceWashAndBlowDryLong;
Service * amcServiceDamagedHairTreatmentShort;
Service * amcServiceDamagedHairTreatmentMedium;
Service * amcServiceDamagedHairTreatmentLong;

// Hair styling
Service * amcServiceHairStylingStraighteningShort;
Service * amcServiceHairStylingStraighteningMedium;
Service * amcServiceHairStylingStraighteningLong;
Service * amcServiceHairStylingCurlingShort;
Service * amcServiceHairStylingCurlingMedium;
Service * amcServiceHairStylingCurlingLong;
Service * amcServiceRestyleAllHair;
Service * amcServiceOccasionalStyleAllHair;

// Hair colouring
Service * amcServiceColouringShort;
Service * amcServiceColouringMedium;
Service * amcServiceColouringLong;
Service * amcServiceColouringShortDeluxe;
Service * amcServiceColouringMediumDeluxe;
Service * amcServiceColouringLongDeluxe;
Service * amcServiceHighlightingHalfHeadShort;
Service * amcServiceHighlightingHalfHeadMedium;
Service * amcServiceHighlightingHalfHeadLong;
Service * amcServiceHighlightingFullHeadShort;
Service * amcServiceHighlightingFullHeadMedium;
Service * amcServiceHighlightingFullHeadLong;
Service * amcServicePermingHeadShort;
Service * amcServicePermingMedium;
Service * amcServicePermingLong;
Service * amcServiceSpecialColouring;

// Manicure
Service * amcServiceStandardManicure;
Service * amcServiceExpressManicure;
Service * amcServiceNailsPolishOnly;
Service * amcServiceNailsPolishOnlyDeluxe;
Service * amcServiceNailsFullSet;
Service * amcServiceNailsTakeOff;
Service * amcServiceNailsRefill;
Service * amcServiceNailModellingAndDesign;
Service * amcServiceHandTreatmentForDamagedSkin;

// Pedicure
Service * amcServiceStandardPedicureCosmetic;
Service * amcServiceStandardPedicureMedical;
Service * amcServiceDeluxePedicureMedical;

// Makeup
Service * amcServiceMakeupDaytime;
Service * amcServiceMakeupEveningParty;
Service * amcServiceMakeupBridal;
Service * amcServiceEyebrowShaping;
Service * amcServiceEyebrowColour;
Service * amcServiceEyelashesOnly;
Service * amcServiceEyelashExtensionFullSet;

// Waxing
Service * amcServiceWaxingLip;
Service * amcServiceWaxingChin;
Service * amcServiceWaxingEyebrow;
Service * amcServiceWaxingEyebrowAndLip;
Service * amcServiceWaxingFullFace;
Service * amcServiceWaxingUnderarm;
Service * amcServiceWaxingHalfArms;
Service * amcServiceWaxingFullArms;
Service * amcServiceWaxingHollywood;
Service * amcServiceWaxingBrazilian;
Service * amcServiceWaxingBikini;
Service * amcServiceWaxingFullLeg;
Service * amcServiceWaxingHalfLeg;
Service * amcServiceWaxingThreeQuartersLeg;

// Packages
Service * amcServicePackageManicureAndPedicure;
Service * amcServicePackageWaxingFullBody;
Service * amcServicePackageHairCutStyleColour;

NSDate * amcsAutoLoadDate;

@implementation AMCStorePopulator

+(BOOL)populateDocument:(AMCSalonDocument*)document error:(NSError**)error
{
    amcsAutoLoadDate = [NSDate date];
    [self populateCategories:document error:error];
    [self populateProducts:document error:error];
    [self populateServices:document error:error];
    [self populateStaff:document error:error];
    return YES;
}
+(BOOL)populateCategories:(AMCSalonDocument*)document error:(NSError *__autoreleasing *)error {
    NSManagedObjectContext * moc = document.managedObjectContext;
    NSArray * categories = [ServiceCategory allObjectsWithMoc:moc];
    if (categories.count > 0) {
        return NO;
    }
    amcscHairCutMen = [ServiceCategory newObjectWithMoc:moc];
    amcscHairCutMen.name = @"Hair cut (men)";
    amcscHairCutWomen = [ServiceCategory newObjectWithMoc:moc];
    amcscHairCutWomen.name = @"Hair cut (women)";
    amcscHairStyling = [ServiceCategory newObjectWithMoc:moc];
    amcscHairStyling.name = @"Hair styling";
    amcscHairColouring = [ServiceCategory newObjectWithMoc:moc];
    amcscHairColouring.name = @"Hair colouring";
    amcscHairHighlighting = [ServiceCategory newObjectWithMoc:moc];
    amcscHairHighlighting.name = @"Hair highlighting";
    amcscHairPerming = [ServiceCategory newObjectWithMoc:moc];
    amcscHairPerming.name = @"Hair perming";
    amcscMakeup = [ServiceCategory newObjectWithMoc:moc];
    amcscMakeup.name = @"Makeup";
    amcscWaxing = [ServiceCategory newObjectWithMoc:moc];
    amcscWaxing.name = @"Waxing";
    amcscManicure = [ServiceCategory newObjectWithMoc:moc];
    amcscManicure.name = @"Manicure";
    amcscPedicure = [ServiceCategory newObjectWithMoc:moc];
    amcscPedicure.name = @"Pedicure";
    amcscMassage = [ServiceCategory newObjectWithMoc:moc];
    amcscMassage.name = @"Massage (women only)";
    amcscPackages = [ServiceCategory newObjectWithMoc:moc];
    amcscPackages.name = @"Packages";

    NSArray * allObjects = [ServiceCategory allObjectsWithMoc:moc];
    for (ServiceCategory * object in allObjects) {
        object.createdDate = amcsAutoLoadDate;
        object.lastUpdatedDate = amcsAutoLoadDate;
    }
    [document commitAndSave:nil];
    return YES;
}
+(BOOL)populateProducts:(AMCSalonDocument*)document error:(NSError**)error{
    NSManagedObjectContext * moc = document.managedObjectContext;
    NSArray * products = [Product allObjectsWithMoc:moc];
    if (products.count > 0) {
        return NO;
    }
    amcProductOPIGel = [Product newObjectWithMoc:moc];
    amcProductOPINailPolish    = [Product newObjectWithMoc:moc];
    amcProductLorealNailPolish = [Product newObjectWithMoc:moc];
    amcProductLorealColour     = [Product newObjectWithMoc:moc];
    amcProductNXTColour        = [Product newObjectWithMoc:moc];
    amcProductPedicureWax      = [Product newObjectWithMoc:moc];
    
    amcProductOPIGel.brandName             = @"OPI";
    amcProductOPIGel.productType           = @"Nail gel";
    
    amcProductOPINailPolish.brandName      = @"OPI";
    amcProductOPINailPolish.productType    = @"Nail polish";
    
    amcProductLorealNailPolish.brandName   = @"L'Oreal";
    amcProductLorealNailPolish.productType = @"Nail polish";
    
    amcProductLorealColour.brandName       = @"L'Oreal";
    amcProductLorealColour.productType     = @"Hair colour";
    
    amcProductNXTColour.brandName          = @"NXT";
    amcProductNXTColour.productType        = @"Hair colour";
    
    amcProductPedicureWax.brandName          = @"Salon's choice brand";
    amcProductPedicureWax.productType        = @"Pedicure treatment wax";
    
    NSArray * allObjects = [Product allObjectsWithMoc:moc];
    for (Product * object in allObjects) {
        object.createdDate = amcsAutoLoadDate;
        object.lastUpdatedDate = amcsAutoLoadDate;
    }
    [document commitAndSave:nil];
    return YES;
}
+(BOOL)populateServices:(AMCSalonDocument*)document error:(NSError**)error{
    NSManagedObjectContext * moc = document.managedObjectContext;
    NSArray * service = [Service allObjectsWithMoc:moc];
    if (service.count > 0) {
        return NO;
    }
    Service * s = nil;
    
    // Hair cutting
    amcServiceHairCutMen = [Service newObjectWithMoc:moc];
    s = amcServiceHairCutMen;
    s.name = @"Hair cut only (men)";
    s.minimumCharge = @(8);
    s.nominalCharge = @(8);
    s.maximumCharge = @(8);
    s.hairLength    = @(0);
    s.serviceCategory = amcscHairCutMen;
    
    amcServiceHairCutMenWithWashAndBlowDry = [Service newObjectWithMoc:moc];
    s = amcServiceHairCutMenWithWashAndBlowDry;
    s.name = @"Hair cut with wash & blow-dry (men)";
    s.minimumCharge = @(8);
    s.nominalCharge = @(8);
    s.maximumCharge = @(8);
    s.hairLength    = @(0);
    s.serviceCategory = amcscHairCutMen;
    
    amcServiceHairCutWomenShort = [Service newObjectWithMoc:moc];
    s = amcServiceHairCutWomenShort;
    s.name = @"Hair cut only (women - short hair)";
    s.minimumCharge = @(14);
    s.nominalCharge = @(14);
    s.maximumCharge = @(14);
    s.hairLength    = @(1);
    s.serviceCategory = amcscHairCutWomen;
    
    amcServiceHairCutWomenMedium = [Service newObjectWithMoc:moc];
    s = amcServiceHairCutWomenMedium;
    s.name = @"Hair cut only (women - medium hair)";
    s.minimumCharge = @(15);
    s.nominalCharge = @(15);
    s.maximumCharge = @(15);
    s.hairLength    = @(2);
    s.serviceCategory = amcscHairCutWomen;
    
    amcServiceHairCutWomenLong = [Service newObjectWithMoc:moc];
    s = amcServiceHairCutWomenLong;
    s.name = @"Hair cut only (women - long hair)";
    s.minimumCharge = @(16);
    s.nominalCharge = @(16);
    s.maximumCharge = @(16);
    s.hairLength    = @(3);
    s.serviceCategory = amcscHairCutWomen;
    
    amcServiceWashAndBlowDryShort = [Service newObjectWithMoc:moc];
    s = amcServiceWashAndBlowDryShort;
    s.name = @"Wash and blow dry (women - short hair)";
    s.minimumCharge = @(10);
    s.nominalCharge = @(10);
    s.maximumCharge = @(10);
    s.hairLength    = @(1);
    s.serviceCategory = amcscHairCutWomen;
    
    amcServiceWashAndBlowDryMedium = [Service newObjectWithMoc:moc];
    s = amcServiceWashAndBlowDryMedium;
    s.name = @"Wash and blow dry (women - medium hair)";
    s.minimumCharge = @(13);
    s.nominalCharge = @(13);
    s.maximumCharge = @(13);
    s.hairLength    = @(2);
    s.serviceCategory = amcscHairCutWomen;
    
    amcServiceWashAndBlowDryLong = [Service newObjectWithMoc:moc];
    s = amcServiceWashAndBlowDryLong;
    s.name = @"Wash and blow dry (women - long hair)";
    s.minimumCharge = @(15);
    s.nominalCharge = @(15);
    s.maximumCharge = @(15);
    s.hairLength    = @(3);
    s.serviceCategory = amcscHairCutWomen;
    
    amcServiceDamagedHairTreatmentShort = [Service newObjectWithMoc:moc];
    s = amcServiceDamagedHairTreatmentShort;
    s.name = @"Damaged hair treatment (short hair)";
    s.minimumCharge = @(4);
    s.nominalCharge = @(4);
    s.maximumCharge = @(4);
    s.hairLength    = @(1);
    s.serviceCategory = amcscHairCutWomen;
    
    amcServiceDamagedHairTreatmentMedium = [Service newObjectWithMoc:moc];
    s = amcServiceDamagedHairTreatmentMedium;
    s.name = @"Damaged hair treatment (medium hair)";
    s.minimumCharge = @(5);
    s.nominalCharge = @(5);
    s.maximumCharge = @(5);
    s.hairLength    = @(2);
    s.serviceCategory = amcscHairCutWomen;
    
    amcServiceDamagedHairTreatmentLong = [Service newObjectWithMoc:moc];
    s = amcServiceDamagedHairTreatmentLong;
    s.name = @"Damaged hair treatment (long hair)";
    s.minimumCharge = @(6);
    s.nominalCharge = @(6);
    s.maximumCharge = @(6);
    s.hairLength    = @(3);
    s.serviceCategory = amcscHairCutWomen;
    
    // Hair styling
    amcServiceHairStylingStraighteningShort = [Service newObjectWithMoc:moc];
    s = amcServiceHairStylingStraighteningShort;
    s.name = @"Straightening (short hair)";
    s.minimumCharge = @(20);
    s.nominalCharge = @(20);
    s.maximumCharge = @(20);
    s.hairLength    = @(1);
    s.serviceCategory = amcscHairStyling;
    
    amcServiceHairStylingStraighteningMedium = [Service newObjectWithMoc:moc];
    s = amcServiceHairStylingStraighteningMedium;
    s.name = @"Straightening (medium hair)";
    s.minimumCharge = @(23);
    s.nominalCharge = @(23);
    s.maximumCharge = @(23);
    s.hairLength    = @(2);
    s.serviceCategory = amcscHairStyling;
    
    amcServiceHairStylingStraighteningLong = [Service newObjectWithMoc:moc];
    s = amcServiceHairStylingStraighteningLong;
    s.name = @"Straightening (long hair)";
    s.minimumCharge = @(25);
    s.nominalCharge = @(25);
    s.maximumCharge = @(25);
    s.hairLength    = @(1);
    s.serviceCategory = amcscHairStyling;
    
    amcServiceHairStylingCurlingShort = [Service newObjectWithMoc:moc];
    s = amcServiceHairStylingCurlingShort;
    s.name = @"Curling (short hair)";
    s.minimumCharge = @(20);
    s.nominalCharge = @(20);
    s.maximumCharge = @(20);
    s.hairLength    = @(1);
    s.serviceCategory = amcscHairStyling;
    
    amcServiceHairStylingCurlingMedium = [Service newObjectWithMoc:moc];
    s = amcServiceHairStylingCurlingMedium;
    s.name = @"Curling (medium hair)";
    s.minimumCharge = @(23);
    s.nominalCharge = @(23);
    s.maximumCharge = @(23);
    s.hairLength    = @(2);
    s.serviceCategory = amcscHairStyling;
    
    amcServiceHairStylingCurlingLong = [Service newObjectWithMoc:moc];
    s = amcServiceHairStylingCurlingLong;
    s.name = @"Curling (long hair)";
    s.minimumCharge = @(25);
    s.nominalCharge = @(25);
    s.maximumCharge = @(25);
    s.hairLength    = @(1);
    s.serviceCategory = amcscHairStyling;
    
    amcServiceRestyleAllHair = [Service newObjectWithMoc:moc];
    s = amcServiceRestyleAllHair;
    s.name = @"Hair restyling";
    s.minimumCharge = @(25);
    s.nominalCharge = @(30);
    s.maximumCharge = @(35);
    s.hairLength    = @(0);
    s.serviceCategory = amcscHairStyling;
    
    amcServiceOccasionalStyleAllHair = [Service newObjectWithMoc:moc];
    s = amcServiceOccasionalStyleAllHair;
    s.name = @"Occasional styling (and bridal)";
    s.minimumCharge = @(25);
    s.nominalCharge = @(50);
    s.maximumCharge = @(115);
    s.hairLength    = @(0);
    s.serviceCategory = amcscHairStyling;
    
    // Hair colouring
    amcServiceColouringShort = [Service newObjectWithMoc:moc];
    s = amcServiceColouringShort;
    s.name = @"Colouring (standard, short hair)";
    s.minimumCharge = @(29);
    s.nominalCharge = @(29);
    s.maximumCharge = @(29);
    s.hairLength    = @(1);
    s.serviceCategory = amcscHairColouring;
    
    amcServiceColouringMedium = [Service newObjectWithMoc:moc];
    s = amcServiceColouringMedium;
    s.name = @"Colouring (standard, medium hair)";
    s.minimumCharge = @(34);
    s.nominalCharge = @(34);
    s.maximumCharge = @(34);
    s.hairLength    = @(2);
    s.serviceCategory = amcscHairColouring;
    
    amcServiceColouringLong = [Service newObjectWithMoc:moc];
    s = amcServiceColouringLong;
    s.name = @"Colouring (standard, long hair)";
    s.minimumCharge = @(39);
    s.nominalCharge = @(39);
    s.maximumCharge = @(39);
    s.hairLength    = @(3);
    s.serviceCategory = amcscHairColouring;
    
    amcServiceColouringShortDeluxe = [Service newObjectWithMoc:moc];
    s = amcServiceColouringShortDeluxe;
    s.name = @"Colouring (deluxe, short hair)";
    s.minimumCharge = @(33);
    s.nominalCharge = @(33);
    s.maximumCharge = @(33);
    s.hairLength    = @(1);
    s.serviceCategory = amcscHairColouring;
    s.deluxe = @(YES);
    [s addProductObject:amcProductLorealColour];
    
    amcServiceColouringMediumDeluxe = [Service newObjectWithMoc:moc];
    s = amcServiceColouringMediumDeluxe;
    s.name = @"Colouring (deluxe, medium hair)";
    s.minimumCharge = @(38);
    s.nominalCharge = @(38);
    s.maximumCharge = @(48);
    s.hairLength    = @(1);
    s.serviceCategory = amcscHairColouring;
    s.deluxe = @(YES);
    [s addProductObject:amcProductLorealColour];
    
    amcServiceColouringLongDeluxe = [Service newObjectWithMoc:moc];
    s = amcServiceColouringLongDeluxe;
    s.name = @"Colouring (deluxe, long hair)";
    s.minimumCharge = @(43);
    s.nominalCharge = @(43);
    s.maximumCharge = @(43);
    s.hairLength    = @(3);
    s.serviceCategory = amcscHairColouring;
    s.deluxe = @(YES);
    [s addProductObject:amcProductLorealColour];
    
    amcServiceSpecialColouring = [Service newObjectWithMoc:moc];
    s = amcServiceSpecialColouring;
    s.name = @"Special Colouring";
    s.minimumCharge = @(30);
    s.nominalCharge = @(45);
    s.maximumCharge = @(60);
    s.serviceCategory = amcscHairColouring;

    
    // Highlighting
    amcServiceHighlightingHalfHeadShort = [Service newObjectWithMoc:moc];
    s = amcServiceHighlightingHalfHeadShort;
    s.name = @"Highlighting (half-head, short hair)";
    s.minimumCharge = @(23);
    s.nominalCharge = @(23);
    s.maximumCharge = @(23);
    s.hairLength    = @(1);
    s.serviceCategory = amcscHairHighlighting;
    
    amcServiceHighlightingHalfHeadMedium = [Service newObjectWithMoc:moc];
    s = amcServiceHighlightingHalfHeadMedium;
    s.name = @"Highlighting (half-head, medium hair)";
    s.minimumCharge = @(28);
    s.nominalCharge = @(28);
    s.maximumCharge = @(28);
    s.hairLength    = @(2);
    s.serviceCategory = amcscHairHighlighting;
    
    amcServiceHighlightingHalfHeadLong = [Service newObjectWithMoc:moc];
    s = amcServiceHighlightingHalfHeadLong;
    s.name = @"Highlighting (half-head, long hair)";
    s.minimumCharge = @(30);
    s.nominalCharge = @(30);
    s.maximumCharge = @(30);
    s.hairLength    = @(3);
    s.serviceCategory = amcscHairHighlighting;
    
    amcServiceHighlightingFullHeadShort = [Service newObjectWithMoc:moc];
    s = amcServiceHighlightingFullHeadShort;
    s.name = @"Highlighting (full-head, short hair)";
    s.minimumCharge = @(45);
    s.nominalCharge = @(45);
    s.maximumCharge = @(45);
    s.hairLength    = @(1);
    s.serviceCategory = amcscHairHighlighting;
    
    amcServiceHighlightingFullHeadMedium = [Service newObjectWithMoc:moc];
    s = amcServiceHighlightingFullHeadMedium;
    s.name = @"Highlighting (full-head, medium hair)";
    s.minimumCharge = @(55);
    s.nominalCharge = @(55);
    s.maximumCharge = @(55);
    s.hairLength    = @(2);
    s.serviceCategory = amcscHairHighlighting;
    
    amcServiceHighlightingFullHeadLong = [Service newObjectWithMoc:moc];
    s = amcServiceHighlightingFullHeadLong;
    s.name = @"Highlighting (full-head, long hair)";
    s.minimumCharge = @(60);
    s.nominalCharge = @(60);
    s.maximumCharge = @(60);
    s.hairLength    = @(3);
    s.serviceCategory = amcscHairHighlighting;
    
    amcServicePermingHeadShort = [Service newObjectWithMoc:moc];
    s = amcServicePermingHeadShort;
    s.name = @"Perming (short hair)";
    s.minimumCharge = @(40);
    s.nominalCharge = @(40);
    s.maximumCharge = @(40);
    s.hairLength    = @(1);
    s.serviceCategory = amcscHairPerming;
    
    amcServicePermingMedium = [Service newObjectWithMoc:moc];
    s = amcServicePermingMedium;
    s.name = @"Perming (medium hair)";
    s.minimumCharge = @(45);
    s.nominalCharge = @(45);
    s.maximumCharge = @(45);
    s.hairLength    = @(2);
    s.serviceCategory = amcscHairPerming;
    
    amcServicePermingLong = [Service newObjectWithMoc:moc];
    s = amcServicePermingLong;
    s.name = @"Perming (long hair)";
    s.minimumCharge = @(50);
    s.nominalCharge = @(50);
    s.maximumCharge = @(50);
    s.hairLength    = @(2);
    s.serviceCategory = amcscHairPerming;
    
    // Manicure
    amcServiceStandardManicure = [Service newObjectWithMoc:moc];
    s = amcServiceStandardManicure;
    s.name = @"Manicure (standard)";
    s.minimumCharge = @(15);
    s.nominalCharge = @(15);
    s.maximumCharge = @(15);
    s.hairLength    = @(0);
    s.serviceCategory = amcscManicure;
    s.deluxe = @(NO);
    [s addProductObject:amcProductOPINailPolish];
    [s addProductObject:amcProductLorealNailPolish];

    amcServiceExpressManicure = [Service newObjectWithMoc:moc];
    s = amcServiceExpressManicure;
    s.name = @"Manicure (deluxe)";
    s.minimumCharge = @(25);
    s.nominalCharge = @(25);
    s.maximumCharge = @(25);
    s.hairLength    = @(0);
    s.serviceCategory = amcscManicure;
    s.deluxe = @(YES);
    [s addProductObject:amcProductOPIGel];
    
    amcServiceNailsPolishOnly = [Service newObjectWithMoc:moc];
    s = amcServiceNailsPolishOnly;
    s.name = @"Nail polish (standard)";
    s.minimumCharge = @(5);
    s.nominalCharge = @(5);
    s.maximumCharge = @(5);
    s.hairLength    = @(0);
    s.serviceCategory = amcscManicure;
    s.deluxe = @(NO);
    [s addProductObject:amcProductOPINailPolish];
    [s addProductObject:amcProductLorealNailPolish];
    
    amcServiceNailsPolishOnlyDeluxe = [Service newObjectWithMoc:moc];
    s = amcServiceNailsPolishOnlyDeluxe;
    s.name = @"Nail polish (deluxe)";
    s.minimumCharge = @(10);
    s.nominalCharge = @(10);
    s.maximumCharge = @(10);
    s.hairLength    = @(0);
    s.serviceCategory = amcscManicure;
    s.deluxe = @(YES);
    [s addProductObject:amcProductOPINailPolish];
    [s addProductObject:amcProductLorealNailPolish];
    
    amcServiceNailsFullSet = [Service newObjectWithMoc:moc];
    s = amcServiceNailsFullSet;
    s.name = @"Nails - Full set";
    s.minimumCharge = @(35);
    s.nominalCharge = @(35);
    s.maximumCharge = @(35);
    s.hairLength    = @(0);
    s.serviceCategory = amcscManicure;
    s.deluxe = @(NO);
    
    amcServiceNailsRefill = [Service newObjectWithMoc:moc];
    s = amcServiceNailsRefill;
    s.name = @"Nails - Refill only";
    s.minimumCharge = @(17);
    s.nominalCharge = @(17);
    s.maximumCharge = @(17);
    s.hairLength    = @(0);
    s.serviceCategory = amcscManicure;
    s.deluxe = @(NO);
    
    amcServiceNailsTakeOff = [Service newObjectWithMoc:moc];
    s = amcServiceNailsTakeOff;
    s.name = @"Nails - Take-off nails";
    s.minimumCharge = @(15);
    s.nominalCharge = @(15);
    s.maximumCharge = @(15);
    s.hairLength    = @(0);
    s.serviceCategory = amcscManicure;
    s.deluxe = @(NO);
    
    amcServiceNailModellingAndDesign = [Service newObjectWithMoc:moc];
    s = amcServiceNailModellingAndDesign;
    s.name = @"Nail modelling and design";
    s.minimumCharge = @(5);
    s.nominalCharge = @(8);
    s.maximumCharge = @(10);
    s.hairLength    = @(0);
    s.serviceCategory = amcscManicure;
    s.deluxe = @(NO);
    
    amcServiceHandTreatmentForDamagedSkin = [Service newObjectWithMoc:moc];
    s = amcServiceHandTreatmentForDamagedSkin;
    s.name = @"Treat damaged skin on hands";
    s.minimumCharge = @(10);
    s.nominalCharge = @(10);
    s.maximumCharge = @(10);
    s.hairLength    = @(0);
    s.serviceCategory = amcscManicure;
    s.deluxe = @(NO);
    
    // Pedicure
    amcServiceStandardPedicureCosmetic = [Service newObjectWithMoc:moc];
    s = amcServiceStandardPedicureCosmetic;
    s.name = @"Pedicure (cosmetic)";
    s.minimumCharge = @(25);
    s.nominalCharge = @(25);
    s.maximumCharge = @(25);
    s.hairLength    = @(0);
    s.serviceCategory = amcscPedicure;
    s.deluxe = @(NO);
    [s addProductObject:amcProductOPINailPolish];
    [s addProductObject:amcProductLorealNailPolish];
    
    amcServiceStandardPedicureMedical = [Service newObjectWithMoc:moc];
    s = amcServiceStandardPedicureMedical;
    s.name = @"Pedicure (medical - standard)";
    s.minimumCharge = @(40);
    s.nominalCharge = @(40);
    s.maximumCharge = @(40);
    s.hairLength    = @(0);
    s.serviceCategory = amcscPedicure;
    s.deluxe = @(NO);
    [s addProductObject:amcProductOPINailPolish];
    [s addProductObject:amcProductLorealNailPolish];
    
    amcServiceDeluxePedicureMedical = [Service newObjectWithMoc:moc];
    s = amcServiceDeluxePedicureMedical;
    s.name = @"Pedicure (medical - deluxe)";
    s.minimumCharge = @(43);
    s.nominalCharge = @(43);
    s.maximumCharge = @(43);
    s.hairLength    = @(0);
    s.serviceCategory = amcscPedicure;
    s.deluxe = @(NO);
    [s addProductObject:amcProductOPIGel];

    // Makeup
    amcServiceMakeupDaytime = [Service newObjectWithMoc:moc];
    s = amcServiceMakeupDaytime;
    s.name = @"Makeup (for daytime)";
    s.minimumCharge = @(25);
    s.nominalCharge = @(25);
    s.maximumCharge = @(25);
    s.hairLength    = @(0);
    s.serviceCategory = amcscMakeup;
    s.deluxe = @(NO);
    
    amcServiceMakeupEveningParty = [Service newObjectWithMoc:moc];
    s = amcServiceMakeupEveningParty;
    s.name = @"Makeup (for evening/party)";
    s.minimumCharge = @(25);
    s.nominalCharge = @(50);
    s.maximumCharge = @(115);
    s.hairLength    = @(0);
    s.serviceCategory = amcscMakeup;
    s.deluxe = @(NO);
    
    amcServiceMakeupBridal = [Service newObjectWithMoc:moc];
    s = amcServiceMakeupBridal;
    s.name = @"Makeup (for bridal)";
    s.minimumCharge = @(25);
    s.nominalCharge = @(50);
    s.maximumCharge = @(200);
    s.hairLength    = @(0);
    s.serviceCategory = amcscMakeup;
    s.deluxe = @(NO);
    
    amcServiceEyebrowShaping = [Service newObjectWithMoc:moc];
    s = amcServiceEyebrowShaping;
    s.name = @"Eyebrow shaping (tweezers)";
    s.minimumCharge = @(6);
    s.nominalCharge = @(7);
    s.maximumCharge = @(8);
    s.hairLength    = @(0);
    s.serviceCategory = amcscMakeup;
    s.deluxe = @(NO);
    
    amcServiceEyebrowColour = [Service newObjectWithMoc:moc];
    s = amcServiceEyebrowColour;
    s.name = @"Eyebrow colouring";
    s.minimumCharge = @(10);
    s.nominalCharge = @(11);
    s.maximumCharge = @(12);
    s.hairLength    = @(0);
    s.serviceCategory = amcscMakeup;
    s.deluxe = @(NO);
    
    amcServiceEyelashesOnly = [Service newObjectWithMoc:moc];
    s = amcServiceEyelashesOnly;
    s.name = @"Eyelashes only";
    s.minimumCharge = @(15);
    s.nominalCharge = @(15);
    s.maximumCharge = @(15);
    s.hairLength    = @(0);
    s.serviceCategory = amcscMakeup;
    s.deluxe = @(NO);
    
    amcServiceEyelashExtensionFullSet = [Service newObjectWithMoc:moc];
    s = amcServiceEyelashExtensionFullSet;
    s.name = @"Eyelash extension (full set)";
    s.minimumCharge = @(35);
    s.nominalCharge = @(35);
    s.maximumCharge = @(35);
    s.hairLength    = @(0);
    s.serviceCategory = amcscMakeup;
    s.deluxe = @(NO);
    
    // Waxing
    amcServiceWaxingLip = [Service newObjectWithMoc:moc];
    s = amcServiceWaxingLip;
    s.name = @"Wax Lip";
    s.minimumCharge = @(7);
    s.nominalCharge = @(7);
    s.maximumCharge = @(7);
    s.hairLength    = @(0);
    s.serviceCategory = amcscWaxing;
    s.deluxe = @(NO);
    s.expectedTimeRequired = @(5);
    
    amcServiceWaxingChin = [Service newObjectWithMoc:moc];
    s = amcServiceWaxingChin;
    s.name = @"Wax Chin";
    s.minimumCharge = @(7);
    s.nominalCharge = @(7);
    s.maximumCharge = @(7);
    s.hairLength    = @(0);
    s.serviceCategory = amcscWaxing;
    s.deluxe = @(NO);
    s.expectedTimeRequired = @(5);
    
    amcServiceWaxingEyebrow = [Service newObjectWithMoc:moc];
    s = amcServiceWaxingEyebrow;
    s.name = @"Wax Eyebrows";
    s.minimumCharge = @(7);
    s.nominalCharge = @(7);
    s.maximumCharge = @(7);
    s.hairLength    = @(0);
    s.serviceCategory = amcscWaxing;
    s.deluxe = @(NO);
    s.expectedTimeRequired = @(10);
    
    amcServiceWaxingEyebrowAndLip = [Service newObjectWithMoc:moc];
    s = amcServiceWaxingEyebrowAndLip;
    s.name = @"Wax Eyebrows and Lip";
    s.minimumCharge = @(10);
    s.nominalCharge = @(10);
    s.maximumCharge = @(10);
    s.hairLength    = @(0);
    s.serviceCategory = amcscWaxing;
    s.deluxe = @(NO);
    s.expectedTimeRequired = @(15);

    amcServiceWaxingFullFace = [Service newObjectWithMoc:moc];
    s = amcServiceWaxingFullFace;
    s.name = @"Wax Face (other areas)";
    s.minimumCharge = @(20);
    s.nominalCharge = @(20);
    s.maximumCharge = @(20);
    s.hairLength    = @(0);
    s.serviceCategory = amcscWaxing;
    s.deluxe = @(NO);
    s.expectedTimeRequired = @(15);
    
    amcServiceWaxingUnderarm = [Service newObjectWithMoc:moc];
    s = amcServiceWaxingUnderarm;
    s.name = @"Wax Underarms";
    s.minimumCharge = @(11);
    s.nominalCharge = @(12);
    s.maximumCharge = @(14);
    s.hairLength    = @(0);
    s.serviceCategory = amcscWaxing;
    s.deluxe = @(NO);
    s.expectedTimeRequired = @(15);
    
    amcServiceWaxingHalfArms = [Service newObjectWithMoc:moc];
    s = amcServiceWaxingHalfArms;
    s.name = @"Wax Half Arms";
    s.minimumCharge = @(9);
    s.nominalCharge = @(11);
    s.maximumCharge = @(13);
    s.hairLength    = @(0);
    s.serviceCategory = amcscWaxing;
    s.deluxe = @(NO);
    s.expectedTimeRequired = @(15);
    
    amcServiceWaxingFullArms = [Service newObjectWithMoc:moc];
    s = amcServiceWaxingFullArms;
    s.name = @"Wax Full Arms";
    s.minimumCharge = @(19);
    s.nominalCharge = @(23);
    s.maximumCharge = @(26);
    s.hairLength    = @(0);
    s.serviceCategory = amcscWaxing;
    s.deluxe = @(NO);
    s.expectedTimeRequired = @(30);
    
    amcServiceWaxingHollywood = [Service newObjectWithMoc:moc];
    s = amcServiceWaxingHollywood;
    s.name = @"Bikini (hollywood)";
    s.minimumCharge = @(36);
    s.nominalCharge = @(42);
    s.maximumCharge = @(48);
    s.hairLength    = @(0);
    s.serviceCategory = amcscWaxing;
    s.deluxe = @(NO);
    s.expectedTimeRequired = @(40);
    
    amcServiceWaxingBrazilian = [Service newObjectWithMoc:moc];
    s = amcServiceWaxingBrazilian;
    s.name = @"Bikini (brazilian)";
    s.minimumCharge = @(30);
    s.nominalCharge = @(32);
    s.maximumCharge = @(34);
    s.hairLength    = @(0);
    s.serviceCategory = amcscWaxing;
    s.deluxe = @(NO);
    s.expectedTimeRequired = @(30);
    
    amcServiceWaxingBikini = [Service newObjectWithMoc:moc];
    s = amcServiceWaxingBikini;
    s.name = @"Bikini (bikini)";
    s.minimumCharge = @(18);
    s.nominalCharge = @(20);
    s.maximumCharge = @(23);
    s.hairLength    = @(0);
    s.serviceCategory = amcscWaxing;
    s.deluxe = @(NO);
    s.expectedTimeRequired = @(15);
    
    amcServiceWaxingFullLeg = [Service newObjectWithMoc:moc];
    s = amcServiceWaxingFullLeg;
    s.name = @"Wax Full Legs";
    s.minimumCharge = @(24);
    s.nominalCharge = @(28);
    s.maximumCharge = @(31);
    s.hairLength    = @(0);
    s.serviceCategory = amcscWaxing;
    s.deluxe = @(NO);
    s.expectedTimeRequired = @(30);
    
    amcServiceWaxingHalfLeg = [Service newObjectWithMoc:moc];
    s = amcServiceWaxingHalfLeg;
    s.name = @"Wax Half Legs";
    s.minimumCharge = @(18);
    s.nominalCharge = @(20);
    s.maximumCharge = @(23);
    s.hairLength    = @(0);
    s.serviceCategory = amcscWaxing;
    s.deluxe = @(NO);
    s.expectedTimeRequired = @(15);
    
    amcServiceWaxingThreeQuartersLeg = [Service newObjectWithMoc:moc];
    s = amcServiceWaxingThreeQuartersLeg;
    s.name = @"Wax Three-quarter Legs";
    s.minimumCharge = @(20);
    s.nominalCharge = @(23);
    s.maximumCharge = @(26);
    s.hairLength    = @(0);
    s.serviceCategory = amcscWaxing;
    s.deluxe = @(NO);
    s.expectedTimeRequired = @(18);
    
    // Packages
    amcServicePackageManicureAndPedicure = [Service newObjectWithMoc:moc];
    s = amcServicePackageManicureAndPedicure;
    s.name = @"Manicure & Pedicure";
    s.minimumCharge = @(60);
    s.nominalCharge = @(60);
    s.maximumCharge = @(60);
    s.hairLength    = @(0);
    s.serviceCategory = amcscPackages;
    s.deluxe = @(NO);
    
    amcServicePackageWaxingFullBody = [Service newObjectWithMoc:moc];
    s = amcServicePackageWaxingFullBody;
    s.name = @"Full Body Wax";
    s.minimumCharge = @(97);
    s.nominalCharge = @(97);
    s.maximumCharge = @(97);
    s.hairLength    = @(0);
    s.serviceCategory = amcscPackages;
    s.deluxe = @(NO);

    amcServicePackageHairCutStyleColour = [Service newObjectWithMoc:moc];
    s = amcServicePackageHairCutStyleColour;
    s.name = @"Colour, Cut & Restyle";
    s.minimumCharge = @(50);
    s.nominalCharge = @(50);
    s.maximumCharge = @(50);
    s.hairLength    = @(0);
    s.serviceCategory = amcscPackages;
    s.deluxe = @(NO);

    NSArray * allObjects = [Service allObjectsWithMoc:moc];
    for (Service * object in allObjects) {
        object.createdDate = amcsAutoLoadDate;
        object.lastUpdatedDate = amcsAutoLoadDate;
    }
    [document commitAndSave:nil];
    return YES;
}
+(BOOL)populateStaff:(AMCSalonDocument*)document error:(NSError**)error{
    NSManagedObjectContext * moc = document.managedObjectContext;
    NSArray * employees = [Employee allObjectsWithMoc:moc];
    if (employees.count > 0) {
        return NO;
    }
    [document commitAndSave:nil];
    return YES;
}
@end
