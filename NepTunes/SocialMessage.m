//
//  SocialMessage.m
//  NepTunes
//
//  Created by rurza on 27/03/16.
//  Copyright © 2016 micropixels. All rights reserved.
//

#import "SocialMessage.h"
#import "Track.h"
#import "MusicScrobbler.h"
#import "MenuController.h"
#import "MusicPlayer.h"

@implementation SocialMessage

+(void)messageForCurrentTrackWithCompletionHandler:(void(^)(NSString *message))handler
{
    Track *currentTrack = [MusicScrobbler sharedScrobbler].currentTrack;

    if (currentTrack.trackName) {
        NSString *artistHashtag = currentTrack.artist;
        artistHashtag = [artistHashtag stringByReplacingOccurrencesOfString:@" " withString:@""];
        NSMutableString *content = [NSMutableString stringWithFormat:@"Now playing %@ by %@ #%@ #NeptunesForMac", currentTrack.trackName, currentTrack.artist, artistHashtag];
        
        [[MusicPlayer sharedPlayer] getCurrentTrackURLPublicLink:YES withCompletionHandler:^(NSString *urlString) {
            if (urlString.length) {
                [content appendString:[NSString stringWithFormat:@" %@", urlString]];
            }
            handler(content);
        } failureHandler:^(NSError * error) {
            handler(content);
        }];
    }
}

+(void)messageForLovedTrackWithCompletionHandler:(void(^)(NSString *message))handler
{
    Track *currentTrack = [MusicScrobbler sharedScrobbler].currentTrack;
    
    if (currentTrack.trackName) {
        NSString *artistHashtag = currentTrack.artist;
        artistHashtag = [artistHashtag stringByReplacingOccurrencesOfString:@" " withString:@""];
        NSMutableString *content = [NSMutableString stringWithFormat:@"I love %@ by %@ #LastFM #%@ #NeptunesForMac", currentTrack.trackName, currentTrack.artist, artistHashtag];
        
        [[MusicPlayer sharedPlayer] getCurrentTrackURLPublicLink:YES withCompletionHandler:^(NSString *urlString) {
            [content appendString:[NSString stringWithFormat:@" %@", urlString]];
            handler(content);
        } failureHandler:^(NSError * error) {
            handler(content);
        }];
    }
}

@end
