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
    [self udapteShowUserProfileMenuItem];
    [self updateSimilarArtistMenuItem];
}

-(void)updateLoveSongMenuItem
{
    BOOL internetIsReachable = [FXReachability isReachable];
    
    if (self.settings.session && internetIsReachable && self.musicController.playerState == iTunesEPlSPlaying) {
        if (self.settings.integrationWithiTunes && self.settings.loveTrackOniTunes) {
            self.loveSongMenuTitle.title = [NSString stringWithFormat:NSLocalizedString(@"Love %@", nil), self.musicScrobbler.currentTrack.trackName ? self.musicScrobbler.currentTrack.trackName : @""];
        } else {
            self.loveSongMenuTitle.title = [NSString stringWithFormat:NSLocalizedString(@"Love %@ on Last.fm", nil), self.musicScrobbler.currentTrack.trackName ? self.musicScrobbler.currentTrack.trackName : @""];
        }
        self.loveSongMenuTitle.enabled = YES;
    } else if (self.settings.session && !internetIsReachable && self.musicController.playerState == iTunesEPlSPlaying) {
        if (self.settings.integrationWithiTunes && self.settings.loveTrackOniTunes) {
            self.loveSongMenuTitle.title = [NSString stringWithFormat:NSLocalizedString(@"Love %@", nil), self.musicScrobbler.currentTrack.trackName ? self.musicScrobbler.currentTrack.trackName : @""];
        } else {
            self.loveSongMenuTitle.title = [NSString stringWithFormat:NSLocalizedString(@"Love %@ on Last.fm", nil), self.musicScrobbler.currentTrack.trackName ? self.musicScrobbler.currentTrack.trackName : @""];
        }
        self.loveSongMenuTitle.enabled = NO;
    } else if (!self.settings.session && self.musicController.playerState == iTunesEPlSPlaying) {
        self.loveSongMenuTitle.title = [NSString stringWithFormat:NSLocalizedString(@"Love %@ (Log in)", nil), self.musicScrobbler.currentTrack.trackName ? self.musicScrobbler.currentTrack.trackName : @""];
        self.loveSongMenuTitle.enabled = NO;
    } else if (self.settings.session) {
        self.loveSongMenuTitle.enabled = NO;
        self.loveSongMenuTitle.title = [NSString stringWithFormat:NSLocalizedString(@"Love track", nil)];
    } else  {
        self.loveSongMenuTitle.title = [NSString stringWithFormat:NSLocalizedString(@"Love track (Log in)", nil)];
        self.loveSongMenuTitle.enabled = NO;
    }
}

-(void)updateSimilarArtistMenuItem
{
    BOOL internetIsReachable = [FXReachability isReachable];
    if (self.musicController.playerState == iTunesEPlSPlaying) {
        self.similarArtistMenuTtitle.enabled = YES;
        self.similarArtistMenuTtitle.title = [NSString stringWithFormat:NSLocalizedString(@"Similar artists to %@", nil), self.musicScrobbler.currentTrack.artist ? self.musicScrobbler.currentTrack.artist : @""];
        if (!internetIsReachable) {
            self.similarArtistMenuTtitle.enabled = NO;
        }
        if (self.settings.showSimilarArtistsOnAppleMusic && self.settings.integrationWithiTunes) {
            if (![self.similarArtistMenuTtitle hasSubmenu]) {
                [self.musicScrobbler.scrobbler getSimilarArtistsTo:self.musicScrobbler.currentTrack.artist successHandler:^(NSArray *result) {
                    if (result.count) {
                        [self prepareMenuWithArtists:result];
                    }
                } failureHandler:^(NSError *error) {
                    self.similarArtistMenuTtitle.submenu = nil;
                    
                }];
            } else {
                [self.similarArtistMenuTtitle.submenu removeAllItems];
                [self.musicScrobbler.scrobbler getSimilarArtistsTo:self.musicScrobbler.currentTrack.artist successHandler:^(NSArray *result) {
                    [self prepareMenuWithArtists:result];
                } failureHandler:^(NSError *error) {
                    self.similarArtistMenuTtitle.submenu = nil;
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
        self.similarArtistMenuTtitle.title = [NSString stringWithFormat:NSLocalizedString(@"Show similar artists", nil)];
    }
}


-(void)prepareMenuWithArtists:(NSArray *)artists
{
    if (!self.similarArtistMenuTtitle.hasSubmenu) {
        NSMenu *submenu = [[NSMenu alloc] init];
        submenu.autoenablesItems = NO;
        self.similarArtistMenuTtitle.submenu = submenu;
    } else {
        [self.similarArtistMenuTtitle.submenu removeAllItems];
    }
    
    
    [artists enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *artist = [obj objectForKey:@"name"];
        [self.similarArtistMenuTtitle.submenu addItemWithTitle:artist action:NULL keyEquivalent:@""];
        [self.iTunesSearch getIdForArtist:artist successHandler:^(NSArray *result) {
            if (result.count) {
                [self.similarArtistMenuTtitle.submenu.itemArray enumerateObjectsUsingBlock:^(NSMenuItem * _Nonnull menuItem, NSUInteger idx, BOOL * _Nonnull stop) {
                    if ([menuItem.title.lowercaseString isEqualToString:((NSString *)result.firstObject[@"artistName"]).lowercaseString]) {
                        menuItem.enabled = YES;
                        menuItem.action = @selector(openiTunesLinkFromMenuItem:);
                        menuItem.target = self;
                    }
                }];
            } else {
                [self.similarArtistMenuTtitle.submenu.itemArray enumerateObjectsUsingBlock:^(NSMenuItem * _Nonnull menuItem, NSUInteger idx, BOOL * _Nonnull stop) {
                    if ([menuItem.title.lowercaseString isEqualToString:artist.lowercaseString]) {
                        menuItem.enabled = NO;
                    }
                }];
            }
        } failureHandler:^(NSError *error) {
            [self.similarArtistMenuTtitle.submenu.itemArray enumerateObjectsUsingBlock:^(NSMenuItem * _Nonnull menuItem, NSUInteger idx, BOOL * _Nonnull stop) {
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

-(void)openiTunesLinkFromMenuItem:(NSMenuItem *)menuItem
{
    [self openiTunesLinkForArtist:menuItem.title];
}

-(void)openiTunesLinkForArtist:(NSString *)artist
{
    [self.iTunesSearch getIdForArtist:artist successHandler:^(NSArray *result) {
        if (result.count) {
            NSString *link = [(NSString *)result.firstObject[@"artistLinkUrl"] stringByReplacingOccurrencesOfString:@"https://" withString:@"itmss://"];
            NSLog(@"%@", link);
            [[NSWorkspace sharedWorkspace] launchAppWithBundleIdentifier:@"com.apple.iTunes" options:NSWorkspaceLaunchDefault additionalEventParamDescriptor:nil launchIdentifier:NULL];
            [self.musicController.iTunes openLocation:link];

        }
    } failureHandler:^(NSError *error) {
        
    }];

}

-(void)udapteShowUserProfileMenuItem
{
    BOOL internetIsReachable = [FXReachability isReachable];
    
    if (self.settings.session && internetIsReachable) {
        self.profileMenuTitle.title = [NSString stringWithFormat:NSLocalizedString(@"%@'s profile...", nil), self.settings.username];
        self.profileMenuTitle.enabled = YES;
    } else if (self.settings.session && !internetIsReachable) {
        self.profileMenuTitle.title = [NSString stringWithFormat:NSLocalizedString(@"%@'s profile...", nil), self.settings.username];
        self.profileMenuTitle.enabled = NO;
    } else {
        self.profileMenuTitle.title = [NSString stringWithFormat:NSLocalizedString(@"Profile... (Log in)", nil)];
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
        menuItem.target = weakSelf;
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
        [self openAppleMusicPageForTrack:track andMenuItem:menuItem];
        [[NSWorkspace sharedWorkspace] launchAppWithBundleIdentifier:@"com.apple.iTunes" options:NSWorkspaceLaunchDefault additionalEventParamDescriptor:nil launchIdentifier:NULL];
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
            [self.musicController.iTunes openLocation:link];
            [[NSWorkspace sharedWorkspace] launchAppWithBundleIdentifier:@"com.apple.iTunes" options:NSWorkspaceLaunchDefault additionalEventParamDescriptor:nil launchIdentifier:NULL];

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
    [self.statusMenu removeItem:self.recentTracksMenuItem];
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
//        _iTunesSearch.countryCode = @"US";
    }
    return _iTunesSearch;
}

@end