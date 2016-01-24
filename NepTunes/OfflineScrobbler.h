//
//  OfflineScrobbler.h
//  NepTunes
//
//  Created by rurza on 20/01/16.
//  Copyright © 2016 micropixels. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MusicScrobbler.h"
@class Song;
@class SavedSong;

@interface OfflineScrobbler : NSObject <MusicScrobblerDelegate>
@property (nonatomic, readonly) NSMutableArray *songs;
@property (nonatomic) BOOL areWeOffline;

+(OfflineScrobbler *)sharedInstance;
-(void)saveSong:(Song *)song;
-(void)deleteSong:(SavedSong *)song;

@end
