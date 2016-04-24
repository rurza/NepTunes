//
//  MusicPlayer.m
//  NepTunes
//
//  Created by Adam Różyński on 18/04/16.
//  Copyright © 2016 micropixels. All rights reserved.
//

#import "MusicPlayer.h"
#import <ScriptingBridge/ScriptingBridge.h>
#import "iTunes.h"
#import "Spotify.h"
#import "Track.h"
#import "MusicController.h"

NSString * const kiTunesBundleIdentifier = @"com.apple.iTunes";
NSString * const kSpotifyBundlerIdentifier = @"com.spotify.client";

@interface MusicPlayer ()

@property (atomic, readwrite) MusicPlayerApplication currentPlayer;
@property (nonatomic, readwrite) Track *currentTrack;
@property (nonatomic, readwrite) MusicPlayerState playerState;

@property (nonatomic) NSTimer * _noDurationTimer;
@property (nonatomic, readonly) SpotifyTrack *_currentSpotifyTrack;
@property (nonatomic, readonly) iTunesTrack *_currentiTunesTrack;

@property (nonatomic) iTunesApplication *_iTunesApp;
@property (nonatomic) SpotifyApplication *_spotifyApp;
@property (nonatomic, readonly) BOOL isiTunesRunning;
@property (nonatomic, readonly) BOOL isSpotifyRunning;
@end

@implementation MusicPlayer
@synthesize currentPlayer = _currentPlayer;

+ (id) allocWithZone:(NSZone*)z { return [self sharedPlayer];              }
+ (id) alloc                    { return [self sharedPlayer];              }
+ (id)_alloc                    { return [super allocWithZone:NULL]; }
- (id)_init                     { return [super init];               }


-(instancetype)init
{
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                        selector:@selector(notificationFromiTunes:)
                                                            name:@"com.apple.iTunes.playerInfo"
                                                          object:nil];
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                        selector:@selector(notificationFromSpotify:)
                                                            name:@"com.spotify.client.PlaybackStateChanged"
                                                          object:nil];
    NSNotificationCenter *center = [[NSWorkspace sharedWorkspace] notificationCenter];
    
    // Install the notifications.
    
    [center addObserver:self
               selector:@selector(appLaunched:)
                   name:NSWorkspaceDidLaunchApplicationNotification
                 object:nil
     ];
    [center addObserver:self
               selector:@selector(appTerminated:)
                   name:NSWorkspaceDidTerminateApplicationNotification
                 object:nil
     ];
    
    self.delegate = [MusicController sharedController];
    return self;
}

-(void)awakeFromNib
{
    NSArray *runningApps = [NSWorkspace sharedWorkspace].runningApplications;
    for (NSRunningApplication *app in runningApps) {
        if ([app.bundleIdentifier isEqualToString:kiTunesBundleIdentifier]) {
            if ([self.delegate respondsToSelector:@selector(iTunesIsAvailable)]) {
                [self.delegate iTunesIsAvailable];
            }
        } else if ([app.bundleIdentifier isEqualToString:kSpotifyBundlerIdentifier]) {
            if ([self.delegate respondsToSelector:@selector(spotifyIsAvailable)]) {
                [self.delegate spotifyIsAvailable];
            }
        }
    }
    [self detectCurrentPlayer];
}

+(instancetype)sharedPlayer
{
    static MusicPlayer *musicPlayer = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        musicPlayer = [[self _alloc] _init];
    });
    return musicPlayer;
}


#pragma mark - iTunes

-(void)notificationFromiTunes:(NSNotification *)notification
{
    self.currentPlayer = MusicPlayeriTunes;
    if (self.currentPlayer == MusicPlayeriTunes) {
        [self invalidateNoDurationTimerIfNeeded];
        NSDictionary *userInfoFromNotification = notification.userInfo;
//        NSDictionary *trackInfo = @{ @"Artist"              : userInfoFromNotification[@"Artist"],
//                                     @"Album Artist"        : userInfoFromNotification[@"Album Artist"],
//                                     @"Artist"              : userInfoFromNotification[@"Artist"],
//                                     @"TrackName"           : userInfoFromNotification[@"Name"],
//                                     @"Player State"        : userInfoFromNotification[@"Player State"],
//                                     @"Store URL"           : userInfoFromNotification[@"Store URL"],
//                                     @"Duration"            : userInfoFromNotification[@"Total Time"],
//                                     @"Player"              : @"iTunes"
//                                     };
        [self setCurrentTrackFromiTunesOrUserInfo:userInfoFromNotification];
        [self.delegate trackChanged];
    }
}

-(void)setCurrentTrackFromiTunesOrUserInfo:(NSDictionary *)userInfo
{
    if (self._currentiTunesTrack.name.length && self._currentiTunesTrack.duration) {
        self.currentTrack = [Track trackWithiTunesTrack:self._iTunesApp.currentTrack];
    } else {
        if (self.isiTunesRunning) {
            self.currentTrack = [[Track alloc] initWithTrackName:userInfo[@"Name"] artist:userInfo[@"Artist"] album:userInfo[@"Album"] andDuration:[userInfo[@"Total Time"] doubleValue] / 1000];
            if ([userInfo[@"Total Time"] isEqualToNumber:@(0)]) {
                self._noDurationTimer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(updateTrackDuration:) userInfo:nil repeats:NO];
            }
            self.currentTrack.trackOrigin = TrackFromiTunes;
        }
    }
}

-(void)updateTrackDuration:(NSTimer *)timer
{
    if (self.isiTunesRunning) {
        self.currentTrack.duration = self._currentiTunesTrack.duration;
    }
}

-(void)invalidateNoDurationTimerIfNeeded
{
    if (self._noDurationTimer) {
        [self._noDurationTimer invalidate];
        self._noDurationTimer = nil;
    }
}

-(void)loveCurrentTrack
{
    self._iTunesApp.currentTrack.loved = YES;
}

-(NSImage *)currentiTunesTrackCover
{
    iTunesTrack *track = self._currentiTunesTrack;
    for (iTunesArtwork *artwork in track.artworks) {
        if ([artwork.data isKindOfClass:[NSImage class]]) {
            return artwork.data;
        } else if ([artwork.rawData isKindOfClass:[NSData class]]) {
            return [[NSImage alloc] initWithData:artwork.rawData];
        }
    }
    return nil;
}

#pragma mark iTunes playback
-(void)fastForward
{
    if (self.currentPlayer == MusicPlayeriTunes) {
        [self._iTunesApp fastForward];
    }
}
-(void)rewind
{
    if (self.currentPlayer == MusicPlayeriTunes) {
        [self._iTunesApp rewind];
    }
}
-(void)resume
{
    if (self.currentPlayer == MusicPlayeriTunes) {
        [self._iTunesApp resume];
    }
}


#pragma mark - Spotify

-(void)notificationFromSpotify:(NSNotification *)notification
{
    self.currentPlayer = MusicPlayerSpotify;
    if (self.currentPlayer == MusicPlayerSpotify) {
        [self setCurrentTrackFromSpotify];
        [self.delegate trackChanged];
    }
}

-(void)setCurrentTrackFromSpotify
{
    self.currentTrack = [Track trackWithSpotifyTrack:self._spotifyApp.currentTrack];
}

-(NSImage *)currentSpotifyTrackCover
{
#warning currentSpotifyTrackCover do zrobienia
    return nil;
}

#pragma mark - Common
-(void)detectCurrentPlayer
{
    if (self.isSpotifyRunning && self._spotifyApp.playerState == SpotifyEPlSPlaying) {
        self.currentPlayer = MusicPlayerSpotify;
        [self setCurrentTrackFromSpotify];
        [self.delegate trackChanged];
    } else if (self.isiTunesRunning && self._iTunesApp.playerState == iTunesEPlSPlaying) {
        self.currentPlayer = MusicPlayeriTunes;
        [self setCurrentTrackFromiTunesOrUserInfo:nil];
        [self.delegate trackChanged];
    }
}

-(void)openArtistPageForTrack:(Track *)track
{
#warning do zrobienia strona artysty w playerze
}

-(void)bringPlayerToFront
{
#warning do zrobienia bringPlayerToFront
}

-(NSImage *)currentTrackCover
{
    if (self.currentPlayer == MusicPlayeriTunes) {
        return [self currentiTunesTrackCover];
    } else if (self.currentPlayer == MusicPlayerSpotify) {
        return [self currentSpotifyTrackCover];
    } else return nil;
}

#pragma mark Soundvolume
-(void)setSoundVolume:(NSInteger)soundVolume
{
    if (self.currentPlayer == MusicPlayerSpotify) {
        self._spotifyApp.soundVolume = soundVolume;
    } else if (self.currentPlayer == MusicPlayeriTunes) {
        self._iTunesApp.soundVolume = soundVolume;
    }
}

-(NSInteger)soundVolume
{
    if (self.currentPlayer == MusicPlayerSpotify) {
        return self._spotifyApp.soundVolume;
    } else if (self.currentPlayer == MusicPlayeriTunes) {
        return self._iTunesApp.soundVolume;
    }
    return 0;
}

#pragma mark Playback
-(void)playPause
{
    if (self.currentPlayer == MusicPlayeriTunes && self.isiTunesRunning && self.playerState != MusicPlayerStateUndefined) {
        [self._iTunesApp playpause];
    } else if (self.currentPlayer == MusicPlayerSpotify && self.isSpotifyRunning && self.playerState != MusicPlayerStateUndefined) {
        [self._spotifyApp playpause];
    }
}

-(void)nextTrack
{
    if (self.currentPlayer == MusicPlayeriTunes && self.isiTunesRunning && self.playerState != MusicPlayerStateUndefined) {
        [self._iTunesApp nextTrack];
    } else if (self.currentPlayer == MusicPlayerSpotify && self.isSpotifyRunning && self.playerState != MusicPlayerStateUndefined) {
        [self._spotifyApp nextTrack];
    }
}
-(void)backTrack
{
    if (self.currentPlayer == MusicPlayeriTunes && self.isiTunesRunning && self.playerState != MusicPlayerStateUndefined) {
        [self._iTunesApp backTrack];
    } else if (self.currentPlayer == MusicPlayerSpotify && self.isSpotifyRunning && self.playerState != MusicPlayerStateUndefined) {
        [self._spotifyApp previousTrack];
    }
}

-(void)appLaunched:(NSNotification *)note
{
    if ([[note.userInfo objectForKey:@"NSApplicationBundleIdentifier"] isEqualToString:kSpotifyBundlerIdentifier]) {
        if ([self.delegate respondsToSelector:@selector(spotifyIsAvailable)]) {
            [self.delegate spotifyIsAvailable];
        }
    } else if ([[note.userInfo objectForKey:@"NSApplicationBundleIdentifier"] isEqualToString:kiTunesBundleIdentifier]) {
        if ([self.delegate respondsToSelector:@selector(iTunesIsAvailable)]) {
            [self.delegate iTunesIsAvailable];
        }
    }
}

-(void)appTerminated:(NSNotification *)note
{
    if ([[note.userInfo objectForKey:@"NSApplicationBundleIdentifier"] isEqualToString:kSpotifyBundlerIdentifier]) {
        if ([self.delegate respondsToSelector:@selector(spotifyWasTerminated)]) {
            [self.delegate spotifyWasTerminated];
        }
    } else if ([[note.userInfo objectForKey:@"NSApplicationBundleIdentifier"] isEqualToString:kiTunesBundleIdentifier]) {
        if ([self.delegate respondsToSelector:@selector(iTunesWasTerminated)]) {
            [self.delegate iTunesWasTerminated];
        }
    }
}

-(void)setCurrentPlayer:(MusicPlayerApplication)currentPlayer
{
    @synchronized (self) {
        if (_currentPlayer == MusicPlayerUndefined) {
            _currentPlayer = currentPlayer;
            [self.delegate newActivePlayer];
            return;
        }
        if (_currentPlayer == MusicPlayerSpotify && currentPlayer == MusicPlayeriTunes && !self.isSpotifyRunning) {
            _currentPlayer = currentPlayer;
            [self.delegate newActivePlayer];
            return;
        }
        if (_currentPlayer == MusicPlayeriTunes && currentPlayer == MusicPlayerSpotify && !self.isiTunesRunning) {
            _currentPlayer = currentPlayer;
            [self.delegate newActivePlayer];

            return;
        }
    }
}

#pragma mark - GETTERS

-(MusicPlayerApplication)currentPlayer
{
    if (_currentPlayer == MusicPlayerUndefined) {
        [self detectCurrentPlayer];
    }
    return _currentPlayer;
}

-(MusicPlayerState)playerState
{
    if (self.currentPlayer == MusicPlayeriTunes) {
        switch (self._iTunesApp.playerState) {
            case iTunesEPlSPlaying:
                return MusicPlayerStatePlaying;
                break;
            case iTunesEPlSStopped:
                return MusicPlayerStateStopped;
                break;
            case iTunesEPlSPaused:
                return MusicPlayerStatePaused;
                break;
            default:
                return MusicPlayerStateUndefined;
                break;
        }
    } else if (self.currentPlayer == MusicPlayerSpotify) {
        switch (self._spotifyApp.playerState) {
            case SpotifyEPlSPlaying:
                return MusicPlayerStatePlaying;
                break;
            case SpotifyEPlSPaused:
                return MusicPlayerStatePaused;
                break;
            case SpotifyEPlSStopped:
                return MusicPlayerStateStopped;
                break;
            default:
                return MusicPlayerStateUndefined;
                break;
        }
    }
    else return MusicPlayerStateUndefined;
}

-(BOOL)isPlayerRunning
{
    if (self.currentPlayer == MusicPlayeriTunes) {
        return self.isiTunesRunning;
    } else if (self.currentPlayer == MusicPlayerSpotify) {
        return self.isSpotifyRunning;
    } else return NO;
}

-(BOOL)isiTunesRunning
{
    if (self._iTunesApp.isRunning) {
        return YES;
    }
    return NO;
}

-(BOOL)isSpotifyRunning
{
    if (self._spotifyApp.isRunning) {
        return YES;
    }
    return NO;
}

-(SpotifyTrack *)_currentSpotifyTrack
{
    if (self.currentPlayer == MusicPlayerSpotify && self.isSpotifyRunning) {
        return self._spotifyApp.currentTrack;
    }
    return nil;
}

-(iTunesTrack *)_currentiTunesTrack
{
    if (self.currentPlayer == MusicPlayeriTunes && self.isiTunesRunning) {
        return self._iTunesApp.currentTrack;
    }
    return nil;

}

-(SpotifyApplication *)_spotifyApp
{
    if (!__spotifyApp) {
        __spotifyApp = (SpotifyApplication *)[SBApplication applicationWithBundleIdentifier:kSpotifyBundlerIdentifier];
    }
    return __spotifyApp;
}

-(iTunesApplication *)_iTunesApp
{
    if (!__iTunesApp) {
        __iTunesApp = (iTunesApplication *)[SBApplication applicationWithBundleIdentifier:kiTunesBundleIdentifier];
    }
    return __iTunesApp;
}
@end