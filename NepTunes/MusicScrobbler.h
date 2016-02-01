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
@class SavedSong;

@protocol MusicScrobblerDelegate <NSObject>
-(void)songWasSuccessfullyScrobbled:(Song *)song;
-(void)songWasNotScrobbled:(Song *)song;
@end

@interface MusicScrobbler : NSObject

@property (nonatomic) LastFm *scrobbler;
@property (nonatomic) LastFmCache *lastfmCache;
@property (nonatomic) iTunesApplication* iTunes;

@property (nonatomic) NSDictionary *infoAboutCurrentTrack;
@property (nonatomic) NSString *username;
@property (nonatomic) Song *currentTrack;
@property (nonatomic, weak) id<MusicScrobblerDelegate>delegate;

+(MusicScrobbler *)sharedScrobbler;
-(void)updateCurrentTrackWithUserInfo:(NSDictionary *)userInfo;
/// sends current track to Last.fm as a scrobbled
-(void)scrobbleCurrentTrack;
-(void)scrobbleOfflineTrack:(Song *)song atTimestamp:(NSTimeInterval)timestamp withTryCounter:(NSUInteger)tryCounter;
-(void)scrobbleOfflineTrack:(SavedSong *)song;

/// sends current track to Last.fm as a "now playing"
-(void)nowPlayingCurrentTrack;
/// loves current track on Last.fm
-(void)loveCurrentTrackWithCompletionHandler:(void(^)(Song *track))completion;

-(void)logInWithCredentials:(NSDictionary *)info;
-(void)logOut;

@end
