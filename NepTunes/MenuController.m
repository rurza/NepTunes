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
#import "LastFm.h"
#import "PreferencesController.h"
#import <PINCache.h>
#import "OfflineScrobbler.h"
#import "CoverWindowController.h"
#import "ControlViewController.h"
#import "AboutWindowController.h"

@import QuartzCore;

static NSUInteger const kFPS = 30;
static NSUInteger const kNumberOfFrames = 10;

@interface MenuController () <ItunesSearchCache, NSWindowDelegate>

@property (nonatomic) NSStatusItem *statusItem;
@property (nonatomic) IBOutlet NSMenu *recentTracksMenu;
@property (nonatomic) IBOutlet NSMenuItem *recentTracksMenuItem;
@property (nonatomic) IBOutlet MusicController *musicController;
@property (nonatomic) RecentTracksController *recentTracksController;
@property (nonatomic) MusicScrobbler *musicScrobbler;
@property (nonatomic) SettingsController *settings;
@property (nonatomic) ItunesSearch *iTunesSearch;
@property (nonatomic) NSUInteger animationCurrentStep;
@property (nonatomic) PINCache *cachediTunesSearchResults;
@property (nonatomic) PreferencesController *preferencesController;
//reachability
@property (nonatomic) BOOL reachability;
@property (nonatomic) OfflineScrobbler *offlineScrobbler;
@property (nonatomic) AboutWindowController *aboutWindowController;
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



-(void)awakeFromNib
{
    //System status bar icon
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
    
    [self updateMenu];    
}

#pragma mark - Reachability


-(void)setupReachability
{
    //1. this must be first
    self.reachability = YES;
    //2. this must be second
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityDidChange:) name:FXReachabilityStatusDidChangeNotification object:nil];
    
}

-(void)reachabilityDidChange:(NSNotification *)note
{
    BOOL reachable = [FXReachability isReachable];
    if (!reachable && self.musicController.playerState == iTunesEPlSPlaying && self.settings.session) {
        [[UserNotificationsController sharedNotificationsController] displayNotificationThatInternetConnectionIsDown];
        self.reachability = NO;
    } else if (reachable && !self.reachability && self.musicScrobbler.currentTrack && self.offlineScrobbler.tracks.count && self.settings.session) {
        [[UserNotificationsController sharedNotificationsController] displayNotificationThatInternetConnectionIsBack];
        self.reachability = YES;
    }
    [self updateMenu];
}

#pragma mark - Status Bar Icon

-(void)installStatusBar
{
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    NSImage *icon = [NSImage imageNamed:@"statusIcon"];
    [icon setTemplate:YES];
    self.statusItem.image = icon;
    self.statusItem.menu = self.statusMenu;
}



-(void)removeStatusBarItem
{
    [[NSStatusBar systemStatusBar] removeStatusItem:self.statusItem];
    self.statusItem = nil;
}

#pragma mark Status Bar Icon Animation

-(void)blinkMenuIcon
{
    if (self.statusItem) {
        [self animationStepForward:YES];
    }
}

-(void)animationStepForward:(BOOL)forward
{
    dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, 1.0 / kFPS * NSEC_PER_SEC);
    
    dispatch_after(delay, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        if (forward) {
            self.animationCurrentStep++;
        } else {
            self.animationCurrentStep--;
        }
        
        if (forward) {
            if (self.animationCurrentStep <= kNumberOfFrames) {
                [self animationStepForward:YES];
            } else {
                self.animationCurrentStep = 0;
            }
        } else {
            if (self.animationCurrentStep > 0) {
                [self animationStepForward:NO];
            } else {
                self.animationCurrentStep = 0;
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.animationCurrentStep != 0) {
                self.statusItem.image = [self imageForStep:self.animationCurrentStep];
            } else {
                if (forward) {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [self backwardAnimation];
                    });
                } else {
                    [self setOriginalIcon];
                }
            }
        });
    });
}

-(NSImage *)imageForStep:(NSUInteger)step
{
    NSImage *image;
    if (step != 0) {
        image = [NSImage imageNamed:[NSString stringWithFormat:@"statusIcon%lu", (unsigned long)step]];
    } else image = [NSImage imageNamed:@"statusIcon"];
    [image setTemplate:YES];
    return image;
}


-(void)backwardAnimation
{
    self.animationCurrentStep = 10;
    [self animationStepForward:NO];    
}

-(void)setOriginalIcon
{
    NSImage *icon = [NSImage imageNamed:@"statusIcon"];
    [icon setTemplate:YES];
    self.statusItem.image = icon;
}


#pragma mark - Last.fm related
-(IBAction)loveSong:(id)sender {
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


-(IBAction)showSimilarArtists:(id)sender
{
    NSString *str = self.musicScrobbler.currentTrack.artist;
    str = [str stringByReplacingOccurrencesOfString:@"/" withString:@"%2F"];
    NSString *url = [str stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    if (url.length > 0) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.last.fm/music/%@/+similar", url]]];
    }
}


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


-(IBAction)quit:(id)sender
{
    [[NSApplication sharedApplication] terminate:self];
}

#pragma mark - Preferences

-(IBAction)openPreferences:(id)sender
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

-(BOOL)windowShouldClose:(id)sender
{
    return YES;
}

- (void)windowWillClose:(NSNotification *)notification
{
    NSWindow* window = notification.object;
    if (window == self.preferencesController.window) {
        self.preferencesController = nil;
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowWillCloseNotification object:window];
    } else if (window == self.aboutWindowController.window) {
        self.aboutWindowController = nil;
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowWillCloseNotification object:window];
    }
}

#pragma mark Update menu
-(void)updateMenu {
    [self updateRecentMenu];
    [self updateLoveSongMenuItem];
    [self updateShowUserProfileMenuItem];
    [self updateSimilarArtistMenuItem];
}

-(void)updateLoveSongMenuItem
{
    BOOL internetIsReachable = [FXReachability isReachable];
    //if user is logged in, there is Internet conenction and we have a track
    if (self.settings.session && self.musicScrobbler.currentTrack && internetIsReachable && self.musicController.isiTunesRunning) {
        //if user choose to love track also in iTunes  and track listened is available to love in iTunes
        if (self.settings.integrationWithiTunes && self.settings.loveTrackOniTunes) {
            if (self.musicController.currentTrack.artist.length && self.musicController.currentTrack.name.length) {
                self.loveSongMenuTitle.title = [NSString stringWithFormat:NSLocalizedString(@"Love %@ On Last.fm & iTunes", nil), self.musicScrobbler.currentTrack.trackName];
            } else {
                self.loveSongMenuTitle.title = [NSString stringWithFormat:NSLocalizedString(@"Love %@ On Last.fm", nil), self.musicScrobbler.currentTrack.trackName];
            }
            //love on Last.fm and in iTunes
        } else {
            //love track only on Last.fm
            self.loveSongMenuTitle.title = [NSString stringWithFormat:NSLocalizedString(@"Love %@ On Last.fm", nil), self.musicScrobbler.currentTrack.trackName];
        }
        //if user ISN'T logged in, we have a track
    } else if (!self.settings.session && self.musicScrobbler.currentTrack) {
        //if user choose to love track also in iTunes and track listened is available to love in iTunes
        if (self.settings.integrationWithiTunes && self.settings.loveTrackOniTunes) {
            if (self.musicController.currentTrack.artist.length && self.musicController.currentTrack.name.length) {
                self.loveSongMenuTitle.title = [NSString stringWithFormat:NSLocalizedString(@"Love %@ On iTunes", nil), self.musicScrobbler.currentTrack.trackName];
            } else {
                self.loveSongMenuTitle.title = [NSString stringWithFormat:NSLocalizedString(@"Love %@ (Log In)", nil), self.musicScrobbler.currentTrack.trackName];
            }
        } else {
            self.loveSongMenuTitle.title = [NSString stringWithFormat:NSLocalizedString(@"Love %@ (Log In)", nil), self.musicScrobbler.currentTrack.trackName];
        }
        //if Internet connection ISN'T reachable BUT user choose to love track also in iTunes and we have a track
    } else if (!internetIsReachable && [self userHasTurnedOnIntegrationAndLovingMusicOniTunes] && self.musicScrobbler.currentTrack  && self.musicController.isiTunesRunning) {
        self.loveSongMenuTitle.title = [NSString stringWithFormat:NSLocalizedString(@"Love %@ On iTunes", nil), self.musicScrobbler.currentTrack.trackName];
    }   //if user is logged in but we don't have a track
    else if (!self.musicController.isiTunesRunning || self.settings.session || !self.musicScrobbler.currentTrack ) {
        self.loveSongMenuTitle.title = [NSString stringWithFormat:NSLocalizedString(@"Love Track", nil)];
    }
    else {
        self.loveSongMenuTitle.title = [NSString stringWithFormat:NSLocalizedString(@"Love Track", nil)];
    }
    
    //when the button must be disabled
    if ((!internetIsReachable && ![self userHasTurnedOnIntegrationAndLovingMusicOniTunes]) || (!self.settings.session && ![self userHasTurnedOnIntegrationAndLovingMusicOniTunes]) || !self.musicScrobbler.currentTrack || (!self.settings.session && [self userHasTurnedOnIntegrationAndLovingMusicOniTunes] && !self.musicController.currentTrack.name.length)) {
        self.loveSongMenuTitle.enabled = NO;
    } else {
        self.loveSongMenuTitle.enabled = YES;
    }
}

-(BOOL)userHasTurnedOnIntegrationAndLovingMusicOniTunes
{
    if (self.settings.integrationWithiTunes && self.settings.loveTrackOniTunes) {
        return YES;
    }
    return NO;
}

-(void)updateSimilarArtistMenuItem
{
    BOOL internetIsReachable = [FXReachability isReachable];
    if (self.musicController.isiTunesRunning) {
        if (self.musicScrobbler.currentTrack) {
            self.similarArtistMenuTtitle.enabled = YES;
            self.similarArtistMenuTtitle.title = [NSString stringWithFormat:NSLocalizedString(@"Similar Artists To %@", nil), self.musicScrobbler.currentTrack.artist];
            if (!internetIsReachable) {
                self.similarArtistMenuTtitle.enabled = NO;
            }
            if (self.settings.showSimilarArtistsOnAppleMusic && self.settings.integrationWithiTunes && internetIsReachable) {
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


-(void)prepareSimilarArtistsMenuWithArtists:(NSArray *)artists
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
            [self.iTunesSearch getIdForArtist:artist successHandler:^(NSArray *result) {
                if (result.count) {
                    [weakSelf enumerateMenuItemsToFindArtist:(NSString *)result.firstObject[@"artistName"] withAsciiCoding:NO];
                } else {
                    [weakSelf.iTunesSearch getIdForArtist:[weakSelf asciiString:artist] successHandler:^(NSArray *result) {
                        if (result.count) {
                            [weakSelf enumerateMenuItemsToFindArtist:(NSString *)result.firstObject[@"artistName"] withAsciiCoding:YES];
                        } else {
                            [weakSelf.similarArtistMenuTtitle.submenu.itemArray enumerateObjectsUsingBlock:^(NSMenuItem * _Nonnull menuItem, NSUInteger idx, BOOL * _Nonnull stop) {
                                if ([menuItem.title.lowercaseString isEqualToString:artist.lowercaseString]) {
                                    menuItem.enabled = NO;
                                }
                            }];
                        }
                        
                    } failureHandler:^(NSError *error) {
                        
                    }];
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

-(void)enumerateMenuItemsToFindArtist:(NSString *)artist withAsciiCoding:(BOOL)coding
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
            menuItem.action = @selector(openiTunesLinkFromMenuItem:);
            menuItem.target = self;
        }
    }];
}

-(void)openiTunesLinkFromMenuItem:(NSMenuItem *)menuItem
{
    [self openiTunesLinkForArtist:menuItem.title];
}

-(void)openiTunesLinkForArtist:(NSString *)artist
{
    __weak typeof(self) weakSelf = self;
    [self.iTunesSearch getIdForArtist:artist successHandler:^(NSArray *result) {
        if (result.count) {
            [weakSelf openLocationWithURL:(NSString *)result.firstObject[@"artistLinkUrl"]];
        } else {
            [weakSelf.iTunesSearch getIdForArtist:[self asciiString:artist] successHandler:^(NSArray *result) {
                if (result.count) {
                    [weakSelf openLocationWithURL:(NSString *)result.firstObject[@"artistLinkUrl"]];
                }
            } failureHandler:nil];
        }
    } failureHandler:nil];
}

-(void)openLocationWithURL:(NSString *)url
{
    NSString *link = [url stringByReplacingOccurrencesOfString:@"https://" withString:@"itmss://"];
    //Compaign
    link = [link stringByAppendingString:@"&ct=neptunes"];

    NSLog(@"%@", link);
    [[NSWorkspace sharedWorkspace] launchAppWithBundleIdentifier:@"com.apple.iTunes" options:NSWorkspaceLaunchDefault additionalEventParamDescriptor:nil launchIdentifier:NULL];
    if (self.musicController.isiTunesRunning) {
        [self.musicController.iTunes openLocation:link];
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.musicController.iTunes openLocation:link];
        });
    }
}

-(NSString *)asciiString:(NSString *)string
{
    NSData *asciiEncoded = [string.lowercaseString dataUsingEncoding:NSASCIIStringEncoding
                                                allowLossyConversion:YES];
    
    NSString *stringInAscii = [[NSString alloc] initWithData:asciiEncoded
                                                    encoding:NSASCIIStringEncoding];
    return stringInAscii;
    
}

-(void)updateShowUserProfileMenuItem
{
    BOOL internetIsReachable = [FXReachability isReachable];
    
    if (self.settings.session && internetIsReachable) {
        self.profileMenuTitle.title = [NSString stringWithFormat:NSLocalizedString(@"%@'s Profile", nil), self.settings.username];
        self.profileMenuTitle.enabled = YES;
    } else if (self.settings.session && !internetIsReachable) {
        self.profileMenuTitle.title = [NSString stringWithFormat:NSLocalizedString(@"%@'s Profile", nil), self.settings.username];
        self.profileMenuTitle.enabled = NO;
    } else {
        self.profileMenuTitle.title = [NSString stringWithFormat:NSLocalizedString(@"Last.fm Profile (Log In)", nil)];
        self.profileMenuTitle.enabled = NO;
    }
}


#pragma mark - Recent Items

-(void)prepareRecentItemsMenu
{
    if (self.settings.debugMode) {
        NSLog(@"Preparing Recent Tracks menu");
    }
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
        NSMenuItem *menuItem = [weakSelf.recentTracksMenu addItemWithTitle:[NSString stringWithFormat:NSLocalizedString(@"%@ – %@", nil), track.artist, track.trackName] action:@selector(openWebsite:) keyEquivalent:@""];
        menuItem.target = self;
    }];
}


-(void)updateRecentMenu
{
    if (self.settings.debugMode) {
        NSLog(@"Updating Recent Tracks menu");
    }
    Track *track = self.musicScrobbler.currentTrack;
    if ([self.recentTracksController addTrackToRecentMenu:track]) {
        self.recentTracksMenuItem.enabled = YES;
        
        if (self.recentTracksMenu.numberOfItems < [SettingsController sharedSettings].numberOfTracksInRecent.intValue) {
            NSMenuItem *menuItem = [self.recentTracksMenu insertItemWithTitle:[NSString stringWithFormat:NSLocalizedString(@"%@ – %@", nil), track.artist, track.trackName] action:@selector(openWebsite:) keyEquivalent:@"" atIndex:0];
            [self validateLinkFromMenuItem:menuItem];
            menuItem.target = self;
        } else {
            [self.recentTracksMenu removeItemAtIndex:self.recentTracksMenu.numberOfItems-1];
            NSMenuItem *menuItem = [self.recentTracksMenu insertItemWithTitle:[NSString stringWithFormat:NSLocalizedString(@"%@ – %@", nil),track.artist, track.trackName] action:@selector(openWebsite:) keyEquivalent:@"" atIndex:0];
            [self validateLinkFromMenuItem:menuItem];
            menuItem.target = self;
        }
    } else {
        for (NSMenuItem *menuItem in self.recentTracksMenu.itemArray) {
            [self validateLinkFromMenuItem:menuItem];
        }
    }
}



-(void)validateLinkFromMenuItem:(NSMenuItem *)menuItem
{
    Track *trackFromMenu = [self returnTrackFromMenuItem:menuItem];
    //got track
    if (self.settings.integrationWithiTunes && self.settings.showRecentTrackIniTunes) {
        [self validateAppleMusicLinkForTrack:trackFromMenu andMenuItem:menuItem];
    } else {
        [self generateLastFmLinkForTrack:trackFromMenu andMenuItem:menuItem];
    }
}

-(Track *)returnTrackFromMenuItem:(NSMenuItem *)menuItem
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

-(void)validateAppleMusicLinkForTrack:(Track *)track andMenuItem:(NSMenuItem *)menuItem
{
    if (![FXReachability sharedInstance].isReachable) {
        menuItem.enabled = NO;
        return;
    }
    [self.iTunesSearch getIdForArtist:track.artist successHandler:^(NSArray *result) {
        if (result.count) {
            menuItem.enabled = YES;
        } else {
            menuItem.enabled = NO;
        }
    } failureHandler:^(NSError *error) {
        menuItem.enabled = NO;
    }];
}

-(NSString *)generateLastFmLinkForTrack:(Track *)track andMenuItem:(NSMenuItem *)menuItem
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

-(void)openWebsite:(NSMenuItem *)menuItem
{
    if (self.settings.integrationWithiTunes && self.settings.showRecentTrackIniTunes) {
        Track *track = [self returnTrackFromMenuItem:menuItem];
        
        [self openAppleMusicPageForTrack:track andMenuItem:menuItem];
        if (self.settings.debugMode) {
            NSLog(@"Opening Apple Music page for %@", track);
        }

    } else {
        Track *track = [self returnTrackFromMenuItem:menuItem];
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[self generateLastFmLinkForTrack:track andMenuItem:menuItem]]];
        if (self.settings.debugMode) {
            NSLog(@"Opening Last.fm page for %@", track);
        }
    }
}

-(void)openAppleMusicPageForTrack:(Track *)track andMenuItem:(NSMenuItem *)menuItem
{
    __weak typeof(self) weakSelf = self;
    [self.iTunesSearch getTrackWithName:track.trackName artist:track.artist album:track.album limitOrNil:nil successHandler:^(NSArray *result) {
        if (result.count) {
            NSString *link = [(NSString *)result.firstObject[@"trackViewUrl"] stringByReplacingOccurrencesOfString:@"https://" withString:@"itmss://"];
            link = [link stringByAppendingString:@"&ct=neptunes"];
            [[NSWorkspace sharedWorkspace] launchAppWithBundleIdentifier:@"com.apple.iTunes" options:NSWorkspaceLaunchDefault additionalEventParamDescriptor:nil launchIdentifier:NULL];
            if (weakSelf.musicController.isiTunesRunning) {
                [self.musicController.iTunes openLocation:link];
            } else {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self.musicController.iTunes openLocation:link];
                });
            }
        } else {
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[self generateLastFmLinkForTrack:track andMenuItem:menuItem]]];
        }
        
    } failureHandler:^(NSError *error) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[self generateLastFmLinkForTrack:track andMenuItem:menuItem]]];
    }];
    
}

-(void)hideRecentMenu
{
    if ([self.statusMenu.itemArray containsObject:self.recentTracksMenuItem]) {
        [self.statusMenu removeItem:self.recentTracksMenuItem];
        if (self.settings.debugMode) {
            NSLog(@"Hiding Recent Tracks menu");
        }
    }
    
}

-(void)showRecentMenu
{
    if (![self.statusMenu.itemArray containsObject:self.recentTracksMenuItem]) {
        [self.statusMenu insertItem:self.recentTracksMenuItem atIndex:2];
        [self prepareRecentItemsMenu];
        if (self.settings.debugMode) {
            NSLog(@"Adding Recent Tracks menu");
        }
    }
}

#pragma mark - iTunes Search Cache
- (NSArray *)cachedArrayForKey:(NSString *)key
{
    NSArray *result = [self.cachediTunesSearchResults objectForKey:key];
    return result;
}

- (void)cacheArray:(NSArray *)array forKey:(NSString *)key requestParams:(NSDictionary *)params maxAge:(NSTimeInterval)maxAge
{
    [self.cachediTunesSearchResults setObject:array forKey:key];
}

#pragma mark - Getters

-(RecentTracksController *)recentTracksController
{
    if (!_recentTracksController) {
        _recentTracksController = [RecentTracksController sharedInstance];
    }
    return _recentTracksController;
}

-(MusicController *)musicController
{
    if (!_musicController) {
        _musicController = [MusicController sharedController];
    }
    return _musicController;
}

-(MusicScrobbler *)musicScrobbler
{
    if (!_musicScrobbler) {
        _musicScrobbler = [MusicScrobbler sharedScrobbler];
        _musicScrobbler.delegate = self.offlineScrobbler;

    }
    return _musicScrobbler;
}

-(SettingsController *)settings
{
    if (!_settings) {
        _settings = [SettingsController sharedSettings];
    }
    return _settings;
}

-(ItunesSearch *)iTunesSearch
{
    if (!_iTunesSearch) {
        _iTunesSearch = [ItunesSearch sharedInstance];
        _iTunesSearch.affiliateToken = @"1010l3j7";
        _iTunesSearch.campaignToken = @"neptunes";
        _iTunesSearch.cacheDelegate = self;
    }
    return _iTunesSearch;
}

-(PINCache *)cachediTunesSearchResults
{
    if (!_cachediTunesSearchResults) {
        _cachediTunesSearchResults = [[PINCache alloc] initWithName:@"iTunesSearchCache"];
        _cachediTunesSearchResults.diskCache.ageLimit = 60 * 60 * 24;
        _cachediTunesSearchResults.memoryCache.ageLimit = 60 * 60;
    }
    return _cachediTunesSearchResults;
}

-(OfflineScrobbler *)offlineScrobbler
{
    if (!_offlineScrobbler) {
        _offlineScrobbler = [OfflineScrobbler sharedInstance];
    }
    return _offlineScrobbler;
}

@end