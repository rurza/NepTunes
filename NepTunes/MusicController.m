//
//  MusicController.m
//  NepTunes
//
//  Created by rurza on 02/02/16.
//  Copyright © 2016 micropixels. All rights reserved.
//

#import "MusicController.h"
#import "MusicScrobbler.h"
#import "SettingsController.h"
#import "MenuController.h"
#import "Track.h"
#import "CoverWindowController.h"
#import "UserNotificationsController.h"
#import "CoverSettingsController.h"
#import "HUDWindowController.h"
#import "SocialMessage.h"
#import "MusicPlayer.h"
@import Social;
@import Accounts;

#define FOUR_MINUTES 60 * 4
#define DELAY_FOR_RADIO 4

NSString *const kTrackInfoUpdated = @"trackInfoUpdated";

@interface MusicController ()
@property (nonatomic) MusicScrobbler *musicScrobbler;
@property (nonatomic) SettingsController *settingsController;
@property (nonatomic) MenuController *menuController;
@property (nonatomic) NSTimer* scrobbleTimer;
@property (nonatomic) NSTimer* nowPlayingTimer;
@property (nonatomic) NSTimer* mainTimer;
@property (nonatomic) HUDWindowController *hud;
@end

@implementation MusicController

#pragma mark - Responding to notifications

+ (instancetype)sharedController
{
    __strong static id _sharedInstance = nil;
    static dispatch_once_t onlyOnce;
    dispatch_once(&onlyOnce, ^{
        _sharedInstance = [[self _alloc] _init];
    });
    return _sharedInstance;
}

+ (id) allocWithZone:(NSZone*)z { return [self sharedController];                                   }
+ (id) alloc                    { return [self sharedController];                                   }
- (id) init                     { return self;                                                      }
+ (id)_alloc                    { return [super allocWithZone:NULL];                                }
- (id)_init                     { return [super init];}

#pragma mark Music Player Delegate
-(void)trackChanged
{
    if (self.settingsController.debugMode) {
        NSLog(@"Notification sent from Music Player");
    }
    [self invalidateTimers];
    self.mainTimer = [NSTimer scheduledTimerWithTimeInterval:DELAY_FOR_RADIO target:self selector:@selector(prepareTrack:) userInfo:nil repeats:NO];
    [self setScrobblerCurrentTrack];
    [self updateCover];
    [self updateMenu];
    [[NSNotificationCenter defaultCenter] postNotificationName:kTrackInfoUpdated object:nil userInfo:nil];
}

-(void)spotifyIsAvailable
{
    [self.menuController insertNewSourceWithName:@"Spotify"];
}

-(void)iTunesIsAvailable
{
    [self.menuController insertNewSourceWithName:@"iTunes"];
}

-(void)spotifyWasTerminated
{
    [self.menuController removeSourceWithName:@"Spotify"];
}

-(void)iTunesWasTerminated
{
    [self.menuController removeSourceWithName:@"iTunes"];
}

-(void)newActivePlayer
{
    if (self.musicPlayer.currentPlayer == MusicPlayeriTunes) {
        [self.menuController addCheckmarkToSourceWithName:@"iTunes"];
    } else if (self.musicPlayer.currentPlayer == MusicPlayerSpotify) {
        [self.menuController addCheckmarkToSourceWithName:@"Spotify"];
    }
}

-(void)prepareTrack:(NSTimer *)timer
{
    if (self.settingsController.debugMode) {
        NSLog(@"prepareTrack called");
    }
   
    if ([timer isValid]) {
        [self updateMenu];
        if (self.musicScrobbler.currentTrack.trackOrigin == TrackFromSpotify && !self.settingsController.scrobbleFromSpotify) {
            return;
        }
        if (self.musicPlayer.isPlayerRunning) {
            if (self.settingsController.debugMode) {
                NSLog(@"Any player is running is running");
            }

            if (self.musicPlayer.playerState == MusicPlayerStatePlaying && !self.musicScrobbler.currentTrack.itIsNotMusic && self.musicScrobbler.currentTrack) {
                NSTimeInterval trackLength;
                
                
                if (self.musicPlayer.currentTrack.artist && self.musicPlayer.currentTrack.artist.length) {
                    trackLength = (NSTimeInterval)self.musicScrobbler.currentTrack.duration;
                }
                else {
                    trackLength = (NSTimeInterval)self.musicScrobbler.currentTrack.duration;
                }
                
                NSTimeInterval scrobbleTime = ((trackLength * (self.settingsController.percentForScrobbleTime.floatValue / 100)) < FOUR_MINUTES) ? (trackLength * (self.settingsController.percentForScrobbleTime.floatValue / 100)) : FOUR_MINUTES;
                
                if ((self.settingsController.percentForScrobbleTime.floatValue / 100) > 0.95) {
                    scrobbleTime -= 2;
                }
                if (self.settingsController.debugMode) {
                    NSLog(@"Scrobble time for track %@ is %f", self.musicScrobbler.currentTrack, scrobbleTime); 
                }
                
                scrobbleTime -=DELAY_FOR_RADIO;
                
                if (scrobbleTime == 0) {
                    scrobbleTime = 16.0f;
                }
                
                if (trackLength >= 31.0f) {
                    self.nowPlayingTimer = [NSTimer scheduledTimerWithTimeInterval:5
                                                                            target:self
                                                                          selector:@selector(nowPlaying)
                                                                          userInfo:nil
                                                                           repeats:NO];
                }
                if (trackLength >= 31.0f) {
                    NSDictionary *userInfo = [timer.userInfo copy];
                    self.scrobbleTimer = [NSTimer scheduledTimerWithTimeInterval:scrobbleTime
                                                                          target:self
                                                                        selector:@selector(scrobble:)
                                                                        userInfo:userInfo
                                                                         repeats:NO];
                }
            }
        }
    }
}

-(void)updateCover
{
    if (self.musicScrobbler.currentTrack && self.musicPlayer.isPlayerRunning) {
        if (!self.coverWindowController) {
            [self setupCover];
        }
        [self.coverWindowController updateCoverWithTrack:self.musicScrobbler.currentTrack];
    } else {
        [self.coverWindowController updateCoverWithTrack:self.musicScrobbler.currentTrack];
        [self.coverWindowController.window close];

        self.coverWindowController = nil;
    }
}

-(void)setupCover
{
    CoverSettingsController *coverSettingsController = [[CoverSettingsController alloc] init];
    if (coverSettingsController.showCover) {
        self.coverWindowController = [[CoverWindowController alloc] initWithWindowNibName:@"CoverWindow"];
        if (self.musicPlayer.playerState == MusicPlayerStatePlaying && self.musicScrobbler.currentTrack) {
            [self.coverWindowController showWindow:self];
            [self.coverWindowController updateCoverWithTrack:self.musicScrobbler.currentTrack];
            [self.coverWindowController.window makeKeyAndOrderFront:nil];
            HUDWindowController *window =[[HUDWindowController alloc] initWithWindowNibName:@"HUDWindowController"];
            [window.window makeKeyAndOrderFront:nil];
            
        }
    }
}

-(void)invalidateTimers
{
    if (self.mainTimer) {
        [self.mainTimer invalidate];
        self.mainTimer = nil;
    }
    if (self.scrobbleTimer) {
        [self.scrobbleTimer invalidate];
        self.scrobbleTimer = nil;
    }
    if (self.nowPlayingTimer) {
        [self.nowPlayingTimer invalidate];
        self.nowPlayingTimer = nil;
    }
    if (self.settingsController.debugMode) {
        NSLog(@"Timers invalidated");
    }
}

-(void)setScrobblerCurrentTrack
{
    self.musicScrobbler.currentTrack = self.musicPlayer.currentTrack;
}

-(void)loveTrackOniTunes
{
    [self.musicPlayer loveCurrentTrackOniTunes];
}

-(void)updateMenu
{
    [self.menuController updateMenu];
}

-(void)scrobble:(NSTimer *)timer
{
    [self.musicScrobbler scrobbleCurrentTrack];
}

-(void)nowPlaying
{
    [self.musicScrobbler nowPlayingCurrentTrack];
}

-(void)loveTrackWithCompletionHandler:(void(^)(void))handler
{
    SettingsController *settings = [SettingsController sharedSettings];
    if (settings.session) {
        [self.musicScrobbler loveCurrentTrackWithCompletionHandler:^(Track *track, NSImage *artwork) {
            [[UserNotificationsController sharedNotificationsController] displayNotificationThatTrackWasLoved:track withArtwork:(NSImage *)artwork];
            if (handler) {
                handler();
            }
        }];
    }
    if (settings.integrationWithMusicPlayer && settings.loveTrackOniTunes) {
        [self loveTrackOniTunes];
        if (handler && !settings.session) {
            handler();
        }
    }
}



#pragma mark - Getters
-(MusicScrobbler *)musicScrobbler
{
    if (!_musicScrobbler) {
        _musicScrobbler = [MusicScrobbler sharedScrobbler];
    }
    return _musicScrobbler;
}


-(SettingsController *)settingsController
{
    if (!_settingsController) {
        _settingsController = [SettingsController sharedSettings];
    }
    return _settingsController;
}

-(MenuController *)menuController
{
    if (!_menuController) {
        _menuController = [MenuController sharedController];
    }
    return _menuController;
}

-(MusicPlayer *)musicPlayer
{
    if (!_musicPlayer) {
        _musicPlayer = [MusicPlayer sharedPlayer];
    }
    return _musicPlayer;
}


@end