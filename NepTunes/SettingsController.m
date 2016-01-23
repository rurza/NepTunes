//
//  SettingsController.m
//  NepTunes
//
//  Created by rurza on 22/01/16.
//  Copyright © 2016 micropixels. All rights reserved.
//

#import "SettingsController.h"
#import <ServiceManagement/ServiceManagement.h>
#import "MenuController.h"


static NSString *const kUserAvatar = @"userAvatar";
static NSString *const kLaunchAtLogin = @"launchAtLogin";
static NSString *const kNumberOfTracksInRecent = @"numberOfTracksInRecent";
static NSString *const kUsernameKey = @"pl.micropixels.neptunes.usernameKey";
static NSString *const kSessionKey = @"pl.micropixels.neptunes.sessionKey";
static NSString *const kHelperAppBundle = @"pl.micropixels.NepTunesHelperApp";

@interface SettingsController ()
@property (nonatomic, weak) NSUserDefaults *userDefaults;
@end

@implementation SettingsController
@synthesize userAvatar = _userAvatar;
@synthesize username = _username;
@synthesize launchAtLogin = _launchAtLogin;
@synthesize session = _session;
@synthesize numberOfTracksInRecent = _numberOfTracksInRecent;

#pragma mark - Initialization
+ (instancetype)sharedSettings		{  __strong static id _sharedInstance = nil;     static dispatch_once_t onlyOnce;
    dispatch_once(&onlyOnce, ^{   _sharedInstance = [[self _alloc] _init]; }); return _sharedInstance;
}
+ (id) allocWithZone:(NSZone*)z { return [self sharedSettings];              }
+ (id) alloc                    { return [self sharedSettings];              }
- (id) init                     { return  self;}
+ (id)_alloc                    { return [super allocWithZone:NULL]; }
- (id)_init                     { return [super init];               }


-(void)awakeFromNib
{
    [self updateLaunchAtLoginCheckbox];
    [self terminateHelperApp];
    [self updateNumberOfRecentItemsPopUp];
}

-(void)updateLaunchAtLoginCheckbox
{
    if (self.launchAtLogin) {
        self.launchAtLoginCheckbox.state =  NSOnState;
    } else {
        self.launchAtLoginCheckbox.state =  NSOffState;
    }
}

-(void)updateNumberOfRecentItemsPopUp
{
    [self.numberOfRecentItems selectItemWithTag:self.numberOfTracksInRecent.integerValue];
}


-(IBAction)toggleLaunchAtLogin:(NSButton *)sender
{
    if (sender.state) { // ON
        if (!SMLoginItemSetEnabled ((__bridge CFStringRef)kHelperAppBundle, YES)) {
            sender.state = NSOffState;
        } else {
            self.launchAtLogin = YES;
        }
    }
    if (!sender.state) { // OFF
        // Turn off launch at login
        if (!SMLoginItemSetEnabled ((__bridge CFStringRef)kHelperAppBundle, NO)) {
            sender.state = NSOnState;
        } else {
            self.launchAtLogin = NO;
        }
    }
}

-(void)terminateHelperApp
{
    BOOL startedAtLogin = NO;
    
    NSArray *apps = [[NSWorkspace sharedWorkspace] runningApplications];
    for (NSRunningApplication *app in apps) {
        if ([app.bundleIdentifier isEqualToString:kHelperAppBundle]) startedAtLogin = YES;
    }
    
    if (startedAtLogin) {
        [[NSDistributedNotificationCenter defaultCenter] postNotificationName:kHelperAppBundle
                                                                       object:[[NSBundle mainBundle] bundleIdentifier]];
        if (!self.launchAtLogin) {
            self.launchAtLogin = YES;
        }
    }
}

- (IBAction)changeNumberOfRecentItems:(NSPopUpButton *)popUp
{
    self.numberOfTracksInRecent = @(popUp.selectedTag);
    [self.menuController prepareRecentItemsMenu];
}



#pragma mark - Setters & Getters
#pragma mark   Avatar
-(void)setUserAvatar:(NSImage *)userAvatar
{
    if (userAvatar) {
        _userAvatar = userAvatar;
        NSData *imageData = [userAvatar TIFFRepresentation];
        [self.userDefaults setObject:imageData forKey:kUserAvatar];
    } else {
        [self.userDefaults removeObjectForKey:kUserAvatar];
    }
    [self saveSettings];
}

-(NSImage *)userAvatar
{
    if (!_userAvatar) {
        NSData *imageData = [self.userDefaults objectForKey:kUserAvatar];
        _userAvatar = [[NSImage alloc] initWithData:imageData];
        if (!_userAvatar) {
            _userAvatar = [NSImage imageNamed:@"no avatar"];
            [self.userDefaults setObject:[_userAvatar TIFFRepresentation] forKey:kUserAvatar];
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
        [self.userDefaults setObject:username forKey:kUsernameKey];
    } else {
        [self.userDefaults removeObjectForKey:kUsernameKey];
    }
    [self saveSettings];
}

-(NSString *)username
{
    if (!_username) {
        _username = [self.userDefaults stringForKey:kUsernameKey];
    }
    return _username;
}

#pragma mark   Launch at login
-(void)setLaunchAtLogin:(BOOL)launchAtLogin
{
    _launchAtLogin = launchAtLogin;
    [self.userDefaults setObject:@(launchAtLogin) forKey:kLaunchAtLogin];
    [self saveSettings];
}

-(BOOL)launchAtLogin
{
    if (!_launchAtLogin) {
        _launchAtLogin = [[self.userDefaults objectForKey:kLaunchAtLogin] boolValue];
    }
    return _launchAtLogin;
}

#pragma mark   Session
-(void)setSession:(NSString *)session
{
    if (session) {
        _session = [session copy];
        [self.userDefaults setObject:session forKey:kSessionKey];
    } else {
        [self.userDefaults removeObjectForKey:kSessionKey];
    }
    [self saveSettings];

}

-(NSString *)session
{
    if (!_session) {
        _session = [[self.userDefaults stringForKey:kSessionKey] copy];
    }
    return _session;
}

#pragma mark   Number of tracks in recent
-(void)setNumberOfTracksInRecent:(NSNumber *)numberOfTracksInRecent
{
    if (numberOfTracksInRecent) {
        _numberOfTracksInRecent = numberOfTracksInRecent;
        [self.userDefaults setObject:numberOfTracksInRecent forKey:kNumberOfTracksInRecent];
    } else {
        [self.userDefaults removeObjectForKey:kNumberOfTracksInRecent];
    }
    [self saveSettings];
}

-(NSNumber *)numberOfTracksInRecent
{
    if (!_numberOfTracksInRecent) {
        _numberOfTracksInRecent = [self.userDefaults objectForKey:kNumberOfTracksInRecent];
    }
    return _numberOfTracksInRecent;
}

#pragma mark - Save
-(void)saveSettings
{
    [self.userDefaults synchronize];
}

-(NSUserDefaults *)userDefaults
{
    if (!_userDefaults) {
        _userDefaults = [NSUserDefaults standardUserDefaults];
    }
    return _userDefaults;
}


@end
