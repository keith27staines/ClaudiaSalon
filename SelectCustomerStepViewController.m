//
//  SelectCustomerStepViewController.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 27/07/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "SelectCustomerStepViewController.h"
#import "AMCConstants.h"
#import "Sale.h"
#import "Customer.h"
#import "AMCSalonDocument.h"
#import "NSDate+AMCDate.h"

@interface SelectCustomerStepViewController ()
{
    NSMutableArray * _customers;
}
@property (readonly) NSMutableArray * customers;
@property (readonly) Sale * sale;
@property (weak) IBOutlet NSButton *selectAnonymousCustomerButton;

@end

@implementation SelectCustomerStepViewController

-(NSString *)nibName
{
    return @"SelectCustomerStepViewController";
}
-(void)reloadData {
    _customers = nil;
    [self.customersTable reloadData];
}
-(IBAction)clearButton:(id)sender
{
    [self clear];
    [self customers];
}

-(IBAction)createCustomer:(id)sender {
    Customer *customer = [Customer createObjectInMoc:self.documentMoc];
    customer.firstName = [self.firstName.stringValue capitalizedString];
    customer.lastName = [self.lastName.stringValue capitalizedString];
    customer.phone = self.phone.stringValue;
    customer.email = [self.email.stringValue lowercaseString];
    customer.postcode = [self.postcode.stringValue uppercaseString];
    customer.addressLine1 = [self.addressLine1.stringValue capitalizedString];
    customer.addressLine2 = [self.addressLine2.stringValue capitalizedString];
    customer.monthOfBirth = @(self.dayAndMonthContoller.monthNumber);
    customer.dayOfBirth = @(self.dayAndMonthContoller.dayNumber);
    _customers = nil;
    [self.customersTable reloadData];
    [self setLabelText];
}
-(void)clear
{
    [super clear];
    _customers = nil;
    self.firstName.stringValue = @"";
    self.lastName.stringValue = @"";
    self.phone.stringValue = @"";
    self.email.stringValue = @"";
    self.postcode.stringValue = @"";
    self.addressLine1.stringValue = @"";
    self.addressLine2.stringValue = @"";
    [self.dayAndMonthContoller selectMonthNumber:0 dayNumber:0];
    [self.view.window makeFirstResponder:self.firstName];
    [self filtersUpdated];
    if (![self.view.window makeFirstResponder:nil]) {
        [self.view.window endEditingFor:nil];
    }
}
- (IBAction)selectAnonymousCustomer:(id)sender {
    [self.view.window makeFirstResponder:self.customersTable];
    self.sale.customer = self.salonDocument.anonymousCustomer;
    [self applyEditMode:self.editMode];
    // Next line trials automatically moving on from select customer screen if the user uses the "select anonymous customer" button.
    // Result of this simple delay is effective but not smooth. Really need a proper transition
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [self.delegate requestMoveToNextStep:self];
//    });
}

-(void)applyEditMode:(EditMode)editMode
{
    BOOL enableEditing = (editMode == EditModeCreate);
    [self.clearButton setEnabled:enableEditing];
    [self.firstName setEditable:enableEditing];
    [self.lastName setEditable:enableEditing];
    [self.phone setEditable:enableEditing];
    [self.email setEditable:enableEditing];
    [self.postcode setEditable:enableEditing];
    [self.addressLine1 setEditable:enableEditing];
    [self.addressLine2 setEditable:enableEditing];
    [self.createCustomerButton setEnabled:enableEditing];
    [self.dayAndMonthContoller setEnabled:enableEditing];
    [self.selectAnonymousCustomerButton setEnabled:enableEditing];
    [self populate];
}
-(void)populate
{
    Customer * customer = self.sale.customer;
    if (customer) {
        self.firstName.stringValue = customer.firstName;
        self.lastName.stringValue = customer.lastName;
        self.phone.stringValue = customer.phone;
        self.email.stringValue = customer.email;
        self.postcode.stringValue = customer.postcode;
        self.addressLine1.stringValue = customer.addressLine1;
        self.addressLine2.stringValue = customer.addressLine2;
        [self.dayAndMonthContoller selectMonthNumber:customer.monthOfBirth.integerValue dayNumber:customer.dayOfBirth.integerValue];
        [self filtersUpdated];
        NSInteger i = [self.customers indexOfObject:customer];
        [self.customersTable selectRowIndexes:[NSIndexSet indexSetWithIndex:i] byExtendingSelection:NO];
    } else {
        self.firstName.stringValue = @"";
        self.lastName.stringValue = @"";
        self.phone.stringValue = @"";
        self.email.stringValue = @"";
        self.postcode.stringValue = @"";
        self.addressLine1.stringValue = @"";
        self.addressLine2.stringValue = @"";
        [self.dayAndMonthContoller selectMonthNumber:0 dayNumber:0];
        [self filtersUpdated];
    }
    [self setLabelText];
}
-(Sale *)sale
{
    return [self.delegate wizardStepRequiresSale:self];
}
-(NSMutableArray *)customers
{
    if (!_customers) {
        NSManagedObjectContext * moc = self.documentMoc;
        NSEntityDescription *entityDescription = [NSEntityDescription
                                                  entityForName:@"Customer" inManagedObjectContext:moc];
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setEntity:entityDescription];
        
        // Set predicate and sort orderings...
        NSPredicate *predicate = [self predicate];
        if (predicate) {
            [request setPredicate:predicate];
        }
        NSError *error = nil;
        _customers = [[moc executeFetchRequest:request error:&error] mutableCopy];
        if (!_customers) {
            _customers = [@[] mutableCopy];
        }
        [self.customersTable deselectAll:self];
    }
    return _customers;
}
-(id)objectForWizardStep
{
    Customer * customer = [self selectedCustomer];
    return customer;
}
-(Customer *)selectedCustomer
{
    NSInteger selectedIndex = NSNotFound;
    if (self.customers.count == 1) {
        selectedIndex = 0;
    } else {
        selectedIndex = self.customersTable.selectedRow;
    }
    if (selectedIndex >= 0) {
        return self.customers[selectedIndex];
    }
    return nil;
}
-(void)setLabelText
{
    NSColor * paleRed = [NSColor colorWithCalibratedRed:0.8 green:0 blue:0 alpha:1];
    NSColor * white = [NSColor whiteColor];
    NSColor * paleGreen = [NSColor colorWithCalibratedRed:0 green:0.8 blue:0 alpha:1];
    NSColor * amber = [NSColor colorWithCalibratedRed:1 green:0.4 blue:0 alpha:1];
    BOOL customerSelected = NO;
    BOOL canCreateCustomer = NO;
    NSString * info;
    switch (_customers.count) {
        case 0:
        {
            if ([self detailsSufficientToCreateCustomer]) {
                info = [NSString stringWithFormat:@"%@\n\n%@", @"No existing customer matches these details.",@"There is enough information to create a new customer"];
                customerSelected = NO;
                canCreateCustomer = YES;
            } else {
                info = [NSString stringWithFormat:@"%@\n\n%@", @"No existing customer matches these details.",@"More information is required before you can create a new customer."];
                customerSelected = NO;
                canCreateCustomer = NO;
            }
            break;
        }
        case 1:
        {
            Customer * customer = [self selectedCustomer];
            info = @"One matching Customer found";
            info = [info stringByAppendingFormat:@"\nNumber of previous visits: %@",@(customer.sales.count)];
            info = [info stringByAppendingFormat:@"\nTotal money spent: £%1.2f",customer.totalMoneySpent.doubleValue];
            info = [info stringByAppendingFormat:@"\nTotal money refunded: £%1.2f",customer.totalMoneyRefunded.doubleValue];
            [self.customersTable selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
            customerSelected = YES;
            canCreateCustomer = NO;
            break;
        }
        default:
        {
            if (self.customersTable.selectedRowIndexes.count == 1) {
                Customer * customer = [self selectedCustomer];
                info = @"Matching customer selected.";
                info = [info stringByAppendingFormat:@"\nNumber of previous visits: %@",@(customer.sales.count)];
                info = [info stringByAppendingFormat:@"\nTotal money spent: £%1.2f",customer.totalMoneySpent.doubleValue];
                info = [info stringByAppendingFormat:@"\nTotal money refunded: £%1.2f",customer.totalMoneyRefunded.doubleValue];
                customerSelected = YES;
                canCreateCustomer = NO;
            } else {
                NSString * infoPart1 = [NSString stringWithFormat:@"There are %@ matching customers",@(_customers.count)];
                info = [NSString stringWithFormat:@"%@\n\n%@", infoPart1,@"Add more details or select a customer from the list"];
                customerSelected = NO;
                canCreateCustomer = NO;
            }
            break;
        }
    }
    [self.instructionLabel setStringValue:info];
    if (customerSelected) {
        [self.delegate wizardStep:self isValid:YES];
        self.instructionLabel.backgroundColor = paleGreen;
        self.instructionLabel.textColor = white;
        self.isValid = YES;
        [self.createCustomerButton setHidden:YES];
    } else {
        [self.delegate wizardStep:self isValid:NO];
        if (canCreateCustomer) {
            self.instructionLabel.backgroundColor = amber;
            [self.createCustomerButton setHidden:NO];
            [self.createCustomerButton setBezelStyle:NSRoundedBezelStyle];
            [self.view.window setDefaultButtonCell:[self.createCustomerButton cell]];
            [self.createCustomerButton setNeedsDisplay:YES];
        } else {
            self.instructionLabel.backgroundColor = paleRed;
            [self.createCustomerButton setHidden:YES];
        }
        self.instructionLabel.textColor = white;
        self.isValid = NO;
    }
}

#pragma mark - NSTableViewDataSource
-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [self.customers count];
}
-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if (self.customers.count == 0) {
        return nil;
    }
    Customer * customer = self.customers[row];
    if ([tableColumn.identifier isEqualToString:@"firstName"]) {
        return customer.firstName;
    }
    if ([tableColumn.identifier isEqualToString:@"lastName"]) {
        return customer.lastName;
    }
    if ([tableColumn.identifier isEqualToString:@"phone"]) {
        return customer.phone;
    }
    if ([tableColumn.identifier isEqualToString:@"email"]) {
        return customer.email;
    }
    if ([tableColumn.identifier isEqualToString:@"postcode"]) {
        return customer.postcode;
    }
    if ([tableColumn.identifier isEqualToString:@"addressLine1"]) {
        return customer.addressLine1;
    }
    if ([tableColumn.identifier isEqualToString:@"addressLine2"]) {
        return customer.addressLine2;
    }
    if ([tableColumn.identifier isEqualToString:@"monthOfBirth"]) {
        NSUInteger monthNumber = customer.monthOfBirth.integerValue;
        if (monthNumber == 0) {
            return @"";
        } else {
            return [NSDate monthNameFromNumber:monthNumber];
        }
    }
    if ([tableColumn.identifier isEqualToString:@"dayOfBirth"]) {
        NSUInteger dayNumber = customer.dayOfBirth.integerValue;
        if (dayNumber == 0) {
            return @"";
        } else {
            return customer.dayOfBirth;
        }
    }
    return nil;
}
-(void)tableView:(NSTableView *)tableView sortDescriptorsDidChange:(NSArray *)oldDescriptors
{
    NSArray * newDescriptors = [tableView sortDescriptors];
    [self.customers sortUsingDescriptors:newDescriptors];
    [self.customersTable reloadData];
}
#pragma mark - NSTableViewDelegate
-(void)tableViewSelectionDidChange:(NSNotification *)notification
{
    [self setLabelText];
}
-(BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    return NO;
}

#pragma mark - NSTextFieldDelegate
-(void)controlTextDidChange:(NSNotification *)notification
{
    if (notification.object == self.firstName) {
        self.firstName.stringValue = [self.firstName.stringValue capitalizedString];
    }
    if (notification.object == self.lastName) {
        self.lastName.stringValue = [self.lastName.stringValue capitalizedString];
    }
    if (notification.object == self.addressLine1) {
        self.addressLine1.stringValue = [self.addressLine1.stringValue capitalizedString];
    }
    if (notification.object == self.addressLine2) {
        self.addressLine2.stringValue = [self.addressLine2.stringValue capitalizedString];
    }
    if (notification.object == self.postcode) {
        self.postcode.stringValue = [self.postcode.stringValue uppercaseString];
    }
    [self filtersUpdated];
}
#pragma mark - AMCDayAndMonthPopupViewControllerDelegate
-(void)dayAndMonthControllerDidUpdate:(AMCDayAndMonthPopupViewController *)dayAndMonthController
{
    [self filtersUpdated];
}

#pragma mark - NSControlTextEditingDelegate
-(BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
    BOOL controlIsValid = NO;
    if (control == self.firstName) {
        controlIsValid = [self validateName:fieldEditor.string allowZeroLength:NO];
    }
    if (control == self.lastName) {
        controlIsValid = [self validateName:fieldEditor.string allowZeroLength:YES];
    }
    if (control == self.email) {
        controlIsValid = [self validateEmailAddress:fieldEditor.string];
    }
    if (control == self.phone) {
        controlIsValid = [self validatePhoneNumber:fieldEditor.string];
    }
    if (control == self.postcode) {
        controlIsValid = [self validatePostcode:fieldEditor.string];
    }
    return controlIsValid;
}
-(void)controlTextDidEndEditing:(NSNotification *)obj
{
    [self filtersUpdated];
}

#pragma mark - validation
-(NSString*)extractPhoneNumber:(NSString*)string
{
    NSError *error = nil;
    NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypePhoneNumber error:&error];
    __block NSString * phoneNumber = @"";
    [detector enumerateMatchesInString:string
                               options:kNilOptions
                                 range:NSMakeRange(0, [string length])
                            usingBlock:
     ^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
         phoneNumber = result.phoneNumber;
     }];
    return phoneNumber;
}
-(BOOL)validateName:(NSString*)name allowZeroLength:(BOOL)allowZeroLength
{
    if (!name) return NO;
    if ([self trimmedStringFromString:name].length == 0) {
        return allowZeroLength;
    }
    return YES;
}
-(NSString*)trimmedStringFromString:(NSString*)string
{
    if (!string) return string;
    NSCharacterSet * whiteSpace = [NSCharacterSet whitespaceCharacterSet];
    return [string stringByTrimmingCharactersInSet:whiteSpace];
}
-(BOOL)validatePhoneNumber:(NSString*)possibleNumber
{
    if (possibleNumber.length == 0) {
        return YES;
    }
    NSString * phoneNumber = [self extractPhoneNumber:possibleNumber];
    if (phoneNumber && phoneNumber.length > 0) {
        return YES;
    }
    return NO;
}
-(BOOL)validateEmailAddress:(NSString*)possibleAddress
{
    if (!possibleAddress || possibleAddress.length == 0) {
        return YES;
    }
    
    NSString* pattern = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]+";
    
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", pattern];
    if ([predicate evaluateWithObject:possibleAddress] == YES) {
        return YES;
    } else {
        return NO;
    }
}
-(BOOL)validatePostcode:(NSString*)postcode
{
    return YES;
//    NSString * test = [postcode uppercaseString];
//    if (test.length == 0) return YES;
//    NSString *postcodeRegex = @"(GIR 0AA)|((([A-Z-[QVX]][0-9][0-9]?)|(([A-Z-[QVX]][A-Z-[IJZ]][0-9][0-9]?)|(([A-Z-[QVX]][0-9][A-HJKSTUW])|([A-Z-[QVX]][A-Z-[IJZ]][0-9][ABEHMNPRVWXY])))) [0-9][A-Z-[CIKMOV]]{2})";
//    NSPredicate *postcodeValidate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", postcodeRegex];
//    return [postcodeValidate evaluateWithObject:test];
}
-(BOOL)detailsSufficientToCreateCustomer
{
    if (![self validateName:self.firstName.stringValue allowZeroLength:NO]) return NO;
    if (![self validateName:self.lastName.stringValue allowZeroLength:YES]) return NO;
    if ([self.firstName.stringValue isEqualToString:@""] && [self.lastName.stringValue isEqualToString:@""]) return NO;
    if (![self validatePhoneNumber:self.phone.stringValue]) return NO;
    if (![self validateEmailAddress:self.email.stringValue]) return NO;
    if (![self validatePostcode:self.postcode.stringValue]) return NO;
    if (self.phone.stringValue.length == 0 && self.email.stringValue.length == 0) return NO;
    return YES;
}
#pragma mark - Filtering and sorting helpers
-(NSPredicate*)predicate
{
    NSPredicate * predicate;
    
    NSString * firstName = self.firstName.stringValue;
    NSString * lastName = self.lastName.stringValue;
    NSString * email = self.email.stringValue;
    NSString * phone = self.phone.stringValue;
    NSString * postcode = self.postcode.stringValue;
    NSString * addressLine1 = self.addressLine1.stringValue;
    NSString * addressLine2 = self.addressLine2.stringValue;
    NSNumber * monthOfBirth = @(self.dayAndMonthContoller.monthNumber);
    NSNumber * dayOfBirth = @(self.dayAndMonthContoller.dayNumber);
    NSMutableArray * predicates = [NSMutableArray array];
    
    if (firstName.length > 0) {
        [predicates addObject:[NSPredicate predicateWithFormat:@"firstName BEGINSWITH[cd] %@ || firstName = %@",firstName,@""]];
    }
    if (lastName.length > 0) {
        [predicates addObject:[NSPredicate predicateWithFormat:@"lastName BEGINSWITH[cd] %@ || lastName = %@",lastName,@""]];
    }
    if (phone.length > 0) {
        [predicates addObject:[NSPredicate predicateWithFormat:@"phone BEGINSWITH[cd] %@ || phone = %@",phone,@""]];
    }
    if (email.length > 0) {
        [predicates addObject:[NSPredicate predicateWithFormat:@"email BEGINSWITH[cd] %@ || email = %@",email,@""]];
    }
    if (postcode.length > 0) {
        [predicates addObject:[NSPredicate predicateWithFormat:@"postcode BEGINSWITH[cd] %@ || postcode = %@",postcode,@""]];
    }
    if (addressLine1.length > 0) {
        [predicates addObject:[NSPredicate predicateWithFormat:@"addressLine1 BEGINSWITH[cd] %@ || addressLine1 = %@",addressLine1,@""]];
    }
    if (addressLine2.length > 0) {
        [predicates addObject:[NSPredicate predicateWithFormat:@"addressLine2 BEGINSWITH[cd] %@ || addressLine2 = %@",addressLine2,@""]];
    }
    if (monthOfBirth.integerValue > 0) {
        [predicates addObject:[NSPredicate predicateWithFormat:@"monthOfBirth = %@",monthOfBirth]];
    }
    if (dayOfBirth.integerValue > 0) {
        [predicates addObject:[NSPredicate predicateWithFormat:@"dayOfBirth = %@",dayOfBirth]];
    }
    if (predicates.count > 0) {
        predicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
    }
    return predicate;
}
-(void)filtersUpdated {
    _customers = nil;
    [self.customersTable reloadData];
    [self.customersTable deselectAll:self];
    [self setLabelText];
}

@end
