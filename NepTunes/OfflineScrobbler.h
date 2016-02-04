//
//  OfflineScrobbler.h
//  NepTunes
//
//  Created by rurza on 20/01/16.
//  Copyright © 2016 micropixels. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MusicScrobbler.h"
@class Track;
@class SavedTrack;

@interface OfflineScrobbler : NSObject <MusicScrobblerDelegate>
@property (nonatomic, readonly) NSMutableArray *songs;
@property (nonatomic) BOOL areWeOffline;
@property (nonatomic) BOOL lastFmIsDown;
@property (nonatomic) BOOL userWasLoggedOut;

+(OfflineScrobbler *)sharedInstance;
-(void)saveTrack:(Track *)track;
-(void)deleteTrack:(SavedTrack *)track;
-(void)deleteAllSavedTracks;
@end
