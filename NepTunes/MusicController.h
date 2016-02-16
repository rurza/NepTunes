//
//  MusicController.h
//  NepTunes
//
//  Created by rurza on 02/02/16.
//  Copyright © 2016 micropixels. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "iTunes.h"
@class CoverWindowController;

@interface MusicController : NSObject
@property (nonatomic) iTunesApplication *iTunes;
@property (nonatomic, readonly) BOOL isiTunesRunning;
@property (nonatomic, readonly) iTunesEPlS playerState;
@property (nonatomic) iTunesTrack *currentTrack;
@property (nonatomic) CoverWindowController *coverWindowController ;

+(instancetype)sharedController;
-(void)loveTrackWithCompletionHandler:(void(^)(void))handler;
-(void)invalidateTimers;
-(void)updateTrackInfo:(NSNotification *)note;
-(NSImage *)currentTrackCover;
@end
