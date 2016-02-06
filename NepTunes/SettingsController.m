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
#import "AppDelegate.h"


static NSString *const kUserAvatar = @"userAvatar";
static NSString *const kLaunchAtLogin = @"launchAtLogin";
static NSString *const kNumberOfTracksInRecent = @"numberOfTracksInRecent";
static NSString *const kHideStatusBarIcon = @"hideStatusBarIcon";
static NSString *const kUsernameKey = @"pl.micropixels.neptunes.usernameKey";
static NSString *const kSessionKey = @"pl.micropixels.neptunes.sessionKey";
static NSString *const kHelperAppBundle = @"pl.micropixels.NepTunesHelperApp";
static NSString *const kOpenPreferencesAtLogin = @"openPreferencesAtLogin";
static NSString *const kHideNotifications = @"hideNotifications";
static NSString *const kPercentForScrobbleTime = @"percentForScrobbleTime";
static NSString *const kuserWasLoggedOut = @"userWasLoggedOut";
static NSString *const kIntegrationWithiTunes = @"integrationWithiTunes";
static NSString *const kLoveTrackOniTunes = @"loveTrackOniTunes";
static NSString *const kShowSimilarArtistsOnAppleMusic = @"showSimilarArtistsOnAppleMusic";
static NSString *const kShowRecentTrackIniTunes = @"showRecentTrackIniTunes";

@interface SettingsController ()
@property (nonatomic, weak) NSUserDefaults *userDefaults;
@property (nonatomic, weak) NSWindow *alertWindow;
@property (weak) IBOutlet NSTextField *percentForScrobbleTimeLabel;
@end

@implementation SettingsController

@synthesize userAvatar = _userAvatar;
@synthesize username = _username;
@synthesize launchAtLogin = _launchAtLogin;
@synthesize session = _session;
@synthesize numberOfTracksInRecent = _numberOfTracksInRecent;
@synthesize hideStatusBarIcon = _hideStatusBarIcon;
@synthesize openPreferencesWhenThereIsNoUser = _openPreferencesWhenThereIsNoUser;
@synthesize hideNotifications = _hideNotifications;
@synthesize percentForScrobbleTime = _percentForScrobbleTime;
@synthesize userWasLoggedOut = _userWasLoggedOut;
@synthesize integrationWithiTunes = _integrationWithiTunes;
@synthesize loveTrackOniTunes = _loveTrackOniTunes;
@synthesize showSimilarArtistsOnAppleMusic = _showSimilarArtistsOnAppleMusic;
@synthesize showRecentTrackIniTunes = _showRecentTrackIniTunes;





#pragma mark - Initialization
+ (instancetype)sharedSettings
{
    __strong static id _sharedInstance = nil;
    static dispatch_once_t onlyOnce;
    dispatch_once(&onlyOnce, ^{
        _sharedInstance = [[self _alloc] _init];
        
    });
    return _sharedInstance;
}

+ (id) allocWithZone:(NSZone*)z { return [self sharedSettings];              }
+ (id) alloc                    { return [self sharedSettings];              }
- (id) init                     { [self registerDefaultsSettings]; return self;}
+ (id)_alloc                    { return [super allocWithZone:NULL]; }
- (id)_init                     { return [super init];               }


-(void)awakeFromNib
{
    [self saveSettings];
    [self updateSettingsPane];
    [self terminateHelperApp];
    [self updateNumberOfRecentItemsPopUp];
}

-(void)registerDefaultsSettings
{
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{kHideStatusBarIcon: @NO}];
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{kPercentForScrobbleTime: @50}];
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{kNumberOfTracksInRecent: @5}];
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{kLaunchAtLogin: @NO}];
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{kOpenPreferencesAtLogin: @YES}];
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{kHideNotifications: @NO}];
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{kIntegrationWithiTunes: @NO}];
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{kLoveTrackOniTunes: @NO}];
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{kShowSimilarArtistsOnAppleMusic: @NO}];
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{kShowRecentTrackIniTunes: @NO}];

    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)updateSettingsPane
{
    if (self.launchAtLogin) {
        self.launchAtLoginCheckbox.state =  NSOnState;
    } else {
        self.launchAtLoginCheckbox.state =  NSOffState;
    }
    if (self.hideStatusBarIcon) {
        self.hideStatusBarCheckbox.state = NSOnState;
    } else {
        self.hideStatusBarCheckbox.state = NSOffState;
    }
    if (self.openPreferencesWhenThereIsNoUser) {
        self.openPreferencesWhenThereIsNoUserCheckbox.state = NSOnState;
    } else {
        self.openPreferencesWhenThereIsNoUserCheckbox.state = NSOffState;
    }
    if (self.hideNotifications) {
        self.hideNotificationsCheckbox.state = NSOnState;
    } else {
        self.hideNotificationsCheckbox.state = NSOffState;
    }
    if (self.percentForScrobbleTime) {
        self.percentForScrobbleTimeSlider.integerValue = self.percentForScrobbleTime.integerValue;
    } else {
        self.percentForScrobbleTimeSlider.integerValue = 50;
    }
    //Menu
    if (self.integrationWithiTunes) {
        self.integrationWithiTunesCheckbox.state = NSOnState;
    } else {
        self.integrationWithiTunesCheckbox.state = NSOffState;
        self.loveTrackOniTunesCheckbox.enabled = NO;
        self.showSimilarArtistsOnAppleMusicCheckbox.enabled = NO;
        self.showRecentTrackIniTunesCheckbox.enabled = NO;
    }
    
    if (self.loveTrackOniTunes) {
        self.loveTrackOniTunesCheckbox.state = NSOnState;
    } else {
        self.loveTrackOniTunesCheckbox.state = NSOffState;
    }
    if (self.showSimilarArtistsOnAppleMusic) {
        self.showSimilarArtistsOnAppleMusicCheckbox.state = NSOnState;
    } else {
        self.showSimilarArtistsOnAppleMusicCheckbox.state = NSOffState;
    }
    if (self.showRecentTrackIniTunes) {
        self.showRecentTrackIniTunesCheckbox.state = NSOnState;
    } else {
        self.showRecentTrackIniTunesCheckbox.state = NSOffState;
    }

}

-(void)updateNumberOfRecentItemsPopUp
{
    [self.numberOfRecentItems selectItemWithTag:self.numberOfTracksInRecent.integerValue];
    [self toggleShowRecentTracksCheckbox];
}

-(IBAction)toggleLaunchAtLogin:(NSButton *)sender
{
    if (sender.state) { // ON
        if (!SMLoginItemSetEnabled((__bridge CFStringRef)kHelperAppBundle, YES)) {
            sender.state = NSOffState;
        } else {
            self.launchAtLogin = YES;
        }
    }
    if (!sender.state) { // OFF
        // Turn off launch at login
        if (!SMLoginItemSetEnabled((__bridge CFStringRef)kHelperAppBundle, NO)) {
            sender.state = NSOnState;
        } else {
            self.launchAtLogin = NO;
        }
    }
}

-(IBAction)toggleHideStatusBarIcon:(NSButton *)sender
{
    self.hideStatusBarIcon = sender.state;
    __weak typeof(self) weakSelf = self;
        if (sender.state) {
            [self.menuController removeStatusBarItem];
            __block NSAlert *alert = [[NSAlert alloc] init];
            alert.window.releasedWhenClosed = YES;
            alert.messageText = NSLocalizedString(@"Icon Hidden", nil);
            alert.informativeText = NSLocalizedString(@"To open NepTunes settings again, click its icon in Launchpad or double-click it in Finder.", nil);
            alert.alertStyle = NSInformationalAlertStyle;
            [alert addButtonWithTitle:@"OK"];
            NSButton *restoreNowButton = [alert addButtonWithTitle:NSLocalizedString(@"Restore now", nil)];
            restoreNowButton.target = self;
            restoreNowButton.action = @selector(restoreStatusBarIcon);
            self.alertWindow = alert.window;
            [alert beginSheetModalForWindow:((AppDelegate *)[NSApplication sharedApplication].delegate).window completionHandler:^(NSModalResponse returnCode) {
                [alert.window close];
            }];
        } else {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakSelf.menuController installStatusBar];
            });
        }
}

-(IBAction)toggleOpenPreferencesWhenThereIsNoUser:(NSButton *)sender
{
    self.openPreferencesWhenThereIsNoUser = sender.state;
}

-(void)toggleHideNotifications:(NSButton *)sender
{
    self.hideNotifications = sender.state;
}

-(void)restoreStatusBarIcon
{
    self.hideStatusBarIcon = NO;
    [self.menuController installStatusBar];
    [((AppDelegate *)[NSApplication sharedApplication].delegate).window endSheet:self.alertWindow];
    [self.hideStatusBarCheckbox setState:NSOffState];
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
    [self toggleShowRecentTracksCheckbox];
}

-(void)toggleShowRecentTracksCheckbox
{
    if (self.numberOfTracksInRecent.integerValue == 0 || !self.integrationWithiTunes) {
        self.showRecentTrackIniTunesCheckbox.enabled = NO;
    } else {
        self.showRecentTrackIniTunesCheckbox.enabled = YES;
    }
}

-(IBAction)toggleIntegrationWithiTunes:(NSButton *)sender
{
    self.integrationWithiTunes = sender.state;
    [self.menuController updateMenu];
    if (self.numberOfTracksInRecent.integerValue == 0) {
        self.showRecentTrackIniTunesCheckbox.enabled = NO;
    }
}
-(IBAction)toggleLoveTrackOniTunes:(NSButton *)sender
{
    self.loveTrackOniTunes = sender.state;
    [self.menuController updateMenu];
    if (sender.state) {
        __block NSAlert *alert = [[NSAlert alloc] init];
        alert.window.releasedWhenClosed = YES;
        alert.messageText = NSLocalizedString(@"Some limitations", nil);
        alert.informativeText = NSLocalizedString(@"Unfortunately, this functionality works only with music in your iTunes Library and with Apple Music radio. Be aware of this.", nil);
        alert.alertStyle = NSInformationalAlertStyle;
        [alert addButtonWithTitle:@"I'm aware"];
        self.alertWindow = alert.window;
        [alert beginSheetModalForWindow:((AppDelegate *)[NSApplication sharedApplication].delegate).window completionHandler:^(NSModalResponse returnCode) {
        }];
    }
}

-(IBAction)toggleShowSimilarArtistsOnAppleMusic:(NSButton *)sender
{
    self.showSimilarArtistsOnAppleMusic = sender.state;
    [self.menuController updateMenu];
    
}
-(IBAction)toggleShowRecentTrackIniTunes:(NSButton *)sender
{
    self.showRecentTrackIniTunes = sender.state;
    [self.menuController updateMenu];
}


#pragma mark - Setters & Getters
#pragma mark   Avatar
-(void)setUserAvatar:(NSImage *)userAvatar
{
    _userAvatar = userAvatar;
    if (userAvatar) {
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
    _username = username;
    if (username) {
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
    _session = [session copy];
    if (session) {
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
    _numberOfTracksInRecent = numberOfTracksInRecent;
    if (numberOfTracksInRecent) {
        [self.userDefaults setObject:numberOfTracksInRecent forKey:kNumberOfTracksInRecent];
        if (numberOfTracksInRecent.integerValue != 0) {
            [self.menuController showRecentMenu];
            self.showRecentTrackIniTunesCheckbox.enabled = YES;
        } else {
            [self.menuController hideRecentMenu];
            self.showRecentTrackIniTunesCheckbox.enabled = NO;
        }
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

#pragma mark   Hide status bar icon
-(BOOL)hideStatusBarIcon
{
    if (!_hideStatusBarIcon) {
        _hideStatusBarIcon = [[self.userDefaults objectForKey:kHideStatusBarIcon] boolValue];
    }
    return _hideStatusBarIcon;
}

-(void)setHideStatusBarIcon:(BOOL)hideStatusBarIcon
{
    _hideStatusBarIcon = hideStatusBarIcon;
    [self.userDefaults setObject:@(hideStatusBarIcon) forKey:kHideStatusBarIcon];
    [self saveSettings];
}

#pragma mark   Open preferences
-(BOOL)openPreferencesWhenThereIsNoUser
{
    if (!_openPreferencesWhenThereIsNoUser) {
        _openPreferencesWhenThereIsNoUser = [[self.userDefaults objectForKey:kOpenPreferencesAtLogin] boolValue];
    }
    return _openPreferencesWhenThereIsNoUser;
}

-(void)setOpenPreferencesWhenThereIsNoUser:(BOOL)openPreferencesWhenThereIsNoUser
{
    _openPreferencesWhenThereIsNoUser = openPreferencesWhenThereIsNoUser;
    [self.userDefaults setObject:@(openPreferencesWhenThereIsNoUser) forKey:kOpenPreferencesAtLogin];
    [self saveSettings];
    if (self.openPreferencesWhenThereIsNoUserCheckbox.state != openPreferencesWhenThereIsNoUser) {
        self.openPreferencesWhenThereIsNoUserCheckbox.state = openPreferencesWhenThereIsNoUser;
    }
}

#pragma mark   Hide notifications
-(BOOL)hideNotifications
{
    if (!_hideNotifications) {
        _hideNotifications = [[self.userDefaults objectForKey:kHideNotifications] boolValue];
    }
    return _hideNotifications;
}

-(void)setHideNotifications:(BOOL)hideNotifications
{
    _hideNotifications = hideNotifications;
    [self.userDefaults setObject:@(hideNotifications) forKey:kHideNotifications];
    [self saveSettings];
}

#pragma mark   Percent for scrobble time
-(NSNumber *)percentForScrobbleTime
{
    if (!_percentForScrobbleTime) {
        _percentForScrobbleTime = [self.userDefaults objectForKey:kPercentForScrobbleTime];
    }
    self.percentForScrobbleTimeLabel.stringValue = [NSString stringWithFormat:NSLocalizedString(@"Scrobble track at %@%% of it length.", nil), _percentForScrobbleTime];
    return _percentForScrobbleTime;
}

-(void)setPercentForScrobbleTime:(NSNumber *)percentForScrobbleTime
{
    _percentForScrobbleTime = percentForScrobbleTime;
    if (percentForScrobbleTime) {
        [self.userDefaults setObject:percentForScrobbleTime forKey:kPercentForScrobbleTime];
        self.percentForScrobbleTimeLabel.stringValue = [NSString stringWithFormat:NSLocalizedString(@"Scrobble track at %@%% of it length.", nil), percentForScrobbleTime];
    } else {
        [self.userDefaults removeObjectForKey:kPercentForScrobbleTime];
    }
    [self saveSettings];
}

#pragma mark   User was logged out
-(BOOL)userWasLoggedOut
{
    if (!_userWasLoggedOut) {
        _userWasLoggedOut = [[self.userDefaults objectForKey:kuserWasLoggedOut] boolValue];
    }
    return _userWasLoggedOut;
}

-(void)setUserWasLoggedOut:(BOOL)userWasLoggedOut
{
    _userWasLoggedOut = userWasLoggedOut;
    [self.userDefaults setObject:@(userWasLoggedOut) forKey:kuserWasLoggedOut];
    [self saveSettings];
}

//@property (nonatomic) BOOL integrationWithiTunes;
#pragma mark   integrationWithiTunes
-(void)setIntegrationWithiTunes:(BOOL)integrationWithiTunes
{
    _integrationWithiTunes = integrationWithiTunes;
    [self.userDefaults setObject:@(integrationWithiTunes) forKey:kIntegrationWithiTunes];
    if (!integrationWithiTunes) {
        //wylaczyc pozostale
        self.loveTrackOniTunesCheckbox.enabled = NO;
        self.showRecentTrackIniTunesCheckbox.enabled = NO;
        self.showSimilarArtistsOnAppleMusicCheckbox.enabled = NO;
    } else {
        //wlaczyc pozostale
        self.loveTrackOniTunesCheckbox.enabled = YES;
        self.showRecentTrackIniTunesCheckbox.enabled = YES;
        self.showSimilarArtistsOnAppleMusicCheckbox.enabled = YES;
    }
    [self saveSettings];
}

-(BOOL)integrationWithiTunes
{
    if (!_integrationWithiTunes) {
        _integrationWithiTunes = [[self.userDefaults objectForKey:kIntegrationWithiTunes] boolValue];
    }
    return _integrationWithiTunes;
}

//@property (nonatomic) BOOL loveTrackOniTunes;
#pragma mark   loveTrackOniTunes
-(void)setLoveTrackOniTunes:(BOOL)loveTrackOniTunes
{
    _loveTrackOniTunes = loveTrackOniTunes;
    [self.userDefaults setObject:@(loveTrackOniTunes) forKey:kLoveTrackOniTunes];
    [self saveSettings];
}

-(BOOL)loveTrackOniTunes
{
    if (!_loveTrackOniTunes) {
        _loveTrackOniTunes = [[self.userDefaults objectForKey:kLoveTrackOniTunes] boolValue];
    }
    return _loveTrackOniTunes;
}

//@property (nonatomic) BOOL showSimilarArtistsOnAppleMusic;
#pragma mark   showSimilarArtistsOnAppleMusic
-(void)setShowSimilarArtistsOnAppleMusic:(BOOL)showSimilarArtistsOnAppleMusic
{
    _showSimilarArtistsOnAppleMusic = showSimilarArtistsOnAppleMusic;
    [self.userDefaults setObject:@(showSimilarArtistsOnAppleMusic) forKey:kShowSimilarArtistsOnAppleMusic];
    [self saveSettings];
}

-(BOOL)showSimilarArtistsOnAppleMusic
{
    if (!_showSimilarArtistsOnAppleMusic) {
        _showSimilarArtistsOnAppleMusic = [[self.userDefaults objectForKey:kShowSimilarArtistsOnAppleMusic] boolValue];
    }
    return _showSimilarArtistsOnAppleMusic;
}

#pragma mark   showRecentTrackIniTunes
//@property (nonatomic) BOOL showRecentTrackIniTunes;
-(void)setShowRecentTrackIniTunes:(BOOL)showRecentTrackIniTunes
{
    _showRecentTrackIniTunes = showRecentTrackIniTunes;
    [self.userDefaults setObject:@(showRecentTrackIniTunes) forKey:kShowRecentTrackIniTunes];
    [self saveSettings];
}

-(BOOL)showRecentTrackIniTunes
{
    if (!_showRecentTrackIniTunes) {
        _showRecentTrackIniTunes = [[self.userDefaults objectForKey:kShowRecentTrackIniTunes] boolValue];
    }
    return _showRecentTrackIniTunes;
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