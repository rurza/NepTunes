//
//  MusicController.h
//  NepTunes
//
//  Created by rurza on 02/02/16.
//  Copyright © 2016 micropixels. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "iTunes.h"
#import "Spotify.h"
@class CoverWindowController;

@interface MusicController : NSObject
@property (nonatomic) iTunesApplication *iTunes;
@property (nonatomic) SpotifyApplication *spotify;
@property (nonatomic, readonly) BOOL isiTunesRunning;
@property (nonatomic, readonly) BOOL isSpotifyRunning;
@property (nonatomic, readonly) iTunesEPlS iTunesPlayerState;
@property (nonatomic, readonly) SpotifyEPlS SpotifyplayerState;
@property (nonatomic) iTunesTrack *currentiTunesTrack;
@property (nonatomic) SpotifyTrack *currentSpotifyTrack;
@property (nonatomic) CoverWindowController *coverWindowController ;

+(instancetype)sharedController;
-(void)loveTrackWithCompletionHandler:(void(^)(void))handler;
-(void)invalidateTimers;
-(void)updateTrackInfo:(NSNotification *)note;
-(NSImage *)currentTrackCover;
-(void)setupCover;
@end
