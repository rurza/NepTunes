//
//  AppDelegate.m
//  NepTunesHelperApp
//
//  Created by rurza on 19/01/16.
//  Copyright © 2016 micropixels. All rights reserved.
//

#import "AppDelegate.h"

static NSString *const kHelperAppBundle = @"pl.micropixels.NepTunesHelperApp";
static NSString *const kMainAppBundle = @"pl.micropixels.NepTunes";


@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    // Check if main app is already running; if yes, do nothing and terminate helper app
    BOOL alreadyRunning = NO;
    NSArray *running = [[NSWorkspace sharedWorkspace] runningApplications];
    for (NSRunningApplication *app in running) {
        if ([[app bundleIdentifier] isEqualToString:kMainAppBundle]) {
            alreadyRunning = YES;
        }
    }
    
    if (alreadyRunning)
    {
        // Main app is already running,
        // Meaning that the helper was launched via SMLoginItemSetEnabled, kill the helper
        [self killApp];
    } else
    {
        // Register Observer
        // So that main app can later notify helper to terminate
        [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                            selector:@selector(killApp)
                                                                name:kHelperAppBundle // Can be any string, but shouldn't be nil
                                                              object:kMainAppBundle];
        
        // Launch main app
        NSString *path = [[NSBundle mainBundle] bundlePath];
        NSArray *p = [path pathComponents];
        NSMutableArray *pathComponents = [NSMutableArray arrayWithArray:p];
        [pathComponents removeLastObject];
        [pathComponents removeLastObject];
        [pathComponents removeLastObject];
        [pathComponents addObject:@"MacOS"];
        [pathComponents addObject:@"NepTunes"];
        NSString *mainAppPath = [NSString pathWithComponents:pathComponents];
        [[NSWorkspace sharedWorkspace] launchApplication:mainAppPath];
    }
}

// Terminates helper app
// Called by main app after main app has checked if helper app is still running
// This allows main app to determine whether it was launched at login or not
// For complete documentation see http://blog.timschroeder.net/2014/01/25/detecting-launch-at-login-revisited/
-(void)killApp
{
    [NSApp terminate:nil];
}

@end
