//
//  Song.m
//  NepTunes
//
//  Created by rurza on 30/12/15.
//  Copyright © 2015 micropixels. All rights reserved.
//

#import "Song.h"

@implementation Song

-(instancetype)initWithTrackName:(NSString *)tn artist:(NSString *)art album:(NSString *)alb andDuration:(double)d
{
    self = [super init];
    if (self) {
        self.trackName = tn;
        self.artist = art;
        self.album = alb;
        self.duration = d;
    }
    return self;
}

@end
