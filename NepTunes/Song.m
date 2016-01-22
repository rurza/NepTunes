//
//  Song.m
//  NepTunes
//
//  Created by rurza on 30/12/15.
//  Copyright © 2015 micropixels. All rights reserved.
//

#import "Song.h"
#import "iTunes.h"

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
    if (!tn || !art) {
        return nil;
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)encoder
{
    //Encode the properties of the object
    [encoder encodeObject:self.trackName forKey:@"trackName"];
    [encoder encodeObject:self.artist forKey:@"artist"];
    [encoder encodeObject:self.album forKey:@"album"];
    [encoder encodeObject:@(self.duration) forKey:@"duration"];
}

-(id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if ( self != nil )
    {
        //decode the properties
        self.trackName = [decoder decodeObjectForKey:@"trackName"];
        self.artist = [decoder decodeObjectForKey:@"artist"];
        self.album = [decoder decodeObjectForKey:@"album"];
        self.duration = [[decoder decodeObjectForKey:@"duration"] doubleValue];
    }
    return self;
}

+(Song *)songWithiTunesTrack:(iTunesTrack *)track
{
    if (!track.name || !track.artist) {
        return nil;
    }
    Song *song = [[Song alloc] initWithTrackName:track.name artist:track.artist album:track.album andDuration:track.duration];
    return song;
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"%@ by %@", self.trackName, self.artist];
}

#pragma mark Equality

-(BOOL)isEqual:(id)object
{
    if (self == object) {
        return YES;
    }
    
    if (![object isKindOfClass:[Song class]]) {
        return NO;
    }
    
    return [self isEqualToSong:(Song *)object];
}

-(BOOL)isEqualToSong:(Song *)song
{
    if (self == song) {
        return YES;
    }
    BOOL itIsEqual = ([self.trackName isEqualToString:song.trackName] && [self.album isEqualToString:song.album] && [self.artist isEqualToString:song.artist]);
    return itIsEqual;
}

-(NSUInteger)hash
{
    return [self.trackName hash] ^ [self.album hash];
}
@end
