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

#define FOUR_MINUTES 60 * 4
#define DELAY_FOR_RADIO 5

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
extern NSString *const kCannotGetInfoFromSpotify;


@interface MusicPlayer : NSObject

@property (atomic, readonly) MusicPlayerApplication     currentPlayer;
@property (nonatomic, readonly) Track                   *currentTrack;
@property (nonatomic, readonly) MusicPlayerState        playerState;
@property (nonatomic, readonly) BOOL                    isPlayerRunning;
@property (nonatomic, readonly) BOOL                    canObtainCurrentTrackFromiTunes;
@property (nonatomic, readonly) NSUInteger              numberOfPlayers;

@property (nonatomic) BOOL                              playerIntegration;
@property (nonatomic) BOOL                              currentTrackIsLoved;
@property (nonatomic) NSInteger                         soundVolume;
@property (nonatomic) id<MusicPlayerDelegate>           delegate;

+(instancetype)sharedPlayer;

-(void)openArtistPageForArtistName:(NSString *)artistName withFailureHandler:(void(^)(void))failureHandler;
-(void)openArtistPageInPlayer:(MusicPlayerApplication)player forArtistName:(NSString *)artistName withFailureHandler:(void(^)(void))failureHandler;
-(void)openTrackPageForTrack:(Track *)track withFailureHandler:(void(^)(void))failureHandler;

-(id)currentTrackCoverOrURL;

-(void)getCurrentTrackURLPublicLink:(BOOL)publicLink withCompletionHandler:(void(^)(NSString *urlString))handler failureHandler:(void(^)(NSError *error))failureHandler;
-(void)getTrackURL:(Track *)track publicLink:(BOOL)publicLink withCompletionHandler:(void(^)(NSString *urlString))handler failureHandler:(void(^)(NSError *error))failureHandler;
-(void)getTrackURL:(Track *)track forPlayer:(MusicPlayerApplication)player publicLink:(BOOL)publicLink withCompletionHandler:(void(^)(NSString *urlString))handler failureHandler:(void(^)(NSError *error))failureHandler;
-(void)getTrackURL:(Track *)track publicLink:(BOOL)publicLink forCurrentPlayerWithCompletionHandler:(void(^)(NSString *urlString))handler failureHandler:(void(^)(NSError *error))failureHandler;

-(void)getArtistURLForArtist:(NSString *)artist publicLink:(BOOL)publicLink forCurrentPlayerWithCompletionHandler:(void(^)(NSString *urlString))handler failureHandler:(void(^)(NSError *error))failureHandler;
-(void)getArtistURLForArtist:(NSString *)artist forPlayer:(MusicPlayerApplication)player publicLink:(BOOL)publicLink withCompletionHandler:(void(^)(NSString *urlString))handler failureHandler:(void(^)(NSError *error))failureHandler;


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
