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
#import "Song.h"
#import "RecentTracksController.h"
#import "SettingsController.h"

@interface MenuController ()

@property (strong, nonatomic) NSStatusItem *statusItem;
@property (strong, nonatomic) IBOutlet NSMenu *statusMenu;
@property (strong, nonatomic) MusicScrobbler *musicScrobbler;
@property (strong, nonatomic) IBOutlet NSMenu *recentTracksMenu;
@property (weak) IBOutlet NSMenuItem *recentTracksMenuItem;
@property (nonatomic) RecentTracksController *recentTracksController;


@end

@implementation MenuController


-(void)awakeFromNib
{
    self.musicScrobbler = [MusicScrobbler sharedScrobbler];
    //System status bar icon
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    NSImage *icon = [NSImage imageNamed:@"statusIcon"];
    [icon setTemplate:YES];
    self.statusItem.image = icon;
    self.statusItem.menu = self.statusMenu;
    [self prepareRecentItemsMenu];
    //first launch
    if (!self.musicScrobbler.scrobbler.session) {
        [self openPreferences:self];
    }
}



#pragma mark - Last.fm related


-(IBAction)loveSong:(id)sender {
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    [self.musicScrobbler loveCurrentTrackWithCompletionHandler:^{
        [notification setTitle:[NSString stringWithFormat:@"%@", self.musicScrobbler.currentTrack.artist]];
        [notification setInformativeText:[NSString stringWithFormat:@"%@ ❤️ at Last.fm", self.musicScrobbler.currentTrack.trackName]];
        [notification setDeliveryDate:[NSDate dateWithTimeInterval:0 sinceDate:[NSDate date]]];
        
        [[NSUserNotificationCenter defaultUserNotificationCenter] scheduleNotification:notification];
    }];
}

#pragma mark - Menu Bar Items

- (IBAction)showUserProfile:(id)sender {
    if (self.musicScrobbler.scrobbler.session) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.last.fm/user/%@", self.musicScrobbler.scrobbler.username]]];
    }
}



-(IBAction)showSimilarArtists:(id)sender {
    NSString *str = self.musicScrobbler.currentTrack.artist;
    NSString *url = [str stringByReplacingOccurrencesOfString:@" " withString:@"+"];
    NSData *decode = [url dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *ansi = [[NSString alloc] initWithData:decode encoding:NSASCIIStringEncoding];
    
    if (ansi.length > 0) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.last.fm/music/%@/+similar", ansi]]];
    }
}


-(IBAction)quit:(id)sender {
    [[NSApplication sharedApplication] terminate:self];
}

-(IBAction)openPreferences:(id)sender {
    [NSApp activateIgnoringOtherApps:YES];
    [[(AppDelegate *)[[NSApplication sharedApplication] delegate] window] makeKeyAndOrderFront:nil];
}

#pragma mark Update menu

-(void)changeState {
    [self updateRecentMenu];
    if (self.musicScrobbler.scrobbler.session) {
        [self.profileMenuTitle setEnabled:YES];
        self.profileMenuTitle.title = [NSString stringWithFormat:@"%@'s profile...", self.musicScrobbler.username];
        if ([self.musicScrobbler.iTunes isRunning]) {
            if (self.musicScrobbler.iTunes.playerState == iTunesEPlSPlaying && self.musicScrobbler.currentTrack.trackName) {
                [self.loveSongMenuTitle setEnabled:YES];
                [self.similarArtistMenuTtitle setEnabled:YES];
                self.similarArtistMenuTtitle.title = [NSString stringWithFormat:@"Similar artists to %@...", self.musicScrobbler.currentTrack.artist];
                self.loveSongMenuTitle.title = [NSString stringWithFormat:@"Love %@ on Last.fm", self.musicScrobbler.currentTrack.trackName];
            }
            else {
                [self.loveSongMenuTitle setEnabled:NO];
                [self.similarArtistMenuTtitle setEnabled:NO];
                self.similarArtistMenuTtitle.title = [NSString stringWithFormat:@"Similar artists..."];
                self.loveSongMenuTitle.title = [NSString stringWithFormat:@"Love song on Last.fm"];
            }
        }
        else {
            [self.loveSongMenuTitle setEnabled:NO];
            [self.similarArtistMenuTtitle setEnabled:NO];
            self.loveSongMenuTitle.title = [NSString stringWithFormat:@"Love song on Last.fm"];
            self.similarArtistMenuTtitle.title = [NSString stringWithFormat:@"Similar artists..."];
        }
    }
    else {
        [self.loveSongMenuTitle setEnabled:NO];
        [self.profileMenuTitle setEnabled:NO];
        self.profileMenuTitle.title = [NSString stringWithFormat:@"Profile... (Log in)"];
        if ([self.musicScrobbler.iTunes isRunning]) {
            if (self.musicScrobbler.currentTrack.trackName) {
                self.loveSongMenuTitle.title = [NSString stringWithFormat:@"Love on Last.fm (Log in)"];
                self.similarArtistMenuTtitle.title = [NSString stringWithFormat:@"Similar artists to %@...", self.musicScrobbler.currentTrack.artist];
                [self.similarArtistMenuTtitle setEnabled:YES];
            }
            else if (self.musicScrobbler.iTunes.currentTrack.name) {
                self.loveSongMenuTitle.title = [NSString stringWithFormat:@"Love on Last.fm (Log in)"];
                self.similarArtistMenuTtitle.title = [NSString stringWithFormat:@"Similar artists to %@...", self.musicScrobbler.iTunes.currentTrack.name];
                [self.similarArtistMenuTtitle setEnabled:YES];
            }
            else {
                self.loveSongMenuTitle.title = [NSString stringWithFormat:@"Love on Last.fm (Log in)"];
                self.similarArtistMenuTtitle.title = [NSString stringWithFormat:@"Similar artists..."];
                [self.similarArtistMenuTtitle setEnabled:NO];
            }
        }
        else {
            [self.similarArtistMenuTtitle setEnabled:NO];
            self.loveSongMenuTitle.title = [NSString stringWithFormat:@"Love song on Last.fm (Log in)"];
            self.similarArtistMenuTtitle.title = [NSString stringWithFormat:@"Similar artists..."];
        }
    }
}

#pragma mark - Recent Items

-(void)prepareRecentItemsMenu
{
    if (self.recentTracksController.songs.count == 0) {
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
    [self.recentTracksController.songs enumerateObjectsUsingBlock:^(Song *  _Nonnull song, NSUInteger idx, BOOL * _Nonnull stop) {
        if (idx == numberOfItemsFromSettings-1) {
            *stop =  YES;
        }
        NSLog(@"%@", song);
        NSMenuItem *menuItem = [weakSelf.recentTracksMenu addItemWithTitle:[NSString stringWithFormat:NSLocalizedString(@"%@ by %@", nil), song.trackName, song.artist] action:@selector(openWebsite:) keyEquivalent:@""];
        menuItem.target = weakSelf;
    }];
}


-(void)updateRecentMenu
{
    Song *song = self.musicScrobbler.currentTrack;
    if ([self.recentTracksController addSongToRecentMenu:song]) {
        if (self.recentTracksMenu.numberOfItems < [SettingsController sharedSettings].numberOfTracksInRecent.intValue) {
            NSMenuItem *menuItem = [self.recentTracksMenu insertItemWithTitle:[NSString stringWithFormat:NSLocalizedString(@"%@ by %@", nil), song.trackName, song.artist] action:@selector(openWebsite:) keyEquivalent:@"" atIndex:0];
            menuItem.target = self;
        } else {
            [self.recentTracksMenu removeItemAtIndex:self.recentTracksMenu.numberOfItems-1];
            NSMenuItem *menuItem = [self.recentTracksMenu insertItemWithTitle:[NSString stringWithFormat:NSLocalizedString(@"%@ by %@", nil), song.trackName, song.artist] action:@selector(openWebsite:) keyEquivalent:@"" atIndex:0];
            menuItem.target = self;
        }
    }
}

-(void)openWebsite:(NSMenuItem *)menuItem
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[self validateLinkFromMenuItem:menuItem]]];
}

-(NSString *)validateLinkFromMenuItem:(NSMenuItem *)menuItem
{
    __block Song *songFromMenu;
    NSMenu *menu = [menuItem menu];
    NSInteger itemIndex = [menu indexOfItem:menuItem];
    [self.recentTracksController.songs enumerateObjectsUsingBlock:^(Song *  _Nonnull song, NSUInteger idx, BOOL * _Nonnull stop) {
        if (idx == itemIndex) {
            songFromMenu = song;
            *stop = YES;
        }
    }];
    NSString *artist = songFromMenu.artist;
    NSString *urlArtist = [artist stringByReplacingOccurrencesOfString:@" " withString:@"+"];
    NSData *decodeArtist = [urlArtist dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *ansiArtist = [[NSString alloc] initWithData:decodeArtist encoding:NSASCIIStringEncoding];
    
    NSString *track = songFromMenu.trackName;
    NSString *urlTrack = [track stringByReplacingOccurrencesOfString:@" " withString:@"+"];
    NSData *decodeTrack = [urlTrack dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *ansiTrack = [[NSString alloc] initWithData:decodeTrack encoding:NSASCIIStringEncoding];
    
    NSString *link = [NSString stringWithFormat:@"http://www.last.fm/music/%@/_/%@", ansiArtist, ansiTrack];
    if (link.length > 0) {
        return link;
    }
    return nil;
}

#pragma mark - NSMenuValidation

-(BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    if ([self validateLinkFromMenuItem:menuItem]) {
        return YES;
    }
    return NO;
}

-(RecentTracksController *)recentTracksController
{
    if (!_recentTracksController) {
        _recentTracksController = [RecentTracksController sharedInstance];
    }
    return _recentTracksController;
}


@end
