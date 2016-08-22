//
//  MusicController.h
//  NepTunes
//
//  Created by rurza on 02/02/16.
//  Copyright © 2016 micropixels. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MusicPlayerDelegate.h"

@class CoverWindowController;
@class MusicPlayer;

extern NSString * const kTrackInfoUpdated;

@interface MusicController : NSObject <MusicPlayerDelegate>

@property (nonatomic) CoverWindowController *coverWindowController ;
@property (nonatomic) MusicPlayer *musicPlayer;

+(instancetype)sharedController;
-(void)loveTrackWithCompletionHandler:(void(^)(void))handler;
///wyłącza wszystkie timery, np. po zmianie utworu
-(void)invalidateTimers;
///konfiguruje okładkę
-(void)setupCover;

@end