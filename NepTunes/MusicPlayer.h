//
//  MusicPlayer.h
//  NepTunes
//
//  Created by Adam Różyński on 18/04/16.
//  Copyright © 2016 micropixels. All rights reserved.
//
//one class to control music from iTunes and Spotify

#import <Foundation/Foundation.h>
#import "Track.h"
#import "MusicPlayerDelegate.h"
@class iTunesTrack;
@class SpotifyTrack;



typedef NS_ENUM(NSInteger, MusicPlayerApplication) {
    MusicPlayerUndefined,
    MusicPlayeriTunes,
    MusicPlayerSpotify
};

typedef NS_ENUM(NSInteger, MusicPlayerState) {
    MusicPlayerStateUndefined,
    MusicPlayerStatePlaying,
    MusicPlayerStatePaused,
    MusicPlayerStateStopped
};

extern NSString *const kiTunesBundleIdentifier;
extern NSString *const kSpotifyBundlerIdentifier;

@interface MusicPlayer : NSObject

@property (atomic, readonly) MusicPlayerApplication currentPlayer;
@property (nonatomic, readonly) Track *currentTrack;
@property (nonatomic, readonly) MusicPlayerState playerState;
@property (nonatomic, readonly) BOOL isPlayerRunning;
@property (nonatomic) BOOL playerIntegration;
@property (nonatomic) BOOL currentTrackIsLoved;
@property (nonatomic) NSInteger soundVolume;
@property (nonatomic) id<MusicPlayerDelegate> delegate;

+(instancetype)sharedPlayer;

-(void)openArtistPageForTrack:(Track *)track;
-(id)currentTrackCoverOrURL;

//playback
-(void)playPause;
-(void)nextTrack;
-(void)backTrack;
-(void)fastForward;
-(void)rewind;
-(void)resume;

-(void)loveCurrentTrackOniTunes;
-(void)bringPlayerToFront;
-(void)changeSourceTo:(MusicPlayerApplication)source;
@end