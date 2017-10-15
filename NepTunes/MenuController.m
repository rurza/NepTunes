//
//  MenuController.m
//  NepTunes
//
//  Created by rurza on 08/08/15.
//  Copyright (c) 2015 micropixels. All rights reserved.
//

#import "MenuController.h"
#import "MusicScrobbler.h"
#import "AppDelegate.h"
#import "Track.h"
#import "RecentTracksController.h"
#import "SettingsController.h"
#import "FXReachability.h"
#import "UserNotificationsController.h"
#import "MusicController.h"
#import "iTunesSearch.h"
#import "MPISpotifySearch.h"
#import "LastFm.h"
#import "PreferencesController.h"
#import <PINCache.h>
#import "OfflineScrobbler.h"
#import "CoverWindowController.h"
#import "ControlViewController.h"
#import "AboutWindowController.h"
#import "HotkeyController.h"
#import "MusicPlayer.h"
#import "DebugMode.h"

@import QuartzCore;

static NSUInteger const kFPS = 30;
static NSUInteger const kNumberOfFrames = 10;

@interface MenuController () <ItunesSearchCache, NSWindowDelegate, SpotifySearchCache>

@property (nonatomic) IBOutlet NSMenu *recentTracksMenu;
@property (nonatomic) IBOutlet NSMenuItem *recentTracksMenuItem;
@property (nonatomic) IBOutlet MusicPlayer *musicPlayer;

@property (nonatomic) NSStatusItem *statusItem;
@property (nonatomic) RecentTracksController *recentTracksController;
@property (nonatomic) MusicScrobbler *musicScrobbler;
@property (nonatomic) SettingsController *settings;
@property (nonatomic) NSUInteger animationCurrentStep;
@property (nonatomic) PINCache *cachediTunesSearchResults;
@property (nonatomic) PINCache *cachedSpotifySearchResults;
@property (nonatomic) PreferencesController *preferencesController;
//reachability
@property (nonatomic) OfflineScrobbler *offlineScrobbler;
@property (nonatomic) AboutWindowController *aboutWindowController;
@property (nonatomic) MusicController *musicController;
@property (nonatomic) NSImage *currentMenubarImage;
@property (nonatomic) UserNotificationsController *userNotificationsController;
@property (nonatomic) NSCache *menubarIconsCache;
@property (nonatomic) NSTimer *updateMenuTimer;

@property (nonatomic) BOOL bothPlayerAreAvailable;
@property (nonatomic) BOOL reachability;

@end

@implementation MenuController

+ (instancetype)sharedController
{
    __strong static id _sharedInstance = nil;
    static dispatch_once_t onlyOnce;
    dispatch_once(&onlyOnce, ^{
        _sharedInstance = [[self _alloc] _init];
        
    });
    return _sharedInstance;
}

+ (id) allocWithZone:(NSZone*)z { return [self sharedController];              }
+ (id) alloc                    { return [self sharedController];              }
- (id) init                     { return self;}
+ (id)_alloc                    { return [super allocWithZone:NULL]; }
- (id)_init                     { return [super init];               }



- (void)awakeFromNib
{
    //System status bar icon
    self.userNotificationsController = [UserNotificationsController sharedNotificationsController];
    if (![SettingsController sharedSettings].hideStatusBarIcon) {
        [self installStatusBar];
    }
    
    [self prepareRecentItemsMenu];
    //first launch
    if (!self.musicScrobbler.scrobbler.session && self.settings.openPreferencesWhenThereIsNoUser) {
        [self openPreferences:self];
    }
    //Are we offline?
    [self setupReachability];
    
    if (self.settings.numberOfTracksInRecent.integerValue != 0) {
        [self showRecentMenu];
    } else {
        [self hideRecentMenu];
    }
    self.statusMenu.autoenablesItems = NO;
    [self.loveSongMenuTitle setEnabled:NO];
    
    //initialize hotkey to update menu 
    HotkeyController *hotkey = [[HotkeyController alloc] init];
    hotkey = nil;
}

#pragma mark - Reachability

- (void)setupReachability
{
    //1. this must be first
    self.reachability = YES;
    //2. this must be second
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityDidChange:) name:FXReachabilityStatusDidChangeNotification object:nil];
}

- (void)reachabilityDidChange:(NSNotification *)note
{
    BOOL reachable = [FXReachability isReachable];
    if (!reachable && self.musicPlayer.playerState == MusicPlayerStatePlaying && self.settings.session) {
        [[UserNotificationsController sharedNotificationsController] displayNotificationThatInternetConnectionIsDown];
        self.reachability = NO;
    } else if (reachable && !self.reachability && self.musicScrobbler.currentTrack && self.offlineScrobbler.tracks.count && self.settings.session) {
        [[UserNotificationsController sharedNotificationsController] displayNotificationThatInternetConnectionIsBack];
        self.reachability = YES;
    }
    [self updateMenu];
}

#pragma mark - Status Bar Icon

- (void)installStatusBar
{
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    self.currentMenubarImage = [NSImage imageNamed:@"statusIcon"];
    self.statusItem.button.image = self.currentMenubarImage;
    [self.currentMenubarImage setTemplate:YES];
    self.statusItem.menu = self.statusMenu;
}



- (void)removeStatusBarItem
{
    [[NSStatusBar systemStatusBar] removeStatusItem:self.statusItem];
    self.statusItem = nil;
}

#pragma mark Status Bar Icon Animation

- (void)blinkMenuIcon
{
    if (self.statusItem) {
        self.animationCurrentStep = 0;
        [self animationStepForward:YES];
    }
}

- (void)animationStepForward:(BOOL)forward
{
    //Safety
    if (self.animationCurrentStep > kNumberOfFrames) {
        [self setOriginalIcon];
        return;
    }
    
    dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, 1.0 / kFPS * NSEC_PER_SEC);
    __weak typeof(self) weakSelf = self;
    dispatch_after(delay, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        if (forward) {
            weakSelf.animationCurrentStep++;
        } else {
            weakSelf.animationCurrentStep--;
        }
        
        if (forward) {
            if (weakSelf.animationCurrentStep <= kNumberOfFrames) {
                [weakSelf animationStepForward:YES];
            } else {
                weakSelf.animationCurrentStep = 0;
            }
        } else {
            if (weakSelf.animationCurrentStep > 0) {
                [weakSelf animationStepForward:NO];
            } else {
                weakSelf.animationCurrentStep = 0;
            }
        }
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (weakSelf.animationCurrentStep != 0) {
                weakSelf.statusItem.button.image = [weakSelf imageForStep:weakSelf.animationCurrentStep];
            } else {
                if (forward) {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [weakSelf backwardAnimation];
                    });
                } else {
                    [weakSelf setOriginalIcon];
                }
            }
        });
    });
}

- (NSImage *)imageForStep:(NSUInteger)step
{
    NSImage *cachedImage = [self.menubarIconsCache objectForKey:@(step)];
    if (cachedImage) {
        self.currentMenubarImage = cachedImage;
    } else {
        if (step != 0) {
            NSImage *icon = [NSImage imageNamed:[NSString stringWithFormat:@"statusIcon%lu", (unsigned long)step]];
            if (icon) {
                [self.menubarIconsCache setObject:icon forKey:@(step)];
                self.currentMenubarImage = icon;
            }
        } else {
            NSImage *genericIcon = [self.menubarIconsCache objectForKey:@"generic"];
            if (genericIcon) {
                self.currentMenubarImage = genericIcon;
            } else {
                genericIcon = [NSImage imageNamed:@"statusIcon"];
                [self.menubarIconsCache setObject:genericIcon forKey:@"generic"];
            }
        }
        if (!self.currentMenubarImage) {
            self.currentMenubarImage = [NSImage imageNamed:@"statusIcon"];
            [self.menubarIconsCache setObject:self.currentMenubarImage forKey:@"generic"];
        }
    }
    [self.currentMenubarImage setTemplate:YES];
    return self.currentMenubarImage;
}


- (void)backwardAnimation
{
    self.animationCurrentStep = 10;
    [self animationStepForward:NO];    
}

- (void)setOriginalIcon
{
    self.currentMenubarImage = [NSImage imageNamed:@"statusIcon"];
    [self.currentMenubarImage setTemplate:YES];
    self.statusItem.button.image = self.currentMenubarImage;
}


#pragma mark - Last.fm related
- (IBAction)loveSong:(id)sender {
    [self.musicController loveTrackWithCompletionHandler:^{
        [self.musicController.coverWindowController.controlViewController animationLoveButton];
    }];
}

- (void)forceLogOut
{
    [self.musicScrobbler logOut];
    self.settings.session = nil;
    self.settings.userAvatar = nil;

    [self updateMenu];
}

#pragma mark - Menu Bar Items
- (IBAction)showUserProfile:(id)sender {
    if ([SettingsController sharedSettings].session) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.last.fm/user/%@", self.musicScrobbler.scrobbler.username]]];
    }
}


- (IBAction)showSimilarArtists:(id)sender
{
    NSString *str = self.musicScrobbler.currentTrack.artist;
    str = [str stringByReplacingOccurrencesOfString:@"/" withString:@"%2F"];
    NSString *url = [str stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    if (url.length > 0) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.last.fm/music/%@/+similar", url]]];
    }
}

#pragma mark - About window

- (IBAction)openAboutWindow:(NSMenuItem *)sender
{
    [NSApp activateIgnoringOtherApps:YES];
    if (!self.aboutWindowController) {
        self.aboutWindowController = [[AboutWindowController alloc] initWithWindowNibName:@"AboutWindowController"];
        self.aboutWindowController.window.delegate = self;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(windowWillClose:)
                                                     name:NSWindowWillCloseNotification
                                                   object:self.aboutWindowController.window];

    }
    [self.aboutWindowController showWindow:self];
    [self.aboutWindowController.window makeKeyAndOrderFront:nil];
}


- (IBAction)quit:(id)sender
{
    [[NSApplication sharedApplication] terminate:self];
}

#pragma mark - Preferences

- (IBAction)openPreferences:(id)sender
{
    [NSApp activateIgnoringOtherApps:YES];
    if (!self.preferencesController) {
        self.preferencesController = nil;
        self.preferencesController = [[PreferencesController alloc] initWithWindowNibName:@"PreferencesController"];
        self.preferencesController.window.delegate = self;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(windowWillClose:)
                                                     name:NSWindowWillCloseNotification
                                                   object:self.preferencesController.window];
    }
    [self.preferencesController showWindow:self];
    [self.preferencesController.window makeKeyAndOrderFront:nil];
}

- (BOOL)windowShouldClose:(id)sender
{
    return YES;
}

- (void)windowWillClose:(NSNotification *)notification
{
    NSWindow* window = notification.object;
    if (window == self.preferencesController.window) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowWillCloseNotification object:window];
        self.preferencesController = nil;
    } else if (window == self.aboutWindowController.window) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowWillCloseNotification object:window];
        self.aboutWindowController = nil;
    }
}

#pragma mark Update menu
- (void)updateMenu {
    if (self.updateMenuTimer) {
        [self.updateMenuTimer invalidate];
        self.updateMenuTimer = nil;
    }
    __weak typeof(self) weakSelf = self;
    self.updateMenuTimer = [NSTimer scheduledTimerWithTimeInterval:1.5 target:[NSBlockOperation blockOperationWithBlock:^{
        [weakSelf updateRecentMenu];
        [weakSelf updateLoveSongMenuItem];
        [weakSelf updateShowUserProfileMenuItem];
        [weakSelf updateSimilarArtistMenuItem];
        weakSelf.updateMenuTimer = nil;
    }] selector:@selector(main) userInfo:nil repeats:NO];
}

- (void)updateLoveSongMenuItem
{
    BOOL internetIsReachable = [FXReachability isReachable];
    //if user is logged in, there is Internet conenction and we have a track
    if (self.settings.session && self.musicScrobbler.currentTrack && internetIsReachable && self.musicPlayer.isPlayerRunning) {
        //if user choose to love track also in iTunes  and track listened is available to love in iTunes
        if ([self userHasTurnedOnIntegrationAndLovingMusicOniTunes]) {
            if (self.musicPlayer.canObtainCurrentTrackFromiTunes) {
                self.loveSongMenuTitle.title = [NSString stringWithFormat:NSLocalizedString(@"Love %@ on Last.fm & iTunes", nil), self.musicScrobbler.currentTrack.truncatedTrackName];
            } else {
                self.loveSongMenuTitle.title = [NSString stringWithFormat:NSLocalizedString(@"Love %@ on Last.fm", nil), self.musicScrobbler.currentTrack.truncatedTrackName];
            }
            //love on Last.fm and in iTunes
        } else {
            //love track only on Last.fm
            self.loveSongMenuTitle.title = [NSString stringWithFormat:NSLocalizedString(@"Love %@ on Last.fm", nil), self.musicScrobbler.currentTrack.truncatedTrackName];
        }
        //if user ISN'T logged in, we have a track
    } else if (!self.settings.session && self.musicScrobbler.currentTrack) {
        //if user choose to love track also in iTunes and track listened is available to love in iTunes
        if ([self userHasTurnedOnIntegrationAndLovingMusicOniTunes]) {
            if (self.musicScrobbler.currentTrack.artist.length && self.musicScrobbler.currentTrack.trackName.length) {
                self.loveSongMenuTitle.title = [NSString stringWithFormat:NSLocalizedString(@"Love %@ on iTunes", nil), self.musicScrobbler.currentTrack.truncatedTrackName];
            } else {
                self.loveSongMenuTitle.title = [NSString stringWithFormat:NSLocalizedString(@"Love %@ (Log in)", nil), self.musicScrobbler.currentTrack.truncatedTrackName];
            }
        } else {
            self.loveSongMenuTitle.title = [NSString stringWithFormat:NSLocalizedString(@"Love %@ (Log in)", nil), self.musicScrobbler.currentTrack.truncatedTrackName];
        }
        //if Internet connection ISN'T reachable BUT user choose to love track also in iTunes and we have a track
    } else if (!internetIsReachable && [self userHasTurnedOnIntegrationAndLovingMusicOniTunes] && self.musicScrobbler.currentTrack  && self.musicPlayer.isPlayerRunning) {
        self.loveSongMenuTitle.title = [NSString stringWithFormat:NSLocalizedString(@"Love %@ on iTunes", nil), self.musicScrobbler.currentTrack.truncatedTrackName];
    }   //if user is logged in but we don't have a track
    else if (!self.musicPlayer.isPlayerRunning || self.settings.session || !self.musicScrobbler.currentTrack ) {
        self.loveSongMenuTitle.title = [NSString stringWithFormat:NSLocalizedString(@"Love Track", nil)];
    }
    else {
        self.loveSongMenuTitle.title = [NSString stringWithFormat:NSLocalizedString(@"Love Track", nil)];
    }
    
    //when the button must be disabled
    if ((!internetIsReachable && ![self userHasTurnedOnIntegrationAndLovingMusicOniTunes]) || (!self.settings.session && ![self userHasTurnedOnIntegrationAndLovingMusicOniTunes]) || !self.musicScrobbler.currentTrack || (!self.settings.session && [self userHasTurnedOnIntegrationAndLovingMusicOniTunes] && !self.musicScrobbler.currentTrack.trackName.length) || [self.loveSongMenuTitle.title isEqualToString:[NSString stringWithFormat:NSLocalizedString(@"Love Track", nil)]]) {
        self.loveSongMenuTitle.enabled = NO;
    } else {
        self.loveSongMenuTitle.enabled = YES;
    }
}

- (BOOL)userHasTurnedOnIntegrationAndLovingMusicOniTunes
{
    if (self.settings.integrationWithMusicPlayer && self.settings.loveTrackOniTunes && self.musicPlayer.currentPlayer == MusicPlayeriTunes) {
        return YES;
    }
    return NO;
}

- (void)updateSimilarArtistMenuItem
{
    BOOL internetIsReachable = [FXReachability isReachable];
    if (self.musicPlayer.isPlayerRunning) {
        if (self.musicScrobbler.currentTrack) {
            self.similarArtistMenuTtitle.enabled = YES;
            self.similarArtistMenuTtitle.title = [NSString stringWithFormat:NSLocalizedString(@"Artists Similar  to %@", nil), self.musicScrobbler.currentTrack.truncatedArtist];
            if (!internetIsReachable) {
                self.similarArtistMenuTtitle.enabled = NO;
            }
            if (self.settings.showSimilarArtistsOnMusicPlayer && self.settings.integrationWithMusicPlayer && internetIsReachable) {
                __weak typeof(self) weakSelf = self;
                if (![self.similarArtistMenuTtitle hasSubmenu]) {
                    [self.musicScrobbler.scrobbler getSimilarArtistsTo:self.musicScrobbler.currentTrack.artist successHandler:^(NSArray *result) {
                        if (result.count) {
                            [weakSelf prepareSimilarArtistsMenuWithArtists:result];
                        } else {
                            [weakSelf.similarArtistMenuTtitle.submenu removeAllItems];
                            weakSelf.similarArtistMenuTtitle.submenu = nil;
                            weakSelf.similarArtistMenuTtitle.enabled = NO;
                        }
                    } failureHandler:^(NSError *error) {
                        weakSelf.similarArtistMenuTtitle.submenu = nil;
                        
                    }];
                } else {
                    [self.similarArtistMenuTtitle.submenu removeAllItems];
                    [self.musicScrobbler.scrobbler getSimilarArtistsTo:self.musicScrobbler.currentTrack.artist successHandler:^(NSArray *result) {
                        [weakSelf prepareSimilarArtistsMenuWithArtists:result];
                    } failureHandler:^(NSError *error) {
                        weakSelf.similarArtistMenuTtitle.submenu = nil;
                    }];
                    
                }
            } else {
                if ([self.similarArtistMenuTtitle hasSubmenu]) {
                    [self.similarArtistMenuTtitle.submenu removeAllItems];
                    self.similarArtistMenuTtitle.submenu = nil;
                }
            }
        } else {
            self.similarArtistMenuTtitle.enabled = NO;
            self.similarArtistMenuTtitle.title = [NSString stringWithFormat:NSLocalizedString(@"Similar Artists", nil)];
        }
    } else {
        self.similarArtistMenuTtitle.enabled = NO;
        self.similarArtistMenuTtitle.title = [NSString stringWithFormat:NSLocalizedString(@"Similar Artists", nil)];
    }
}


- (void)prepareSimilarArtistsMenuWithArtists:(NSArray *)artists
{
    if (artists.count) {
        if (!self.similarArtistMenuTtitle.hasSubmenu) {
            NSMenu *submenu = [[NSMenu alloc] init];
            submenu.autoenablesItems = NO;
            self.similarArtistMenuTtitle.submenu = submenu;
        } else {
            [self.similarArtistMenuTtitle.submenu removeAllItems];
        }
        if (![FXReachability sharedInstance].isReachable) {
            for (NSMenuItem *menuItem in self.similarArtistMenuTtitle.submenu.itemArray) {
                menuItem.enabled = NO;
            }
            return;
        }
        
        __weak typeof(self) weakSelf = self;
        [artists enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *artist = [obj objectForKey:@"name"];
            
            [self.similarArtistMenuTtitle.submenu addItemWithTitle:artist action:NULL keyEquivalent:@""];
            [self.musicPlayer getArtistURLForArtist:artist publicLink:NO forCurrentPlayerWithCompletionHandler:^(NSString *urlString) {
                if (urlString) {
                    [weakSelf enumerateMenuItemsToFindArtist:artist withAsciiCoding:NO];
                }
            } failureHandler:^(NSError *error) {
                [weakSelf.similarArtistMenuTtitle.submenu.itemArray enumerateObjectsUsingBlock:^(NSMenuItem * _Nonnull menuItem, NSUInteger idx, BOOL * _Nonnull stop) {
                    if ([menuItem.title.lowercaseString isEqualToString:artist.lowercaseString]) {
                        menuItem.enabled = NO;
                    }
                }];
            }];
            if (idx == 9) {
                *stop = YES;
            }
        }];
    } else {
        if (self.similarArtistMenuTtitle.hasSubmenu) {
            [self.similarArtistMenuTtitle.submenu removeAllItems];
            self.similarArtistMenuTtitle.submenu = nil;
        }
    }
}

- (void)enumerateMenuItemsToFindArtist:(NSString *)artist withAsciiCoding:(BOOL)coding
{
    if (coding) {
        artist = [self asciiString:artist];
    }
    __weak typeof(self) weakSelf = self;
    [self.similarArtistMenuTtitle.submenu.itemArray enumerateObjectsUsingBlock:^(NSMenuItem * _Nonnull menuItem, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *menuTitle;
        if (coding) {
            menuTitle = [weakSelf asciiString:menuItem.title];
        } else {
            menuTitle = menuItem.title;
        }
        if ([menuTitle isEqualToString:artist]) {
            menuItem.enabled = YES;
            menuItem.action = @selector(openLinkForArtistInMusicPlayerFromMenuItem:);
            menuItem.target = self;
        }
    }];
}

- (void)openLinkForArtistInMusicPlayerFromMenuItem:(NSMenuItem *)menuItem
{
    [self.musicPlayer openArtistPageForArtistName:menuItem.title withFailureHandler:nil];
}

- (NSString *)asciiString:(NSString *)string
{
    NSData *asciiEncoded = [string.lowercaseString dataUsingEncoding:NSASCIIStringEncoding
                                                allowLossyConversion:YES];
    
    NSString *stringInAscii = [[NSString alloc] initWithData:asciiEncoded
                                                    encoding:NSASCIIStringEncoding];
    return stringInAscii;
    
}

- (void)updateShowUserProfileMenuItem
{
    BOOL internetIsReachable = [FXReachability isReachable];
    
    if (self.settings.session && internetIsReachable) {
        self.profileMenuTitle.title = [NSString stringWithFormat:NSLocalizedString(@"%@ʼs Profile", nil), self.settings.username];
        self.profileMenuTitle.enabled = YES;
    } else if (self.settings.session && !internetIsReachable) {
        self.profileMenuTitle.title = [NSString stringWithFormat:NSLocalizedString(@"%@ʼs Profile", nil), self.settings.username];
        self.profileMenuTitle.enabled = NO;
    } else {
        self.profileMenuTitle.title = [NSString stringWithFormat:NSLocalizedString(@"Last.fm Profile (Log In)", nil)];
        self.profileMenuTitle.enabled = NO;
    }
}


#pragma mark - Recent Items

- (void)prepareRecentItemsMenu
{
    DebugMode(@"Preparing Recent Tracks menu")
    if (self.recentTracksController.tracks.count == 0) {
        self.recentTracksMenuItem.enabled = NO;
        return;
    } else {
        self.recentTracksMenuItem.enabled = YES;
        if (self.recentTracksMenu.numberOfItems) {
            [self.recentTracksMenu removeAllItems];
        }
    }
    
    __weak typeof(self) weakSelf = self;
    NSUInteger numberOfItemsFromSettings = [SettingsController sharedSettings].numberOfTracksInRecent.integerValue;
    [self.recentTracksController.tracks enumerateObjectsUsingBlock:^(Track *  _Nonnull track, NSUInteger idx, BOOL * _Nonnull stop) {
        if (idx == numberOfItemsFromSettings-1) {
            *stop =  YES;
        }
        NSMenuItem *menuItem = [weakSelf.recentTracksMenu addItemWithTitle:[NSString stringWithFormat:NSLocalizedString(@"%@ – %@", nil), track.truncatedArtist, track.truncatedTrackName] action:@selector(openWebsite:) keyEquivalent:@""];
        menuItem.target = self;
    }];
}


- (void)updateRecentMenu
{
    DebugMode(@"Updating Recent Tracks menu")
    Track *track = self.musicScrobbler.currentTrack;
    if ([self.recentTracksController addTrackToRecentMenu:track]) {
        self.recentTracksMenuItem.enabled = YES;
        
        if (self.recentTracksMenu.numberOfItems < [SettingsController sharedSettings].numberOfTracksInRecent.intValue) {
            NSMenuItem *menuItem = [self.recentTracksMenu insertItemWithTitle:[NSString stringWithFormat:NSLocalizedString(@"%@ – %@", nil), track.truncatedArtist, track.truncatedTrackName] action:@selector(openWebsite:) keyEquivalent:@"" atIndex:0];
            [self validateLinkFromMenuItem:menuItem];
            menuItem.target = self;
        } else {
            [self.recentTracksMenu removeItemAtIndex:self.recentTracksMenu.numberOfItems-1];
            NSMenuItem *menuItem = [self.recentTracksMenu insertItemWithTitle:[NSString stringWithFormat:NSLocalizedString(@"%@ – %@", nil),track.truncatedArtist, track.truncatedTrackName] action:@selector(openWebsite:) keyEquivalent:@"" atIndex:0];
            [self validateLinkFromMenuItem:menuItem];
            menuItem.target = self;
        }
    } else {
        for (NSMenuItem *menuItem in self.recentTracksMenu.itemArray) {
            [self validateLinkFromMenuItem:menuItem];
        }
    }
}

- (void)validateLinkFromMenuItem:(NSMenuItem *)menuItem
{
    Track *trackFromMenu = [self trackFromRecentTracksMenuItem:menuItem];
    //got track
    if (self.settings.integrationWithMusicPlayer && self.settings.showRecentTrackOnMusicPlayer) {
        [self validateCurrentMusicPlayerLinkForTrack:trackFromMenu andMenuItem:menuItem];
    } else {
        [self generateLastFmLinkForTrack:trackFromMenu andMenuItem:menuItem];
    }
}

- (Track *)trackFromRecentTracksMenuItem:(NSMenuItem *)menuItem
{
    __block Track *trackFromMenu;
    NSMenu *menu = [menuItem menu];
    NSInteger itemIndex = [menu indexOfItem:menuItem];
    [self.recentTracksController.tracks enumerateObjectsUsingBlock:^(Track *  _Nonnull song, NSUInteger idx, BOOL * _Nonnull stop) {
        if (idx == itemIndex) {
            trackFromMenu = song;
            *stop = YES;
        }
    }];
    return trackFromMenu;
}

- (void)validateCurrentMusicPlayerLinkForTrack:(Track *)track andMenuItem:(NSMenuItem *)menuItem
{
    if (![FXReachability sharedInstance].isReachable) {
        menuItem.enabled = NO;
        return;
    }
    [self.musicPlayer getTrackURL:track publicLink:NO forCurrentPlayerWithCompletionHandler:^(NSString *urlString) {
        if (urlString.length) {
            menuItem.enabled = YES;
        } else {
            menuItem.enabled = NO;
        }
    } failureHandler:^(NSError *error) {
        menuItem.enabled = NO;
    }];
}

- (NSString *)generateLastFmLinkForTrack:(Track *)track andMenuItem:(NSMenuItem *)menuItem
{
    NSString *artist = track.artist;
    artist = [artist stringByReplacingOccurrencesOfString:@"/" withString:@"%2F"];
    NSString *artistUTF8 = [artist stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    NSString *trackName = [track.trackName stringByReplacingOccurrencesOfString:@"/" withString:@"%2F"];
    NSString *trackUTF8 = [trackName stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    if (!trackUTF8 || !artistUTF8) {
        return nil;
    }
    NSString *link = [NSString stringWithFormat:@"http://www.last.fm/music/%@/_/%@", artistUTF8, trackUTF8];
    if (link) {
        menuItem.enabled = YES;
        return link;
    }
    menuItem.enabled = NO;
    return nil;
}

- (void)openWebsite:(NSMenuItem *)menuItem
{
    if (self.settings.integrationWithMusicPlayer && self.settings.showRecentTrackOnMusicPlayer) {
        Track *track = [self trackFromRecentTracksMenuItem:menuItem];
        
        [self openMusicPlayerPageForTrack:track andMenuItem:menuItem];
        DebugMode(@"Opening Music Player page for %@", track)

    } else {
        Track *track = [self trackFromRecentTracksMenuItem:menuItem];
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[self generateLastFmLinkForTrack:track andMenuItem:menuItem]]];
        DebugMode(@"Opening Last.fm page for %@", track)
    }
}

- (void)openMusicPlayerPageForTrack:(Track *)track andMenuItem:(NSMenuItem *)menuItem
{
    [self.musicPlayer openTrackPageForTrack:track withFailureHandler:^{
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[self generateLastFmLinkForTrack:track andMenuItem:menuItem]]];
    }];
}


- (void)hideRecentMenu
{
    if ([self.statusMenu.itemArray containsObject:self.recentTracksMenuItem]) {
        [self.statusMenu removeItem:self.recentTracksMenuItem];
        DebugMode(@"Hiding Recent Tracks menu")
    }
}

- (void)showRecentMenu
{
    if (![self.statusMenu.itemArray containsObject:self.recentTracksMenuItem]) {
        [self.statusMenu insertItem:self.recentTracksMenuItem atIndex:4];
        [self prepareRecentItemsMenu];
        DebugMode(@"Adding Recent Tracks menu")
    }
}

#pragma mark - iTunes Search Cache
- (NSArray *)cachedArrayForKey:(NSString *)key
{
    NSArray *result;
    if (self.musicPlayer.currentPlayer == MusicPlayeriTunes) {
        result = [self.cachediTunesSearchResults objectForKey:key];
    }
    return result;
}

- (void)cacheArray:(NSArray *)array forKey:(NSString *)key requestParams:(NSDictionary *)params maxAge:(NSTimeInterval)maxAge
{
    if (array) {
        if (self.musicPlayer.currentPlayer == MusicPlayeriTunes) {
            [self.cachediTunesSearchResults setObject:array forKey:key];
        }
    }
}

#pragma mark - Spotify Search Cache
- (id)cachedObjectForKey:(NSString *)key
{
    NSArray *result;
    if (self.musicPlayer.currentPlayer == MusicPlayerSpotify) {
        result = [self.cachedSpotifySearchResults objectForKey:key];
    }
    return result;
}

- (void)cacheResult:(id)result
             forKey:(NSString *)key
             maxAge:(NSTimeInterval)maxAge
{
    if (self.musicPlayer.currentPlayer == MusicPlayerSpotify) {
        [self.cachedSpotifySearchResults setObject:result forKey:key];
    }
}

#pragma mark - update available sources

- (void)addCheckmarkToSourceWithName:(NSString *)sourceName
{
    NSInteger index = [self.statusMenu indexOfItemWithTitle:sourceName];
    if (index != -1) {
        [self.statusMenu.itemArray enumerateObjectsUsingBlock:^(NSMenuItem * _Nonnull menuItem, NSUInteger idx, BOOL * _Nonnull stop) {
            if (menuItem.state == 1) {
                menuItem.state = 0;
                menuItem.enabled = YES;
            }
        }];

        NSMenuItem *item = [self.statusMenu itemAtIndex:index];
        item.state = 1;
    }
}

- (void)insertBothSources
{
    if (!self.bothPlayerAreAvailable) {
        NSMenuItem *separatorMenuItem = [NSMenuItem separatorItem];
        NSMenuItem * sourceLabelMenuItem= [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"SOURCE:", nil) action:nil keyEquivalent:@""];
        sourceLabelMenuItem.enabled = NO;
        
        sourceLabelMenuItem.attributedTitle = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"SOURCE:", nil) attributes:@{NSFontAttributeName:[NSFont systemFontOfSize:10], NSForegroundColorAttributeName:[NSColor lightGrayColor]}];
        
        NSMenuItem *iTunesMenuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"iTunes", nil) action:@selector(activateNewSource:) keyEquivalent:@""];
        NSMenuItem *spotifyMenuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Spotify", nil) action:@selector(activateNewSource:) keyEquivalent:@""];
        
        iTunesMenuItem.target = self;
        spotifyMenuItem.target = self;
        
        [self.statusMenu insertItem:separatorMenuItem atIndex:[self.statusMenu indexOfItemWithTag:12]];
        [self.statusMenu insertItem:sourceLabelMenuItem atIndex:[self.statusMenu indexOfItem:separatorMenuItem]+1];
        [self.statusMenu insertItem:iTunesMenuItem atIndex:[self.statusMenu indexOfItem:sourceLabelMenuItem]+1];
        [self.statusMenu insertItem:spotifyMenuItem atIndex:[self.statusMenu indexOfItem:iTunesMenuItem]+1];
        
        if (self.musicPlayer.currentPlayer == MusicPlayeriTunes) {
            [self addCheckmarkToSourceWithName:@"iTunes"];
        } else if (self.musicPlayer.currentPlayer == MusicPlayerSpotify) {
            [self addCheckmarkToSourceWithName:NSLocalizedString(@"Spotify", nil)];
        } else {
            spotifyMenuItem.enabled = YES;
            iTunesMenuItem.enabled = YES;
            spotifyMenuItem.state = 0;
            iTunesMenuItem.state = 0;
        }
        self.bothPlayerAreAvailable = YES;
    }
}

- (void)removeBothSources
{
    if (self.bothPlayerAreAvailable) {
        [self.statusMenu removeItemAtIndex:[self.statusMenu indexOfItemWithTitle:NSLocalizedString(@"SOURCE:", nil)]-1];
        [self.statusMenu removeItemAtIndex:[self.statusMenu indexOfItemWithTitle:NSLocalizedString(@"SOURCE:", nil)]];
        [self.statusMenu removeItemAtIndex:[self.statusMenu indexOfItemWithTitle:NSLocalizedString(@"iTunes", nil)]];
        [self.statusMenu removeItemAtIndex:[self.statusMenu indexOfItemWithTitle:NSLocalizedString(@"Spotify", nil)]];
        self.bothPlayerAreAvailable = NO;
    }
}

- (void)activateNewSource:(NSMenuItem *)menuItem
{
    if ([menuItem.title localizedCaseInsensitiveContainsString:@"itunes"] && self.musicPlayer.currentPlayer != MusicPlayeriTunes) {
        [self.musicPlayer changeSourceTo:MusicPlayeriTunes];
    } else if ([menuItem.title localizedCaseInsensitiveContainsString:@"spotify"] && self.musicPlayer.currentPlayer != MusicPlayerSpotify) {
        [self.musicPlayer changeSourceTo:MusicPlayerSpotify];
    }
}


#pragma mark - Getters
- (RecentTracksController *)recentTracksController
{
    if (!_recentTracksController) {
        _recentTracksController = [RecentTracksController sharedInstance];
    }
    return _recentTracksController;
}

- (MusicController *)musicController
{
    if (!_musicController) {
        _musicController = [MusicController sharedController];
    }
    return _musicController;
}

- (MusicScrobbler *)musicScrobbler
{
    if (!_musicScrobbler) {
        _musicScrobbler = [MusicScrobbler sharedScrobbler];
        _musicScrobbler.delegate = self.offlineScrobbler;

    }
    return _musicScrobbler;
}

- (SettingsController *)settings
{
    if (!_settings) {
        _settings = [SettingsController sharedSettings];
    }
    return _settings;
}

- (ItunesSearch *)iTunesSearch
{
    if (!_iTunesSearch) {
        _iTunesSearch = [ItunesSearch sharedInstance];
    }
    if (!_iTunesSearch.cacheDelegate) {
        _iTunesSearch.cacheDelegate = self;
    }
    return _iTunesSearch;
}

- (MPISpotifySearch *)spotifySearch
{
    if (!_spotifySearch) {
        _spotifySearch = [MPISpotifySearch sharedInstance];
    }
    if (!_spotifySearch.cache) {
        _spotifySearch.cache = self;
    }
    return _spotifySearch;
}

- (PINCache *)cachediTunesSearchResults
{
    if (!_cachediTunesSearchResults) {
        _cachediTunesSearchResults = [[PINCache alloc] initWithName:@"iTunesSearchCache"];
        _cachediTunesSearchResults.diskCache.ageLimit = 60 * 60 * 24;
        _cachediTunesSearchResults.memoryCache.ageLimit = 60 * 60;
    }
    return _cachediTunesSearchResults;
}

- (PINCache *)cachedSpotifySearchResults
{
    if (!_cachedSpotifySearchResults) {
        _cachedSpotifySearchResults = [[PINCache alloc] initWithName:@"SpotifySearchCache"];
        _cachedSpotifySearchResults.diskCache.ageLimit = 60 * 60 * 24;
        _cachedSpotifySearchResults.memoryCache.ageLimit = 60 * 60;
    }
    return _cachedSpotifySearchResults;
}

- (OfflineScrobbler *)offlineScrobbler
{
    if (!_offlineScrobbler) {
        _offlineScrobbler = [OfflineScrobbler sharedInstance];
    }
    return _offlineScrobbler;
}

- (MusicPlayer *)musicPlayer
{
    if (!_musicPlayer) {
        _musicPlayer = [MusicPlayer sharedPlayer];
    }
    return _musicPlayer;
}

- (NSCache *)menubarIconsCache
{
    if (!_menubarIconsCache) {
        _menubarIconsCache = [NSCache new];
    }
    return _menubarIconsCache;
}

@end
