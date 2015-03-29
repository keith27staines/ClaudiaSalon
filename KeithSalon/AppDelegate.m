//
//  AppDelegate.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 23/02/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "AppDelegate.h"
#import "AMCConstants.h"
#import "AMCWelcomeScreen.h"
#import "AMCSalonDocument.h"
#import "NSDate+AMCDate.h"
#import "AMCAutoCloseWindowController.h"
#import "AMCPreferencesWindowController.h"
#import "AMCCategoryManagerViewController.h"

#define kSalonsDictionary @"kSalonsDictionary"
#define kDefaultSalonPath @"kDefaultSalonPath"
#define kShowWelcomeWindow @"kShowWelcomeWindow"

@interface AppDelegate () <NSAlertDelegate>
{
    NSDate * _autoShutdownDate;
}
@property (weak) IBOutlet AMCWelcomeScreen *welcomeScreenController;


@property (strong) NSMutableDictionary * salonsDictionary;
@property NSString * pathOfDefaultSalon;
@property BOOL showWelcomeWindow;
@property NSDate * appStartDate;
@property NSDate * autoShutdownDate;
@property NSTimer * autoCloseTimer;
@property AMCAutoCloseWindowController * autoCloseWindowController;
@property (weak) IBOutlet AMCPreferencesWindowController *preferencesWindowController;

@end

@implementation AppDelegate


+(void)initialize {
    [super initialize];
    AMCCategoryManagerViewController * categoryManager = [[AMCCategoryManagerViewController alloc] init];
    NSDictionary * defaults = @{kDefaultSalonPath:@"",
                                kSalonsDictionary: @{},
                                kShowWelcomeWindow: @(YES),
                                kAMCSystemCategories: categoryManager.dataForUserDefaultsRegistration
                                };
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}
-(void)applicationWillFinishLaunching:(NSNotification *)notification {
    [self registerForNotifications];
    self.appStartDate = [NSDate date];
    self.autoShutdownDate = [self defaultAutoShutdownTimeForDate:self.appStartDate];
    if ([self.appStartDate isGreaterThan:[self defaultAutoShutdownTimeForDate:self.appStartDate]]) {
        self.autoShutdownDate = [self.appStartDate endOfDay];
    }
}
-(void)timerDidFire:(id)sender {
    if (sender == self.autoCloseTimer) {
        NSDate * now = [NSDate date];
        if ([now isGreaterThanOrEqualTo:[self autoShutdownDate]]) {
            [self.autoCloseTimer invalidate];
            self.autoCloseTimer = nil;
            self.autoCloseWindowController = [[AMCAutoCloseWindowController alloc] init];
            NSWindow * sheet = self.autoCloseWindowController.window;
            self.autoCloseWindowController.appDelegate = self;
            [sheet center];
            [self.autoCloseWindowController showWindow:self];        }
    }
}
-(NSDate *)autoShutdownDate {
    return _autoShutdownDate;
}
-(void)setAutoShutdownDate:(NSDate *)autoShutdownDate {
    if (self.autoCloseTimer) {
        [self.autoCloseTimer invalidate];
        self.autoCloseTimer = nil;
    }
    _autoShutdownDate = autoShutdownDate;
    self.autoCloseTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(timerDidFire:) userInfo:nil repeats:YES];
}
-(void)closeApplicationNow {
    [[NSDocumentController sharedDocumentController] closeAllDocumentsWithDelegate:nil didCloseAllSelector:@selector(documentController:didCloseAll:contextInfo:) contextInfo:nil];
    NSDateFormatter * df = [[NSDateFormatter alloc] init];
    df.dateStyle = NSDateFormatterLongStyle;
    df.timeStyle = NSDateFormatterLongStyle;
    NSLog(@"Automatically closing app at: %@",[NSDate date]);
}
-(void)attemptApplicationClosureAfter:(NSDate *)date {
    self.autoShutdownDate = date;
}
-(NSDate*)defaultAutoShutdownTimeForDate:(NSDate*)date {
    return [[date beginningOfDay] dateByAddingTimeInterval:(20 + 0.0/60.0) * 3600];
}
- (void)documentController:(NSDocumentController *)docController  didCloseAll: (BOOL)didCloseAll contextInfo:(void *)contextInfo {

}
-(void)registerForNotifications {
    [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowDidBecomeKeyNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        if (!self.pathOfDefaultSalon || self.pathOfDefaultSalon.length == 0) {
            NSWindow * window = note.object;
            NSDocumentController * documentController = [NSDocumentController sharedDocumentController];
            NSDocument * document = [documentController documentForWindow:window];
            if (document) {
                self.pathOfDefaultSalon = document.fileURL.path;
            }
        }
    }];
}
-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidBecomeKeyNotification object:nil];
}
-(NSURL*)urlOfDefaultSalon {
    if (!self.pathOfDefaultSalon || self.pathOfDefaultSalon.length == 0) {
        return nil;
    }
    return [NSURL fileURLWithPath:self.pathOfDefaultSalon];
}
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    self.pathOfDefaultSalon = [defaults objectForKey:kDefaultSalonPath];
    self.salonsDictionary = [defaults objectForKey:kSalonsDictionary];
    self.showWelcomeWindow = ((NSNumber*)[defaults objectForKey:kShowWelcomeWindow]).boolValue;
    [self openDefaultSalon:self];
}
-(IBAction)openDefaultSalon:(id)sender {
    if (self.pathOfDefaultSalon && self.pathOfDefaultSalon.length > 0) {
        // A file exists that matches the path of the default salon, but can we open it?
        NSDocumentController * documentController = [NSDocumentController sharedDocumentController];
        [documentController openDocumentWithContentsOfURL:[self urlOfDefaultSalon] display:YES completionHandler:^(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error) {
            if (error) {
                // No, couldn't open it, so just open the welcome screen and show the error because what else can we do?
                [self presentWelcomeScreen:self];
                [self.welcomeScreenController presentError:error modalForWindow:self.welcomeScreenController.window delegate:nil didPresentSelector:NULL contextInfo:nil];
            }
        }];
    } else {
        // no default salon has been set, so present the welcome screen
        [self presentWelcomeScreen:self];
    }
}
-(IBAction)makeCurrentSalonDefault:(id)sender {
    AMCSalonDocument * currentSalon = [[NSDocumentController sharedDocumentController] currentDocument];
    NSAlert * alert = [[NSAlert alloc] init];
    if (!currentSalon) {
        alert.informativeText = @"You must open a Salon before you can set it as the default.";
        [alert addButtonWithTitle:@"OK"];
        [alert runModal];
    } else {
        alert.messageText = @"Make this Salon the default";
        alert.informativeText = [NSString stringWithFormat:@"If it is made default, %@ will be opened automatically whenever the application is opened",currentSalon.fileURL.path];
        [alert addButtonWithTitle:@"Make default"];
        [alert addButtonWithTitle:@"Cancel"];
        alert.delegate = self;
        if ([alert runModal] == NSAlertFirstButtonReturn) {
            self.pathOfDefaultSalon = currentSalon.fileURL.path;
        }
    }
}
-(IBAction)presentWelcomeScreen:(id)sender {
    NSWindow * welcomeWindow = [self.welcomeScreenController window];
    [self.welcomeScreenController showWindow:welcomeWindow];
}
- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:self.salonsDictionary forKey:kSalonsDictionary];
    [defaults setObject:self.pathOfDefaultSalon forKey:kDefaultSalonPath];
    [defaults setObject:@(self.showWelcomeWindow) forKey:kShowWelcomeWindow];
}
-(BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender {
    return NO;
}
-(BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}
-(BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag {
    if (flag) {
        return YES;
    }
    NSDocumentController * documentController = [NSDocumentController sharedDocumentController];
    [documentController openDocumentWithContentsOfURL:[self urlOfDefaultSalon] display:YES completionHandler:^(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error) {
        if (!document) {
            [self presentWelcomeScreen:self];
        }
    }];
    return NO;
}
-(BOOL)application:(NSApplication *)sender openTempFile:(NSString *)filename {
    return NO;
}

-(BOOL)application:(id)sender openFileWithoutUI:(NSString *)filename {
    return NO;
}
-(IBAction)showPreferencesWindow:(id)sender {
    [self.preferencesWindowController showWindow:self];
}
@end
