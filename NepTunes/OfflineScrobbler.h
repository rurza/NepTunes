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

@property (nonatomic) BOOL areWeOffline;
//Co potrzebuje?
//1.singleton
+(OfflineScrobbler *)sharedInstance;
-(void)saveSong:(Song *)song;
-(void)deleteSong:(SavedSong *)song;

//2.zapisanie utworu
//3.usuniecie utwory
//4.timer
//
@end
