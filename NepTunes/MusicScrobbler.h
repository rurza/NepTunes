//
//  MusicScrobbler.h
//  NepTunes
//
//  Created by rurza on 04/07/15.
//  Copyright (c) 2015 micropixels. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "iTunes.h"
#import "LastFmCache.h"

@class Song;

static NSString *const kUsernameKey = @"pl.micropixels.neptunes.usernameKey";
static NSString *const kSessionKey = @"pl.micropixels.neptunes.sessionKey";

@interface MusicScrobbler : NSObject

@property (nonatomic) LastFm *scrobbler;
@property (nonatomic) LastFmCache *lastfmCache;
@property (nonatomic) iTunesApplication* iTunes;

@property (nonatomic) NSDictionary *infoAboutCurrentTrack;
@property (nonatomic) NSString *username;
@property (nonatomic) Song *currentTrack;

+(MusicScrobbler *)sharedScrobbler;


/// sends current track to Last.fm as a scrobbled
-(void)scrobbleCurrentTrack;
/// sends current track to Last.fm as a "now playing"
-(void)nowPlayingCurrentTrack;
/// loves current track on Last.fm
-(void)loveCurrentTrackWithCompletionHandler:(void(^)(void))completion;

-(void)logInWithCredentials:(NSDictionary *)info;
-(void)logOut;

@end
