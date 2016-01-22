//
//  SettingsController.m
//  NepTunes
//
//  Created by rurza on 22/01/16.
//  Copyright © 2016 micropixels. All rights reserved.
//

#import "SettingsController.h"
@import AppKit;

static NSString *const kUserAvatar = @"userAvatar";
static NSString *const kLaunchAtLogin = @"launchAtLogin";
static NSString *const kUsernameKey = @"pl.micropixels.neptunes.usernameKey";
static NSString *const kSessionKey = @"pl.micropixels.neptunes.sessionKey";


@implementation SettingsController
@synthesize userAvatar = _userAvatar;
@synthesize username = _username;
@synthesize launchAtLogin = _launchAtLogin;
@synthesize session = _session;

+(SettingsController *)sharedSettings
{
    static SettingsController *settings = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        settings = [[SettingsController alloc] init];
    });
    return settings;
}

#pragma mark - Setters & Getters
#pragma mark   Avatar
-(void)setUserAvatar:(NSImage *)userAvatar
{
    if (userAvatar) {
        _userAvatar = userAvatar;
        NSData *imageData = [userAvatar TIFFRepresentation];
        [[NSUserDefaults standardUserDefaults] setObject:imageData forKey:kUserAvatar];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kUserAvatar];
    }
    [self saveSettings];
}

-(NSImage *)userAvatar
{
    if (!_userAvatar) {
        NSData *imageData = [[NSUserDefaults standardUserDefaults] objectForKey:kUserAvatar];
        _userAvatar = [[NSImage alloc] initWithData:imageData];
        if (!_userAvatar) {
            _userAvatar = [NSImage imageNamed:@"no avatar"];
            [[NSUserDefaults standardUserDefaults] setObject:[_userAvatar TIFFRepresentation] forKey:kUserAvatar];
            [self saveSettings];
        }
    }
    return _userAvatar;
}

#pragma mark   Username
-(void)setUsername:(NSString *)username
{
    if (username) {
        _username = username;
        [[NSUserDefaults standardUserDefaults] setObject:username forKey:kUsernameKey];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kUsernameKey];
    }
    [self saveSettings];
}

-(NSString *)username
{
    if (!_username) {
        _username = [[NSUserDefaults standardUserDefaults] stringForKey:kUsernameKey];
    }
    return _username;
}

#pragma mark   Launch at login
-(void)setLaunchAtLogin:(BOOL)launchAtLogin
{
    _launchAtLogin = launchAtLogin;
    [[NSUserDefaults standardUserDefaults] setObject:@(launchAtLogin) forKey:kLaunchAtLogin];
    [self saveSettings];
}

-(BOOL)launchAtLogin
{
    if (!_launchAtLogin) {
        _launchAtLogin = [[[NSUserDefaults standardUserDefaults] objectForKey:kLaunchAtLogin] boolValue];
    }
    return _launchAtLogin;
}

#pragma mark   Session
-(void)setSession:(NSString *)session
{
    if (session) {
        _session = session;
        [[NSUserDefaults standardUserDefaults] setObject:session forKey:kSessionKey];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kSessionKey];
    }
    [self saveSettings];

}

-(NSString *)session
{
    if (!_session) {
        _session = [[NSUserDefaults standardUserDefaults] stringForKey:kSessionKey];
    }
    return _session;
}


-(void)saveSettings
{
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
