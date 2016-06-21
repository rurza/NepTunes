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
#import "PreferencesController.h"
#import "MusicScrobbler.h"

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
static NSString *const kScrobblePodcastsAndiTunesUButton = @"scrobblePodcastsAndiTunesUButton";
static NSString *const kAutomaticallyShareOnFacebook = @"automaticallyShareOnFacebook";
static NSString *const kAutomaticallyShareOnTwitter = @"automaticallyShareOnTwitter";
static NSString *const kSpotifyOnly = @"spotifyOnly";
static NSString *const kiTunesOnly = @"iTunesOnly";
static NSString *const kScrobbleFromSpotify = @"scrobbleFromSpotify";
static NSString *const kCutExtraTags = @"cutExtraTags";

static NSString *const kDebugMode = @"debugMode";

@interface SettingsController ()
@property (nonatomic, weak) NSUserDefaults *userDefaults;
@property (nonatomic, weak) NSWindow *alertWindow;
@property (weak) IBOutlet NSTextField *percentForScrobbleTimeLabel;
@property (nonatomic, weak) IBOutlet PreferencesController *preferencesController;

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
@synthesize integrationWithMusicPlayer = _integrationWithMusicPlayer;
@synthesize loveTrackOniTunes = _loveTrackOniTunes;
@synthesize showSimilarArtistsOnMusicPlayer = _showSimilarArtistsOnMusicPlayer;
@synthesize showRecentTrackOnMusicPlayer = _showRecentTrackOnMusicPlayer;
@synthesize debugMode = _debugMode;
@synthesize scrobblePodcastsAndiTunesU = _scrobblePodcastsAndiTunesU;
@synthesize automaticallyShareOnTwitter = _automaticallyShareOnTwitter;
@synthesize automaticallyShareOnFacebook = _automaticallyShareOnFacebook;
@synthesize iTunesOnly = _iTunesOnly;
@synthesize spotifyOnly = _spotifyOnly;
@synthesize scrobbleFromSpotify = _scrobbleFromSpotify;
@synthesize cutExtraTags = _cutExtraTags;

#pragma mark - Initialization
+ (instancetype)sharedSettings
{
    __strong static id _sharedInstance = nil;
    static dispatch_once_t onlyOnce;
    dispatch_once(&onlyOnce, ^{
        _sharedInstance = [[self _alloc] _init];
        [_sharedInstance registerDefaultsSettings];
    });
    return _sharedInstance;
}

+ (id) allocWithZone:(NSZone*)z { return [self sharedSettings];              }
+ (id) alloc                    { return [self sharedSettings];              }
- (id) init                     {return self;}
+ (id)_alloc                    { return [super allocWithZone:NULL]; }
- (id)_init                     {return [super init];}


-(void)awakeFromNib
{
    [self saveSettings];
    [self updateSettingsPane];
    [self terminateHelperApp];
    [self updateNumberOfRecentItemsPopUp];
}

-(void)registerDefaultsSettings
{
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{kHideStatusBarIcon:                   @NO,
                                                              kPercentForScrobbleTime:              @50,
                                                              kNumberOfTracksInRecent:              @5,
                                                              kLaunchAtLogin:                       @NO,
                                                              kOpenPreferencesAtLogin:              @YES,
                                                              kHideNotifications:                   @NO,
                                                              kIntegrationWithiTunes:               @NO,
                                                              kLoveTrackOniTunes:                   @NO,
                                                              kShowSimilarArtistsOnAppleMusic:      @NO,
                                                              kShowRecentTrackIniTunes:             @NO,
                                                              kScrobblePodcastsAndiTunesUButton:    @NO,
                                                              kAutomaticallyShareOnTwitter:         @NO,
                                                              kAutomaticallyShareOnFacebook:        @NO,
                                                              kScrobbleFromSpotify:                 @NO,
                                                              kCutExtraTags:@NO}];
 
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
    if (self.integrationWithMusicPlayer) {
        self.integrationWithMusicPlayerCheckbox.state = NSOnState;
    } else {
        self.integrationWithMusicPlayerCheckbox.state = NSOffState;
        self.loveTrackOniTunesCheckbox.enabled = NO;
        self.showSimilarArtistsOnMusicPlayerCheckbox.enabled = NO;
        self.showRecentTrackOnMusicPlayerCheckbox.enabled = NO;
    }
    
    if (self.loveTrackOniTunes) {
        self.loveTrackOniTunesCheckbox.state = NSOnState;
    } else {
        self.loveTrackOniTunesCheckbox.state = NSOffState;
    }
    if (self.showSimilarArtistsOnMusicPlayer) {
        self.showSimilarArtistsOnMusicPlayerCheckbox.state = NSOnState;
    } else {
        self.showSimilarArtistsOnMusicPlayerCheckbox.state = NSOffState;
    }
    if (self.showRecentTrackOnMusicPlayer) {
        self.showRecentTrackOnMusicPlayerCheckbox.state = NSOnState;
    } else {
        self.showRecentTrackOnMusicPlayerCheckbox.state = NSOffState;
    }
    if (self.scrobblePodcastsAndiTunesU) {
        self.scrobblePodcastsAndiTunesUCheckbox.state = NSOnState;
    } else {
        self.scrobblePodcastsAndiTunesUCheckbox.state = NSOffState;
    }
    //Social
    if (self.automaticallyShareOnFacebook) {
        self.automaticallyShareOnFacebookCheckbox.state = NSOnState;
    } else {
        self.automaticallyShareOnFacebookCheckbox.state = NSOffState;
    }
    NSSharingService *service;
    service = [NSSharingService sharingServiceNamed:NSSharingServiceNamePostOnTwitter];
    if (self.automaticallyShareOnTwitter && [service canPerformWithItems:nil]) {
        self.automaticallyShareOnTwitterCheckbox.state = NSOnState;
    } else if ([service canPerformWithItems:nil]) {
        self.automaticallyShareOnTwitterCheckbox.state = NSOffState;
    } else {
        self.automaticallyShareOnTwitterCheckbox.state = NSOffState;
        self.automaticallyShareOnTwitterCheckbox.enabled = NO;
    }
    service = [NSSharingService sharingServiceNamed:NSSharingServiceNamePostOnFacebook];
    if (self.automaticallyShareOnFacebook && [service canPerformWithItems:nil]) {
        self.automaticallyShareOnFacebookCheckbox.state = NSOnState;
    } else if ([service canPerformWithItems:nil]) {
        self.automaticallyShareOnFacebookCheckbox.state = NSOffState;
    } else {
        self.automaticallyShareOnFacebookCheckbox.state = NSOffState;
        self.automaticallyShareOnFacebookCheckbox.enabled = NO;
    }
    //Spotify
    if (self.scrobbleFromSpotify) {
        self.scrobbleFromSpotifyCheckbox.state = NSOnState;
    } else {
        self.scrobbleFromSpotifyCheckbox.state = NSOffState;
    }
    //Tags
    self.cutExtraTagsCheckbox.state = self.cutExtraTags ? NSOnState : NSOffState;
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
    if (sender.state) {
        [[MenuController sharedController] removeStatusBarItem];
        __block NSAlert *alert = [[NSAlert alloc] init];
        alert.window.releasedWhenClosed = YES;
        alert.messageText = NSLocalizedString(@"Icon Hidden", nil);
        alert.informativeText = NSLocalizedString(@"To open NepTunes preferences again, click its icon in Launchpad or double-click it in Finder.", nil);
        alert.alertStyle = NSInformationalAlertStyle;
        [alert addButtonWithTitle:@"OK"];
        NSButton *restoreNowButton = [alert addButtonWithTitle:NSLocalizedString(@"Restore now", nil)];
        restoreNowButton.target = self;
        restoreNowButton.action = @selector(restoreStatusBarIcon);
        self.alertWindow = alert.window;
        [alert beginSheetModalForWindow:self.preferencesController.window completionHandler:^(NSModalResponse returnCode) {
        }];
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[MenuController sharedController] installStatusBar];
        });
    }
}

-(IBAction)toggleOpenPreferencesWhenThereIsNoUser:(NSButton *)sender
{
    self.openPreferencesWhenThereIsNoUser = sender.state;
}

-(IBAction)toggleHideNotifications:(NSButton *)sender
{
    self.hideNotifications = sender.state;
}

-(IBAction)toggleScrobbleFromSpotify:(NSButton *)sender
{
    self.scrobbleFromSpotify = sender.state;
    if (sender.state) {
        __block NSAlert *alert = [[NSAlert alloc] init];
        alert.window.releasedWhenClosed = YES;
        alert.messageText = NSLocalizedString(@"Just in case...", nil);
        alert.informativeText = NSLocalizedString(@"Spotify has built-in scrobbler. Remember to turn it off, otherwise you will have double scrobbles.", nil);
        alert.alertStyle = NSInformationalAlertStyle;
        [alert addButtonWithTitle:@"Nice to know"];
        self.alertWindow = alert.window;
        [alert beginSheetModalForWindow:self.preferencesController.window completionHandler:^(NSModalResponse returnCode) {
        }];
    }
}

-(void)restoreStatusBarIcon
{
    self.hideStatusBarIcon = NO;
    [[MenuController sharedController] installStatusBar];
    [self.preferencesController.window endSheet:self.alertWindow];
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
    [[MenuController sharedController] prepareRecentItemsMenu];
    [self toggleShowRecentTracksCheckbox];
}

-(void)toggleShowRecentTracksCheckbox
{
    if (self.numberOfTracksInRecent.integerValue == 0 || !self.integrationWithMusicPlayer) {
        self.showRecentTrackOnMusicPlayerCheckbox.enabled = NO;
    } else {
        self.showRecentTrackOnMusicPlayerCheckbox.enabled = YES;
    }
}

-(IBAction)toggleIntegrationWithiTunes:(NSButton *)sender
{
    self.integrationWithMusicPlayer = sender.state;
    [[MenuController sharedController] updateMenu];
    if (self.numberOfTracksInRecent.integerValue == 0) {
        self.showRecentTrackOnMusicPlayerCheckbox.enabled = NO;
    }
}
-(IBAction)toggleLoveTrackOniTunes:(NSButton *)sender
{
    self.loveTrackOniTunes = sender.state;
    [[MenuController sharedController] updateMenu];
}

-(IBAction)toggleShowSimilarArtistsOnAppleMusic:(NSButton *)sender
{
    self.showSimilarArtistsOnMusicPlayer = sender.state;
    [[MenuController sharedController] updateMenu];
    
}
-(IBAction)toggleShowRecentTrackIniTunes:(NSButton *)sender
{
    self.showRecentTrackOnMusicPlayer = sender.state;
    [[MenuController sharedController] prepareRecentItemsMenu];
    [[MenuController sharedController] updateMenu];
}

-(IBAction)toggleScrobblePodcastsAndiTunesU:(NSButton *)sender
{
    self.scrobblePodcastsAndiTunesU = sender.state;
}

//Social
-(IBAction)toggleAutomaticallyShareOnFacebook:(NSButton *)sender
{
    self.automaticallyShareOnFacebook = sender.state;
}
-(IBAction)toggleAutomaticallyShareOnTwitter:(NSButton *)sender;
{
    self.automaticallyShareOnTwitter = sender.state;
}

//Tags
-(void)toggleCutExtraTags:(NSButton *)sender
{
    self.cutExtraTags = sender.state;
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
            [[MenuController sharedController] showRecentMenu];
            self.showRecentTrackOnMusicPlayerCheckbox.enabled = YES;
        } else {
            [[MenuController sharedController] hideRecentMenu];
            self.showRecentTrackOnMusicPlayerCheckbox.enabled = NO;
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
    self.percentForScrobbleTimeLabel.stringValue = [NSString stringWithFormat:NSLocalizedString(@"Scrobble track at %@%% of its length.", nil), _percentForScrobbleTime];
    return _percentForScrobbleTime;
}

-(void)setPercentForScrobbleTime:(NSNumber *)percentForScrobbleTime
{
    _percentForScrobbleTime = percentForScrobbleTime;
    if (percentForScrobbleTime) {
        [self.userDefaults setObject:percentForScrobbleTime forKey:kPercentForScrobbleTime];
        self.percentForScrobbleTimeLabel.stringValue = [NSString stringWithFormat:NSLocalizedString(@"Scrobble track at %@%% of its length.", nil), percentForScrobbleTime];
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
#pragma mark   integrationWithMusicPlayer
-(void)setIntegrationWithMusicPlayer:(BOOL)integrationWithMusicPlayer
{
    _integrationWithMusicPlayer = integrationWithMusicPlayer;
    [self.userDefaults setObject:@(integrationWithMusicPlayer) forKey:kIntegrationWithiTunes];
    if (!integrationWithMusicPlayer) {
        //wylaczyc pozostale
        self.loveTrackOniTunesCheckbox.enabled = NO;
        self.showRecentTrackOnMusicPlayerCheckbox.enabled = NO;
        self.showSimilarArtistsOnMusicPlayerCheckbox.enabled = NO;
    } else {
        //wlaczyc pozostale
        self.loveTrackOniTunesCheckbox.enabled = YES;
        self.showRecentTrackOnMusicPlayerCheckbox.enabled = YES;
        self.showSimilarArtistsOnMusicPlayerCheckbox.enabled = YES;
    }
    [self saveSettings];
}

-(BOOL)integrationWithMusicPlayer
{
    if (!_integrationWithMusicPlayer) {
        _integrationWithMusicPlayer = [[self.userDefaults objectForKey:kIntegrationWithiTunes] boolValue];
    }
    return _integrationWithMusicPlayer;
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
-(void)setShowSimilarArtistsOnMusicPlayer:(BOOL)showSimilarArtistsOnMusicPlayer
{
    _showSimilarArtistsOnMusicPlayer = showSimilarArtistsOnMusicPlayer;
    [self.userDefaults setObject:@(showSimilarArtistsOnMusicPlayer) forKey:kShowSimilarArtistsOnAppleMusic];
    [self saveSettings];
}

-(BOOL)showSimilarArtistsOnMusicPlayer
{
    if (!_showSimilarArtistsOnMusicPlayer) {
        _showSimilarArtistsOnMusicPlayer = [[self.userDefaults objectForKey:kShowSimilarArtistsOnAppleMusic] boolValue];
    }
    return _showSimilarArtistsOnMusicPlayer;
}

#pragma mark   showRecentTrackIniTunes
//@property (nonatomic) BOOL showRecentTrackIniTunes;
-(void)setShowRecentTrackOnMusicPlayer:(BOOL)showRecentTrackOnMusicPlayer
{
    _showRecentTrackOnMusicPlayer = showRecentTrackOnMusicPlayer;
    [self.userDefaults setObject:@(showRecentTrackOnMusicPlayer) forKey:kShowRecentTrackIniTunes];
    [self saveSettings];
}

-(BOOL)showRecentTrackOnMusicPlayer
{
    if (!_showRecentTrackOnMusicPlayer) {
        _showRecentTrackOnMusicPlayer = [[self.userDefaults objectForKey:kShowRecentTrackIniTunes] boolValue];
    }
    return _showRecentTrackOnMusicPlayer;
}

#pragma mark   debugMode
-(void)setDebugMode:(BOOL)debugMode
{
    _debugMode = debugMode;
    [self.userDefaults setObject:@(debugMode) forKey:kDebugMode];
    [self saveSettings];
}

-(BOOL)debugMode
{
    if (!_debugMode) {
        _debugMode = [[self.userDefaults objectForKey:kDebugMode] boolValue];
    }
    return _debugMode;
}

#pragma mark   scrobblePodcastsAndiTunesU
-(void)setScrobblePodcastsAndiTunesU:(BOOL)scrobblePodcastsAndiTunesU
{
    _scrobblePodcastsAndiTunesU = scrobblePodcastsAndiTunesU;
    [self.userDefaults setObject:@(scrobblePodcastsAndiTunesU) forKey:kScrobblePodcastsAndiTunesUButton];
    [self saveSettings];
}

-(BOOL)scrobblePodcastsAndiTunesU
{
    if (!_scrobblePodcastsAndiTunesU) {
        _scrobblePodcastsAndiTunesU = [[self.userDefaults objectForKey:kScrobblePodcastsAndiTunesUButton] boolValue];
    }
    return _scrobblePodcastsAndiTunesU;
}

#pragma mark   automaticallyShareOnTwitter
-(void)setAutomaticallyShareOnTwitter:(BOOL)automaticallyShareOnTwitter
{
    _automaticallyShareOnTwitter = automaticallyShareOnTwitter;
    [self.userDefaults setObject:@(automaticallyShareOnTwitter) forKey:kAutomaticallyShareOnTwitter];
    [self saveSettings];
}

-(BOOL)automaticallyShareOnTwitter
{
    if (!_automaticallyShareOnTwitter) {
        _automaticallyShareOnTwitter = [[self.userDefaults objectForKey:kAutomaticallyShareOnTwitter] boolValue];
    }
    return _automaticallyShareOnTwitter;
}

#pragma mark   automaticallyShareOnFacebook
-(void)setAutomaticallyShareOnFacebook:(BOOL)automaticallyShareOnFacebook
{
    _automaticallyShareOnFacebook = automaticallyShareOnFacebook;
    [self.userDefaults setObject:@(automaticallyShareOnFacebook) forKey:kAutomaticallyShareOnFacebook];
    [self saveSettings];
}

-(BOOL)automaticallyShareOnFacebook
{
    if (!_automaticallyShareOnFacebook) {
        _automaticallyShareOnFacebook = [[self.userDefaults objectForKey:kAutomaticallyShareOnFacebook] boolValue];
    }
    return _automaticallyShareOnFacebook;
}

#pragma mark   scrobbleFromSpotifyCheckbox
-(BOOL)scrobbleFromSpotify
{
    if (!_scrobbleFromSpotify) {
        _scrobbleFromSpotify = [[self.userDefaults objectForKey:kScrobbleFromSpotify] boolValue];
    }
    return _scrobbleFromSpotify;
}

-(void)setScrobbleFromSpotify:(BOOL)scrobbleFromSpotify
{
    _scrobbleFromSpotify = scrobbleFromSpotify;
    [self.userDefaults setObject:@(scrobbleFromSpotify) forKey:kScrobbleFromSpotify];
    [self saveSettings];
}

#pragma mark  cutExtraTags
-(BOOL)cutExtraTags
{
    if (!_cutExtraTags) {
        _cutExtraTags = [[self.userDefaults objectForKey:kCutExtraTags] boolValue];
    }
    return _cutExtraTags;
}

-(void)setCutExtraTags:(BOOL)cutExtraTags
{
    _cutExtraTags = cutExtraTags;
    if (cutExtraTags) {
        [[MusicScrobbler sharedScrobbler] downloadNewTagsLibraryAndStoreIt];
    }
    [self.userDefaults setObject:@(cutExtraTags) forKey:kCutExtraTags];
    [self saveSettings];
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