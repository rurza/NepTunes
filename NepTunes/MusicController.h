//
//  MusicController.h
//  NepTunes
//
//  Created by rurza on 02/02/16.
//  Copyright © 2016 micropixels. All rights reserved.
//

#import <Foundation/Foundation.h>
@class CoverWindowController;
@class MusicPlayer;

@interface MusicController : NSObject


@property (nonatomic) CoverWindowController *coverWindowController ;
@property (nonatomic) MusicPlayer *musicPlayer;

+(instancetype)sharedController;
-(void)loveTrackWithCompletionHandler:(void(^)(void))handler;
-(void)invalidateTimers;
-(void)updateTrackInfo:(NSNotification *)note;
-(void)setupCover;
@end
