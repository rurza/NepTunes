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

@interface AppDelegate ()
@property (nonatomic) SettingsController *settingsController;
@property (nonatomic) IBOutlet MenuController *menuController;
@end



@implementation AppDelegate

-(void)applicationDidFinishLaunching:(NSNotification *)notification
{
}

-(void)applicationDidBecomeActive:(NSNotification *)notification
{
    if (self.settingsController.hideStatusBarIcon) {
        [self.menuController openPreferences:nil];
    }
}

-(SettingsController *)settingsController
{
    if (!_settingsController) {
        _settingsController = [SettingsController sharedSettings];
    }
    return _settingsController;
}


@end
