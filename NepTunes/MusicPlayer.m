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

NSString *const kMusicPlayerNotification = @"NepTunes.playerInfo";

@interface MusicPlayer ()

@property (atomic, readwrite) MusicPlayerApplication currentPlayer;
@property (nonatomic, readwrite) Track *currentTrack;
@property (nonatomic, readwrite) MusicPlayerState playerState;

@property (nonatomic) NSTimer * _noDurationTimer;
@property (nonatomic, readwrite) SpotifyTrack *_currentSpotifyTrack;
@property (nonatomic, readwrite) iTunesTrack *_currentiTunesTrack;

@property (nonatomic) iTunesApplication *_iTunesApp;
@property (nonatomic) SpotifyApplication *_spotifyApp;
@property (nonatomic, readonly) BOOL isiTunesRunning;
@property (nonatomic, readonly) BOOL isSpotifyRunning;
@end

@implementation MusicPlayer
@synthesize currentPlayer = _currentPlayer;
+(instancetype)sharedPlayer
{
    static MusicPlayer *musicPlayer = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        musicPlayer = [[MusicPlayer alloc] init];
    });
    return musicPlayer;
}

-(instancetype)init
{
    if (self = [super init]) {
        [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                            selector:@selector(notificationFromiTunes:)
                                                                name:@"com.apple.iTunes.playerInfo"
                                                              object:nil];
        [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                            selector:@selector(notificationFromSpotify:)
                                                                name:@"com.spotify.client.PlaybackStateChanged"
                                                              object:nil];

    }
    return self;
}

#pragma mark - iTunes

-(void)notificationFromiTunes:(NSNotification *)notification
{
    self.currentPlayer = MusicPlayeriTunes;
    if (self.currentPlayer == MusicPlayeriTunes) {
        [self invalidateNoDurationTimerIfNeeded];
        NSDictionary *userInfoFromNotification = notification.userInfo;
        NSDictionary *trackInfo = @{ @"Artist"              : userInfoFromNotification[@"Artist"],
                                     @"Album Artist"        : userInfoFromNotification[@"Album Artist"],
                                     @"Artist"              : userInfoFromNotification[@"Artist"],
                                     @"TrackName"           : userInfoFromNotification[@"Name"],
                                     @"Player State"        : userInfoFromNotification[@"Player State"],
                                     @"Store URL"           : userInfoFromNotification[@"Store URL"],
                                     @"Duration"            : userInfoFromNotification[@"Total Time"],
                                     @"Player"              : @"iTunes"
                                     };
        self.currentPlayer = MusicPlayeriTunes;
        [self setCurrentTrackFromiTunesOrUserInfo:userInfoFromNotification];
        [self postNotificationWithTrackInfo:trackInfo];
    }
}

-(void)setCurrentTrackFromiTunesOrUserInfo:(NSDictionary *)userInfo
{
    self._iTunesApp = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
    if (self._iTunesApp.currentTrack.name.length && self._iTunesApp.currentTrack.duration) {
        self.currentTrack = [Track trackWithiTunesTrack:self._iTunesApp.currentTrack];
        self._currentiTunesTrack = self._iTunesApp.currentTrack;
        self._currentSpotifyTrack = nil;
    } else {
        self._currentSpotifyTrack = nil;
        self.currentTrack = [[Track alloc] initWithTrackName:userInfo[@"Name"] artist:userInfo[@"Artist"] album:userInfo[@"Album"] andDuration:[userInfo[@"Total Time"] doubleValue]];
        if ([userInfo[@"Total Time"] isEqualToNumber:@(0)]) {
            self._noDurationTimer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(updateTrackDuration:) userInfo:nil repeats:NO];
         }
    }
    self.currentTrack.trackOrigin = TrackFromiTunes;
}

-(void)updateTrackDuration:(NSTimer *)timer
{
    iTunesApplication *iTunes = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
    if (iTunes.isRunning) {
        self.currentTrack.duration = iTunes.currentTrack.duration;
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
        NSDictionary *userInfoFromNotification = notification.userInfo;
        NSDictionary *trackInfo = @{ @"Artist"              : userInfoFromNotification[@"Artist"],
                                     @"Album Artist"        : userInfoFromNotification[@"Album Artist"],
                                     @"Artist"              : userInfoFromNotification[@"Artist"],
                                     @"TrackName"           : userInfoFromNotification[@"Name"],
                                     @"Player State"        : userInfoFromNotification[@"Player State"],
                                     @"Store URL"           : [NSNull null],
                                     @"Duration"            : userInfoFromNotification[@"Duration"],
                                     @"Player"              : @"Spotify"
                                     };
        self.currentPlayer = MusicPlayerSpotify;
        [self setCurrentTrackFromSpotify];
        [self postNotificationWithTrackInfo:trackInfo];
    }
}

-(void)setCurrentTrackFromSpotify
{
    self._spotifyApp = [SBApplication applicationWithBundleIdentifier:@"com.spotify.client"];
    self._currentSpotifyTrack = self._spotifyApp.currentTrack;
    self._currentiTunesTrack = nil;
    self.currentTrack = [Track trackWithSpotifyTrack:self._spotifyApp.currentTrack];
    self.currentTrack.trackOrigin = TrackFromSpotify;
}

-(NSImage *)currentSpotifyTrackCover
{
#warning currentSpotifyTrackCover do zrobienia
    return nil;
}

#pragma mark - Common
-(void)postNotificationWithTrackInfo:(NSDictionary *)info
{
    NSNotification *note = [NSNotification notificationWithName:kMusicPlayerNotification object:nil userInfo:info];
    [[NSNotificationCenter defaultCenter] postNotification:note];
}

-(void)openArtistPageForTrack:(Track *)track
{
#warning do zrobienia strona artysty w playerze
}

-(NSImage *)currentTrackCover
{
    if (self.currentPlayer == MusicPlayeriTunes) {
        return [self currentiTunesTrackCover];
    } else if (self.currentPlayer == MusicPlayerSpotify) {
        return [self currentSpotifyTrackCover];
    } else return nil;
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


-(void)setCurrentPlayer:(MusicPlayerApplication)currentPlayer
{
    @synchronized (self) {
        if (_currentPlayer == MusicPlayerUndefined) {
            _currentPlayer = currentPlayer;
            return;
        }
        if (_currentPlayer == MusicPlayerSpotify && currentPlayer == MusicPlayeriTunes && !self.isSpotifyRunning) {
            _currentPlayer = currentPlayer;
            return;
        }
        if (_currentPlayer == MusicPlayeriTunes && currentPlayer == MusicPlayerSpotify && !self.isiTunesRunning) {
            _currentPlayer = currentPlayer;
            return;
        }
    }
}

-(MusicPlayerApplication)currentPlayer
{
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
    iTunesApplication *iTunes = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
    if (iTunes.isRunning) {
        return YES;
    }
    return NO;
}

-(BOOL)isSpotifyRunning
{
    SpotifyApplication *spotify = [SBApplication applicationWithBundleIdentifier:@"com.spotify.client"];
    if (spotify.isRunning) {
        return YES;
    }
    return NO;
}

#pragma mark Soundvolume
#warning Soundvolume do napisania
@end