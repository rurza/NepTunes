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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeState) name:FXReachabilityStatusDidChangeNotification object:nil];
    
    if ([SettingsController sharedSettings].numberOfTracksInRecent.integerValue != 0) {
        [self showRecentMenu];
    } else {
        [self hideRecentMenu];
    }
    self.statusMenu.autoenablesItems = NO;
    [self.loveSongMenuTitle setEnabled:NO];

    [self changeState];
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
-(void)changeState {
    [self updateRecentMenu];
    BOOL reachable = [FXReachability isReachable];

    if ([SettingsController sharedSettings].session) {
        if (reachable) {
            [self.profileMenuTitle setEnabled:YES];
        } else {
            [self.profileMenuTitle setEnabled:NO];
        }
        self.profileMenuTitle.title = [NSString stringWithFormat:@"%@'s profile...", [SettingsController sharedSettings].username];
        if (self.musicController.isiTunesRunning) {
            if (self.musicController.playerState == iTunesEPlSPlaying && self.musicScrobbler.currentTrack.trackName) {
                if (reachable) {
                    [self.loveSongMenuTitle setEnabled:YES];
                    [self.similarArtistMenuTtitle setEnabled:YES];
                } else {
                    [self.loveSongMenuTitle setEnabled:NO];
                    [self.similarArtistMenuTtitle setEnabled:NO];
                }

                self.similarArtistMenuTtitle.title = [NSString stringWithFormat:@"Similar artists to %@...", self.musicScrobbler.currentTrack.artist];
                self.loveSongMenuTitle.title = [NSString stringWithFormat:@"Love %@ on Last.fm", self.musicScrobbler.currentTrack.trackName];
            }
            else {
                [self.loveSongMenuTitle setEnabled:NO];
                [self.similarArtistMenuTtitle setEnabled:NO];
                self.similarArtistMenuTtitle.title = [NSString stringWithFormat:@"Similar artists..."];
                self.loveSongMenuTitle.title = [NSString stringWithFormat:@"Love track on Last.fm"];
            }
        }
        else {
            [self.loveSongMenuTitle setEnabled:NO];
            [self.similarArtistMenuTtitle setEnabled:NO];
            self.loveSongMenuTitle.title = [NSString stringWithFormat:@"Love track on Last.fm"];
            self.similarArtistMenuTtitle.title = [NSString stringWithFormat:@"Similar artists..."];
        }
    }
    else {
        [self.profileMenuTitle setEnabled:NO];
        [self.loveSongMenuTitle setEnabled:NO];
        self.profileMenuTitle.title = [NSString stringWithFormat:@"Profile... (Log in)"];
        if (self.musicController.isiTunesRunning) {
            if (self.musicScrobbler.currentTrack.trackName) {
                self.loveSongMenuTitle.title = [NSString stringWithFormat:@"Love %@ on Last.fm... (Log in)", self.musicScrobbler.currentTrack.trackName];
                self.similarArtistMenuTtitle.title = [NSString stringWithFormat:@"Similar artists to %@...", self.musicScrobbler.currentTrack.artist];
                if (reachable) {
                    [self.similarArtistMenuTtitle setEnabled:YES];
                } else {
                    [self.similarArtistMenuTtitle setEnabled:NO];
                }

            }
            else {
                self.loveSongMenuTitle.title = [NSString stringWithFormat:@"Love track on Last.fm... (Log in)"];
                self.similarArtistMenuTtitle.title = [NSString stringWithFormat:@"Similar artists..."];
                [self.similarArtistMenuTtitle setEnabled:NO];
            }
        }
        else {
            [self.similarArtistMenuTtitle setEnabled:NO];
            self.loveSongMenuTitle.title = [NSString stringWithFormat:@"Love track on Last.fm... (Log in)"];
            self.similarArtistMenuTtitle.title = [NSString stringWithFormat:@"Similar artists..."];
        }
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
            menuItem.target = self;
        } else {
            [self.recentTracksMenu removeItemAtIndex:self.recentTracksMenu.numberOfItems-1];
            NSMenuItem *menuItem = [self.recentTracksMenu insertItemWithTitle:[NSString stringWithFormat:NSLocalizedString(@"%@ – %@", nil),track.artist, track.trackName] action:@selector(openWebsite:) keyEquivalent:@"" atIndex:0];
            menuItem.target = self;
        }
    }
}

-(void)openWebsite:(NSMenuItem *)menuItem
{
    if (self.settings.integrationWithiTunes && self.settings.showRecentTrackIniTunes) {
        [self.musicController.iTunes openLocation:[self validateLinkFromMenuItem:menuItem]];
        [[NSWorkspace sharedWorkspace] launchAppWithBundleIdentifier:@"com.apple.iTunes" options:NSWorkspaceLaunchDefault additionalEventParamDescriptor:nil launchIdentifier:NULL];
    } else {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[self validateLinkFromMenuItem:menuItem]]];
    }
}

-(NSString *)validateLinkFromMenuItem:(NSMenuItem *)menuItem
{
    __block Track *songFromMenu;
    NSMenu *menu = [menuItem menu];
    NSInteger itemIndex = [menu indexOfItem:menuItem];
    [self.recentTracksController.tracks enumerateObjectsUsingBlock:^(Track *  _Nonnull song, NSUInteger idx, BOOL * _Nonnull stop) {
        if (idx == itemIndex) {
            songFromMenu = song;
            *stop = YES;
        }
    }];
    if (self.settings.integrationWithiTunes && self.settings.showRecentTrackIniTunes) {
        if (songFromMenu.storeURL) {
            return songFromMenu.storeURL;
        } else return nil;
    } else {
        NSString *artist = songFromMenu.artist;
        artist = [artist stringByReplacingOccurrencesOfString:@"/" withString:@"%2F"];
        NSString *artistUTF8 = [artist stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        
        NSString *track = songFromMenu.trackName;
        track = [track stringByReplacingOccurrencesOfString:@"/" withString:@"%2F"];
        NSString *trackUTF8 = [track stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        
        if (!trackUTF8 || !artistUTF8) {
            return nil;
        }
        NSString *link = [NSString stringWithFormat:@"http://www.last.fm/music/%@/_/%@", artistUTF8, trackUTF8];
        NSURL *url = [NSURL URLWithString:link];
        if (url) {
            return url.absoluteString;
        }
        return nil;
    }
}

#pragma mark - NSMenuValidation

-(BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    if (menuItem.action == @selector(showUserProfile:)) {
        if ([SettingsController sharedSettings].session) {
            return YES;
        } else {
            return NO;
        }
    }
    if ([self validateLinkFromMenuItem:menuItem]) {
        return YES;
    }
    return NO;
}

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

@end