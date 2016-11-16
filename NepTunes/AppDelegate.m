//
//  AppDelegate.m
//  NepTunes
//
//  Created by rurza on 19.11.2014.
//  Copyright (c) 2014 micropixels. All rights reserved.
//

#import "AppDelegate.h"
#import "SettingsController.h"
#import "PreferencesController.h"
#import "MenuController.h"
#import "PINCache.h"
#import "EGOCache.h"
#import "DebugMode.h"

@interface AppDelegate ()
@property (nonatomic) SettingsController *settingsController;
@property (nonatomic) IBOutlet MenuController *menuController;
@property (nonatomic) BOOL appWasLaunched;
@end



@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    [self.settingsController updateLaunchCounter];
    if (self.settingsController.launchCounter.integerValue % 50 == 0) {
        DebugMode(@"Clearing caches...");
        [[[PINCache alloc] initWithName:@"imageCache"] removeAllObjects];
        [[EGOCache globalCache] clearCache];
    }
}

-(BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag
{
    if (self.settingsController.hideStatusBarIcon) {
        [self.menuController openPreferences:nil];
    }
    return NO;
}

-(SettingsController *)settingsController
{
    if (!_settingsController) {
        _settingsController = [SettingsController sharedSettings];
    }
    return _settingsController;
}


@end
