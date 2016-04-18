//
//  MusicPlayer.m
//  NepTunes
//
//  Created by Adam Różyński on 18/04/16.
//  Copyright © 2016 micropixels. All rights reserved.
//

#import "MusicPlayer.h"
#import "iTunes.h"
#import "Spotify.h"
#import "Track.h"

@interface MusicPlayer ()
@property (atomic, readwrite) Track *currentTrack;
@property (nonatomic) NSTimer * _noDurationTimer;
@property (atomic, readwrite) SpotifyTrack *currentSpotifyTrack;
@property (atomic, readwrite) iTunesTrack *currentiTunesTrack;
@end

@implementation MusicPlayer

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
    [self updatePlayerStateWithUserInfo:userInfoFromNotification];
    [self setCurrentTrackFromiTunesOrUserInfo:userInfoFromNotification];
    [self postNotificationWithTrackInfo:trackInfo];
}

-(void)setCurrentTrackFromiTunesOrUserInfo:(NSDictionary *)userInfo
{
    iTunesApplication *iTunes = [iTunesApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
    if (iTunes.currentTrack.name.length && iTunes.currentTrack.duration) {
        self.currentTrack = [Track trackWithiTunesTrack:iTunes.currentTrack];
        self.currentiTunesTrack = iTunes.currentTrack;
        self.currentSpotifyTrack = nil;
    } else {
        self.currentSpotifyTrack = nil;
        self.currentTrack = [[Track alloc] initWithTrackName:userInfo[@"Name"] artist:userInfo[@"Artist"] album:userInfo[@"Album"] andDuration:[userInfo[@"Total Time"] doubleValue]];
        if ([userInfo[@"Total Time"] isEqualToNumber:@(0)]) {
            self._noDurationTimer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(updateTrackDuration:) userInfo:nil repeats:NO];
         }
    }
}

-(void)updateTrackDuration:(NSTimer *)timer
{
    iTunesApplication *iTunes = [iTunesApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
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

#pragma mark - Spotify

-(void)notificationFromSpotify:(NSNotification *)notification
{
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
    [self updatePlayerStateWithUserInfo:userInfoFromNotification];
    [self setCurrentTrackFromSpotify];
    [self postNotificationWithTrackInfo:trackInfo];
}

-(void)setCurrentTrackFromSpotify
{
    SpotifyApplication *spotify = [SpotifyApplication applicationWithBundleIdentifier:@"com.spotify.client"];
    self.currentSpotifyTrack = spotify.currentTrack;
    self.currentiTunesTrack = nil;
    self.currentTrack = [Track trackWithSpotifyTrack:spotify.currentTrack];
}

#pragma mark - Common

-(void)updatePlayerStateWithUserInfo:(NSDictionary *)userInfo
{
    if ([[userInfo objectForKey:@"Player State"] isEqualToString:@"Playing"]) {
        self.playerState = MusicPlayerPlaying;
    } else if ([[userInfo objectForKey:@"Player State"] isEqualToString:@"Stopped"]) {
        self.playerState = MusicPlayerStopped;
    } else if ([[userInfo objectForKey:@"Player State"] isEqualToString:@"Paused"]) {
        self.playerState = MusicPlayerPaused;
    } else {
        self.playerState = MusicPlayerStateUndefined;
    }
}

-(void)postNotificationWithTrackInfo:(NSDictionary *)info
{
    NSNotification *note = [NSNotification notificationWithName:@"NepTunes.playerInfo" object:nil userInfo:info];
    [[NSNotificationCenter defaultCenter] postNotification:note];
}

@end