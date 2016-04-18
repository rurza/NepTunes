//
//  MusicPlayer.h
//  NepTunes
//
//  Created by Adam Różyński on 18/04/16.
//  Copyright © 2016 micropixels. All rights reserved.
//
//one class to control music from iTunes and Spotify

#import <Foundation/Foundation.h>
@class Track;
@class iTunesTrack;
@class SpotifyTrack;

typedef NS_ENUM(NSInteger, MusicPlayerApplication) {
    MusicPlayeriTunes,
    MusicPlayerSpotify
};

typedef NS_ENUM(NSInteger, MusicPlayerState) {
    MusicPlayerStateUndefined,
    MusicPlayerPlaying,
    MusicPlayerPaused,
    MusicPlayerStopped
};

@interface MusicPlayer : NSObject

@property (atomic) MusicPlayerApplication currentPlayer;
@property (atomic, readonly) Track *currentTrack;
@property (atomic, readonly) SpotifyTrack *currentSpotifyTrack;
@property (atomic, readonly) iTunesTrack *currentiTunesTrack;
@property (atomic) MusicPlayerState playerState;
@end