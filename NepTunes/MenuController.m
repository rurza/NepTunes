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

@import QuartzCore;

static NSUInteger const kFPS = 30;
static NSUInteger const kNumberOfFrames = 10;

@interface MenuController ()

@property (nonatomic) NSStatusItem *statusItem;
@property (nonatomic) IBOutlet NSMenu *statusMenu;
@property (nonatomic) IBOutlet NSMenu *recentTracksMenu;
@property (nonatomic) IBOutlet NSMenuItem *recentTracksMenuItem;
@property (nonatomic) IBOutlet MusicController *musicController;
@property (nonatomic, weak) IBOutlet AppDelegate *appDelegate;
@property (nonatomic) RecentTracksController *recentTracksController;
@property (nonatomic) MusicScrobbler *musicScrobbler;
@property (nonatomic) SettingsController *settings;
@property (nonatomic) ItunesSearch *iTunesSearch;
@property (nonatomic) NSUInteger animationCurrentStep;
@end

@implementation MenuController


-(void)awakeFromNib
{
    //System status bar icon
    if (![SettingsController sharedSettings].hideStatusBarIcon) {
        [self installStatusBar];
    }
    
    [self prepareRecentItemsMenu];
    //first launch
    if (!self.musicScrobbler.scrobbler.session && [SettingsController sharedSettings].openPreferencesWhenThereIsNoUser) {
        [self openPreferences:self];
    }
    //Are we offline?
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateMenu) name:FXReachabilityStatusDidChangeNotification object:nil];
    
    if ([SettingsController sharedSettings].numberOfTracksInRecent.integerValue != 0) {
        [self showRecentMenu];
    } else {
        [self hideRecentMenu];
    }
    self.statusMenu.autoenablesItems = NO;
    [self.loveSongMenuTitle setEnabled:NO];
    
    [self updateMenu];
}


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

-(void)blinkMenuIcon
{
    if (self.statusItem) {
        [self animationStepForward:YES];
    }
}

- (void)animationStepForward:(BOOL)forward
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
    SettingsController *settings = [SettingsController sharedSettings];
    if (settings.session) {
        [self.musicScrobbler loveCurrentTrackWithCompletionHandler:^(Track *track, NSImage *artwork) {
            [[UserNotificationsController sharedNotificationsController] displayNotificationThatTrackWasLoved:track withArtwork:(NSImage *)artwork];
        }];
    } else {
        [self openPreferences:nil];
    }
    if (settings.integrationWithiTunes && settings.loveTrackOniTunes) {
        [self.musicController loveTrackIniTunes];
    }
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


-(IBAction)quit:(id)sender
{
    [[NSApplication sharedApplication] terminate:self];
}


-(IBAction)openPreferences:(id)sender
{
    [NSApp activateIgnoringOtherApps:YES];
    [self.appDelegate.window makeKeyAndOrderFront:nil];
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
    if (self.settings.session && self.musicScrobbler.currentTrack && internetIsReachable) {
        //if user choose to love track also in iTunes  and track listened is available to love in iTunes
        if (self.settings.integrationWithiTunes && self.settings.loveTrackOniTunes && self.musicController.iTunes.currentTrack.artist.length && self.musicController.iTunes.currentTrack.name.length) {
            //love on Last.fm and in iTunes
            self.loveSongMenuTitle.title = [NSString stringWithFormat:NSLocalizedString(@"Love %@ On Last.fm & iTunes", nil), self.musicScrobbler.currentTrack.trackName];
        } else {
            //love track only on Last.fm
            self.loveSongMenuTitle.title = [NSString stringWithFormat:NSLocalizedString(@"Love %@ On Last.fm", nil), self.musicScrobbler.currentTrack.trackName];
        }
        //if user ISN'T logged in, we have a track
    } else if (!self.settings.session && self.musicScrobbler.currentTrack) {
        //if user choose to love track also in iTunes and track listened is available to love in iTunes
        if (self.settings.integrationWithiTunes && self.settings.loveTrackOniTunes && self.musicController.iTunes.currentTrack.artist.length && self.musicController.iTunes.currentTrack.name.length) {
            self.loveSongMenuTitle.title = [NSString stringWithFormat:NSLocalizedString(@"Love %@ On iTunes", nil), self.musicScrobbler.currentTrack.trackName];
        } else {
            self.loveSongMenuTitle.title = [NSString stringWithFormat:NSLocalizedString(@"Love %@ (Log In)", nil), self.musicScrobbler.currentTrack.trackName];
        }
        //if Internet connection ISN'T reachable BUT user choose to love track also in iTunes and we have a track
    } else if (!internetIsReachable && [self userHasTurnedOnIntegrationAndLovingMusicOniTunes] && self.musicScrobbler.currentTrack) {
        self.loveSongMenuTitle.title = [NSString stringWithFormat:NSLocalizedString(@"Love %@ On iTunes", nil), self.musicScrobbler.currentTrack.trackName];
    }   //if user is logged in but we don't have a track
    else if (self.settings.session) {
        self.loveSongMenuTitle.title = [NSString stringWithFormat:NSLocalizedString(@"Love Track", nil)];
    }  else  {
        self.loveSongMenuTitle.title = [NSString stringWithFormat:NSLocalizedString(@"Love Track (Log In)", nil)];
    }
    
    
    //when the button must be disabled
    if ((!internetIsReachable && ![self userHasTurnedOnIntegrationAndLovingMusicOniTunes])|| (!self.settings.session && ![self userHasTurnedOnIntegrationAndLovingMusicOniTunes]) || (!self.settings.session && [self userHasTurnedOnIntegrationAndLovingMusicOniTunes] && !self.musicController.iTunes.currentTrack.name.length) || !self.musicScrobbler.currentTrack) {
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
    if (self.musicScrobbler.currentTrack) {
        self.similarArtistMenuTtitle.enabled = YES;
        self.similarArtistMenuTtitle.title = [NSString stringWithFormat:NSLocalizedString(@"Similar Artists To %@", nil), self.musicScrobbler.currentTrack.artist];
        if (!internetIsReachable) {
            self.similarArtistMenuTtitle.enabled = NO;
        }
        if (self.settings.showSimilarArtistsOnAppleMusic && self.settings.integrationWithiTunes) {
            __weak typeof(self) weakSelf = self;
            if (![self.similarArtistMenuTtitle hasSubmenu]) {
                [self.musicScrobbler.scrobbler getSimilarArtistsTo:self.musicScrobbler.currentTrack.artist successHandler:^(NSArray *result) {
                    if (result.count) {
                        [weakSelf prepareSimilarArtistsMenuWithArtists:result];
                    } else {
                        [weakSelf.similarArtistMenuTtitle.submenu removeAllItems];
                        weakSelf.similarArtistMenuTtitle.submenu = nil;
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
        self.similarArtistMenuTtitle.title = [NSString stringWithFormat:NSLocalizedString(@"Show Similar Artists", nil)];
    }
}


-(void)prepareSimilarArtistsMenuWithArtists:(NSArray *)artists
{
    if (!self.similarArtistMenuTtitle.hasSubmenu) {
        NSMenu *submenu = [[NSMenu alloc] init];
        submenu.autoenablesItems = NO;
        self.similarArtistMenuTtitle.submenu = submenu;
    } else {
        [self.similarArtistMenuTtitle.submenu removeAllItems];
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
    NSLog(@"%@", link);
    [[NSWorkspace sharedWorkspace] launchAppWithBundleIdentifier:@"com.apple.iTunes" options:NSWorkspaceLaunchDefault additionalEventParamDescriptor:nil launchIdentifier:NULL];
    [self.musicController.iTunes openLocation:link];
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
        [[NSWorkspace sharedWorkspace] launchAppWithBundleIdentifier:@"com.apple.iTunes" options:NSWorkspaceLaunchDefault additionalEventParamDescriptor:nil launchIdentifier:NULL];
        [self openAppleMusicPageForTrack:track andMenuItem:menuItem];
    } else {
        Track *track = [self returnTrackFromMenuItem:menuItem];
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[self generateLastFmLinkForTrack:track andMenuItem:menuItem]]];
    }
}

-(void)openAppleMusicPageForTrack:(Track *)track andMenuItem:(NSMenuItem *)menuItem
{
    [self.iTunesSearch getTrackWithName:track.trackName artist:track.artist album:track.album limitOrNil:nil successHandler:^(NSArray *result) {
        if (result.count) {
#if DEBUG
            NSLog(@"%@", result);
#endif
            NSString *link = [(NSString *)result.firstObject[@"trackViewUrl"] stringByReplacingOccurrencesOfString:@"https://" withString:@"itmss://"];
            [[NSWorkspace sharedWorkspace] launchAppWithBundleIdentifier:@"com.apple.iTunes" options:NSWorkspaceLaunchDefault additionalEventParamDescriptor:nil launchIdentifier:NULL];

            [self.musicController.iTunes openLocation:link];
            
        } else {
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[self generateLastFmLinkForTrack:track andMenuItem:menuItem]]];
        }
        
    } failureHandler:^(NSError *error) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[self generateLastFmLinkForTrack:track andMenuItem:menuItem]]];
    }];
    
}
#pragma mark - NSMenuValidation
//
//-(BOOL)validateMenuItem:(NSMenuItem *)menuItem
//{
//    if (menuItem.action == @selector(showUserProfile:)) {
//        if ([SettingsController sharedSettings].session) {
//            return YES;
//        } else {
//            return NO;
//        }
//    }
//    if ([self validateLinkFromMenuItem:menuItem]) {
//        return YES;
//    }
//    return NO;
//}

-(void)hideRecentMenu
{
    if ([self.statusMenu.itemArray containsObject:self.recentTracksMenuItem]) {
        [self.statusMenu removeItem:self.recentTracksMenuItem];
    }
}

-(void)showRecentMenu
{
    if (![self.statusMenu.itemArray containsObject:self.recentTracksMenuItem]) {
        [self.statusMenu insertItem:self.recentTracksMenuItem atIndex:2];
        [self prepareRecentItemsMenu];
    }
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
        _iTunesSearch.maxCacheAge = 60 * 60;
    }
    return _iTunesSearch;
}

@end