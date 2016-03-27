//
//  SocialMessage.m
//  NepTunes
//
//  Created by rurza on 27/03/16.
//  Copyright © 2016 micropixels. All rights reserved.
//

#import "SocialMessage.h"
#import "Track.h"
#import "ItunesSearch.h"
#import "MusicScrobbler.h"
#import "MenuController.h"

@implementation SocialMessage

+(void)messageForCurrentTrackWithCompletionHandler:(void(^)(NSString *message))handler
{
    Track *currentTrack = [MusicScrobbler sharedScrobbler].currentTrack;
    ItunesSearch *iTunesSearch = [MenuController sharedController].iTunesSearch;

    if (currentTrack.trackName) {
        NSString *artistHashtag = currentTrack.artist;
        artistHashtag = [artistHashtag stringByReplacingOccurrencesOfString:@" " withString:@""];
        NSMutableString *content = [NSMutableString stringWithFormat:@"Now playing %@ by %@ #%@ #NeptunesForMac", currentTrack.trackName, currentTrack.artist, artistHashtag];
        
        [iTunesSearch getTrackWithName:currentTrack.trackName artist:currentTrack.artist album:currentTrack.album limitOrNil:nil successHandler:^(NSArray *result) {
            NSDictionary *firstResult = result.firstObject;
            [content appendString:[NSString stringWithFormat:@" %@", [firstResult objectForKey:@"collectionViewUrl"]]];
            handler(content);
        } failureHandler:^(NSError *error) {
            handler(content);
        }];
    }
}

+(void)messageForLovedTrackWithCompletionHandler:(void(^)(NSString *message))handler
{
    Track *currentTrack = [MusicScrobbler sharedScrobbler].currentTrack;
    ItunesSearch *iTunesSearch = [MenuController sharedController].iTunesSearch;
    
    if (currentTrack.trackName) {
        NSString *artistHashtag = currentTrack.artist;
        artistHashtag = [artistHashtag stringByReplacingOccurrencesOfString:@" " withString:@""];
        NSMutableString *content = [NSMutableString stringWithFormat:@"I love %@ by %@ #LastFM #%@ #NeptunesForMac", currentTrack.trackName, currentTrack.artist, artistHashtag];
        
        [iTunesSearch getTrackWithName:currentTrack.trackName artist:currentTrack.artist album:currentTrack.album limitOrNil:nil successHandler:^(NSArray *result) {
            NSDictionary *firstResult = result.firstObject;
            [content appendString:[NSString stringWithFormat:@" %@", [firstResult objectForKey:@"collectionViewUrl"]]];
            handler(content);
        } failureHandler:^(NSError *error) {
            handler(content);
        }];
    }
}

@end
