//
//  Track.h
//  NepTunes
//
//  Created by rurza on 30/12/15.
//  Copyright © 2015 micropixels. All rights reserved.
//

#import <Foundation/Foundation.h>
@class iTunesTrack;
@class SpotifyTrack;

typedef NS_ENUM(NSInteger, TrackOrigin) {
    TrackFromiTunes,
    TrackFromSpotify
};

typedef NS_ENUM(NSInteger, TrackKind) {
    TrackKindUndefined,
    TrackKindMusic,
    TrackKindPodcast,
    TrackKindVideo,
    TrackKindiTunesU
};

@interface Track : NSObject <NSCoding>

@property (nonatomic) NSString *trackName;
@property (nonatomic) NSString *artist;
@property (nonatomic) NSString *album;
@property (nonatomic) double duration;//in seconds
@property (nonatomic) BOOL itIsNotMusic;
@property (nonatomic) BOOL loved;
@property (nonatomic) TrackOrigin trackOrigin;
@property (nonatomic) TrackKind trackKind;
@property (nonatomic) NSInteger rating;
#warning do zrobienia, kind z iTunesa
@property (nonatomic) NSString *kind;

-(instancetype)initWithTrackName:(NSString *)tn artist:(NSString *)art album:(NSString *)alb andDuration:(double)d;
+(Track *)trackWithiTunesTrack:(iTunesTrack *)track;
+(Track *)trackWithSpotifyTrack:(SpotifyTrack *)track;
-(BOOL)isEqualToTrack:(Track *)track;

@end