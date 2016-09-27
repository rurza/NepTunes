//
//  MusicScrobbler.h
//  NepTunes
//
//  Created by rurza on 04/07/15.
//  Copyright (c) 2015 micropixels. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LastFmCache.h"

@class Track;
@class SavedTrack;
@class CoverWindowController;

@protocol MusicScrobblerDelegate <NSObject>
@property (nonatomic, readonly) NSMutableArray *tracks;
-(void)trackWasSuccessfullyScrobbled:(Track *)track;
-(void)trackWasNotScrobbled:(Track *)track;
@end

@interface MusicScrobbler : NSObject

@property (nonatomic) LastFm *scrobbler;
@property (nonatomic) LastFmCache *lastfmCache;

@property (nonatomic) NSDictionary *infoAboutCurrentTrack;
@property (nonatomic) NSString *username;
@property (nonatomic) Track *currentTrack;
@property (nonatomic, weak) id<MusicScrobblerDelegate>delegate;
@property (nonatomic) NSArray *tagsToCut;


+(MusicScrobbler *)sharedScrobbler;
-(void)updateCurrentTrackWithUserInfo:(NSDictionary *)userInfo;
/// sends current track to Last.fm as a scrobbled
-(void)scrobbleCurrentTrack;
-(void)scrobbleOfflineTrack:(SavedTrack *)track;

/// sends current track to Last.fm as a "now playing"
-(void)nowPlayingCurrentTrack;
/// loves current track on Last.fm
-(void)loveCurrentTrackWithCompletionHandler:(void(^)(Track *track, NSImage *artwork))completion;

-(void)logInWithCredentials:(NSDictionary *)info;
-(void)logOut;
-(void)downloadNewTagsLibraryAndStoreIt;
-(NSArray *)stringsWithRemovedUnwantedTagsFromTrack:(Track *)track;

@end
