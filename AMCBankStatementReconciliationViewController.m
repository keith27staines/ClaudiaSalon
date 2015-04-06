//
//  AMCBankStatementReconciliationViewController.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 06/04/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "AMCBankStatementReconciliationViewController.h"
#import "AMCStatementParser.h"

@interface AMCBankStatementReconciliationViewController () <NSTableViewDataSource, NSTableViewDelegate>
@property (weak) IBOutlet NSTextField *viewTitle;
@property (weak) IBOutlet NSTableView *csvTable;

@property (weak) IBOutlet NSTextField *dateRowField;
@property (weak) IBOutlet NSTextField *dateColumnField;

@property (weak) IBOutlet NSTextField *broughtForwardRowField;

@property (weak) IBOutlet NSTextField *broughtForwardColumnField;
@property (weak) IBOutlet NSTextField *carriedForwardRowField;
@property (weak) IBOutlet NSTextField *carriedForwardColumnField;
@property (weak) IBOutlet NSTextField *headerLinesCountField;
@property AMCStatementParser * parser;

@end

@implementation AMCBankStatementReconciliationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSInteger i = 0;
    for (NSTableColumn * column in self.csvTable.tableColumns) {
        column.title = [NSString stringWithFormat:@"Col%lu",i];
        column.identifier = [NSString stringWithFormat:@"Col%lu",i];
        i++;
    }
}

-(void)prepareForDisplayWithSalon:(AMCSalonDocument *)salonDocument {
    [super prepareForDisplayWithSalon:salonDocument];
}
- (IBAction)loadCSV:(id)sender {
    NSOpenPanel * openPanel = [NSOpenPanel openPanel];
    openPanel.allowedFileTypes = @[@"csv"];
    NSInteger result = [openPanel runModal];
    if (result == NSFileHandlingPanelOKButton) {
        NSURL * fileURL = openPanel.URL;
        NSError * error;
        NSString * csv = [NSString stringWithContentsOfURL:fileURL usedEncoding:nil error:&error];
        if (!csv && error) {
            error = nil;
            csv = [NSString stringWithContentsOfURL:fileURL encoding:NSASCIIStringEncoding error:&error];
            if (!csv && error) {
                [NSApp presentError:error];
            }
        }
        if (csv) {
            self.parser = [[AMCStatementParser alloc] initWithCSVString:csv];
        }
        [self.csvTable reloadData];
    }
}
- (IBAction)reconcileWithAccount:(id)sender {
}
- (IBAction)dateRowChanged:(id)sender {
}
- (IBAction)dateColumnChanged:(id)sender {
}

- (IBAction)headerLinesCountChanged:(id)sender {
}


- (IBAction)broughtForwardRowChanged:(id)sender {
}

- (IBAction)broughtForwardColumnChanged:(id)sender {
}

- (IBAction)carriedForwardRowChanged:(id)sender {
}

- (IBAction)carriedForwardColumnChanged:(id)sender {
}



-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    if (!self.parser) return 0;
    return self.parser.rowCount;
}

-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    return [self.parser objectForColumnWithIdentifier:tableColumn.identifier row:row];
}











@end
