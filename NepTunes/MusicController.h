//
//  MusicController.h
//  NepTunes
//
//  Created by rurza on 02/02/16.
//  Copyright © 2016 micropixels. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "iTunes.h"

@interface MusicController : NSObject
@property (nonatomic) iTunesApplication *iTunes;
@property (nonatomic, readonly) BOOL isiTunesRunning;
@property (nonatomic, readonly) iTunesEPlS playerState;
+(instancetype)sharedController;
-(void)loveTrackIniTunes;
@end
