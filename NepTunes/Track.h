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
    TrackKindiTunesU,
    TrackKindAd
};

extern NSString *const kTrackRatingWasSetNotificationName;


@interface Track : NSObject <NSCoding> {
    NSInteger _rating;
}

@property (nonatomic, readonly) NSString *truncatedTrackName;
@property (nonatomic, readonly) NSString *truncatedArtist;

@property (nonatomic, copy) NSString *trackName;
@property (nonatomic, copy) NSString *artist;
@property (nonatomic, copy) NSString *albumArtist;
@property (nonatomic, copy) NSString *album;
@property (nonatomic, copy) NSString *kind;
@property (nonatomic, copy) NSString *artworkURL;
@property (nonatomic, copy) NSString *spotifyID;

@property (nonatomic) double duration;//in seconds
@property (nonatomic) BOOL itIsNotMusic;
@property (nonatomic) BOOL loved;
@property (nonatomic) TrackOrigin trackOrigin;

///it seems not comptaible with iTunes Version 12.9.0.164
@property (nonatomic) TrackKind trackKind;
@property (nonatomic) NSInteger rating;

@property (nonatomic) NSImage *artwork;

-(instancetype)initWithTrackName:(NSString *)tn artist:(NSString *)art album:(NSString *)alb andDuration:(double)d;
+(Track *)trackWithiTunesTrack:(iTunesTrack *)track;
+(Track *)trackWithSpotifyTrack:(SpotifyTrack *)track;
-(BOOL)isEqualToTrack:(Track *)track;
-(void)setRating:(NSInteger)rating;
-(NSInteger)rating;

@end
