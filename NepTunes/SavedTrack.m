//
//  SavedSong.m
//  NepTunes
//
//  Created by rurza on 20/01/16.
//  Copyright © 2016 micropixels. All rights reserved.
//

#import "SavedTrack.h"

@implementation SavedTrack

-(instancetype)initWithTrack:(Track *)song andDate:(NSDate *)date
{
    self = [super initWithTrackName:song.trackName artist:song.artist album:song.album andDuration:song.duration];
    if (self) {
        self.date = date;
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:self.date forKey:@"date"];
}

-(id)initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder:decoder];
    if (self)
    {
        self.date = [decoder decodeObjectForKey:@"date"];
    }
    return self;
}


@end
