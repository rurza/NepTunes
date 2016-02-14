//
//  GetCover.m
//  NepTunes
//
//  Created by rurza on 12/02/16.
//  Copyright © 2016 micropixels. All rights reserved.
//

#import "GetCover.h"
#import "MusicScrobbler.h"
#import "Track.h"
#import "MusicController.h"
#import "FXReachability.h"
#import "iTunesSearch.h"
#include <CommonCrypto/CommonDigest.h>
#import "SettingsController.h"

@interface GetCover ()
@property (nonatomic) NSCache *cache;

@end

@implementation GetCover

+(GetCover *)sharedInstance
{
    static GetCover *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[GetCover alloc] init];
    });
    return sharedInstance;
}

-(void)getCoverWithTrack:(Track *)track withCompletionHandler:(void(^)(NSImage *cover))handler
{
    if ([[MusicController sharedController] currentTrackCover]) {
        handler([[MusicController sharedController] currentTrackCover]);
        if ([self.delegate respondsToSelector:@selector(trackInfoShouldBeDisplayed)]) {
            [self.delegate trackInfoShouldBeDisplayed];
        }
    } else {
        if ([self cachedCoverImageForTrack:track]) {
            handler([[GetCover sharedInstance] cachedCoverImageForTrack:track]);
            if ([self.delegate respondsToSelector:@selector(trackInfoShouldBeDisplayed)]) {
                [self.delegate trackInfoShouldBeDisplayed];
            }
            return;
        }
        if ([self.delegate respondsToSelector:@selector(trackInfoShouldBeRemoved)]) {
            [self.delegate trackInfoShouldBeRemoved];
        }
        if ([FXReachability sharedInstance].isReachable) {
            
            __weak typeof(self) weakSelf = self;
            [[ItunesSearch sharedInstance] getAlbumWithArtist:track.artist andName:track.album limitOrNil:@20 successHandler:^(NSArray *result) {
                NSString *coverURL;
                for (NSDictionary *singleResult in result) {
                    if ([singleResult objectForKey:@"artworkUrl100"]) {
                        coverURL = [singleResult objectForKey:@"artworkUrl100"];
                        break;
                    }
                }
                if (coverURL) {
                    if ([SettingsController sharedSettings].debugMode) {
                        NSLog(@"coverURL from iTunes %@", coverURL);
                    }
                    [[GetCover sharedInstance] getInfoWithLastFMForTrack:track withCompletionHandler:^(NSString *urlString) {
                        if (urlString.length) {
                            if ([SettingsController sharedSettings].debugMode) {
                                NSLog(@"I choose cover from Last.fm");
                            }
                            [weakSelf getCoverForTrack:track fromString:urlString andCompletionHandler:^(NSImage *cover) {
                                handler(cover);
                            }];
                        } else {
                            if ([SettingsController sharedSettings].debugMode) {
                                NSLog(@"I choose cover from iTunes Search");
                            }
                            [weakSelf getCoverForTrack:track fromString:coverURL andCompletionHandler:^(NSImage *cover) {
                                handler(cover);
                            }];
                        }
                    }];
                } else {
                    [weakSelf getInfoWithLastFMForTrack:track withCompletionHandler:^(NSString *urlString) {
                        if (urlString.length) {
                            [weakSelf getCoverForTrack:track fromString:urlString andCompletionHandler:^(NSImage *cover) {
                                handler(cover);
                            }];
                        }
                    }];
                }
            } failureHandler:^(NSError *error) {
                [weakSelf getInfoWithLastFMForTrack:track withCompletionHandler:^(NSString *urlString) {
                    [weakSelf getCoverForTrack:track fromString:urlString andCompletionHandler:^(NSImage *cover) {
                        handler(cover);
                    }];
                }];
            }];
        }
        else {
            handler([GetCover defaultCover]);
        }
    }
}


-(void)getInfoWithLastFMForTrack:(Track *)track withCompletionHandler:(void(^)(NSString *urlString))handler
{
    [[MusicScrobbler sharedScrobbler].scrobbler getInfoForTrack:track.trackName artist:track.artist successHandler:^(NSDictionary *result) {
        NSString *artworkURLString = [(NSURL *)result[@"image"] absoluteString];
        if ([SettingsController sharedSettings].debugMode) {
            NSLog(@"artworkURLString from Last.fm = %@", artworkURLString);
        }
        if (artworkURLString) {
            handler(artworkURLString);
        } else {
            handler(nil);
        }
    } failureHandler:^(NSError *error) {
        if (handler) {
            handler(nil);
        }
    }];
}

-(void)getCoverForTrack:(Track *)track fromString:(NSString *)urlString andCompletionHandler:(void(^)(NSImage *cover))handler
{
    NSURL *artworkURL = [NSURL URLWithString:urlString];
    NSURLRequest *albumArtworkRequest = [NSURLRequest requestWithURL:artworkURL];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    __weak typeof(self) weakSelf = self;
    NSURLSessionDownloadTask *artworkDownloadTask = [session downloadTaskWithRequest:albumArtworkRequest completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSImage *artwork = [[NSImage alloc] initWithContentsOfURL:location];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (![weakSelf cachedCoverImageForTrack:track]) {
                [weakSelf saveCoverImage:artwork forTrack:track];
            }
            if ([self.delegate respondsToSelector:@selector(trackInfoShouldBeDisplayed)]) {
                [self.delegate trackInfoShouldBeDisplayed];
            }
            handler(artwork);
        });
    }];
    [artworkDownloadTask resume];
}

+(NSImage *)defaultCover
{
    return [NSImage imageNamed:@""];
}

-(void)saveCoverImage:(NSImage *)image forTrack:(Track *)track
{
    NSString *key = [self md5sumFromString: [NSString stringWithFormat:@"%@%@", track.artist, track.album]];
    [self.cache setObject:image forKey:key];
    if ([SettingsController sharedSettings].debugMode) {
        NSLog(@"...so I save it for key %@", key);
    }
}

-(NSImage *)cachedCoverImageForTrack:(Track *)track
{
    NSString *key = [self md5sumFromString:[NSString stringWithFormat:@"%@%@", track.artist, track.album]];
    if ([self.cache objectForKey:key]) {
        if ([SettingsController sharedSettings].debugMode) {
            NSLog(@"Cover image for key %@", key);
        }
        return [self.cache objectForKey:key];
    }
    if ([SettingsController sharedSettings].debugMode) {
        NSLog(@"There is no cover image for key %@...", key);
    }
    return nil;
}

- (NSString *)md5sumFromString:(NSString *)string {
    unsigned char digest[CC_MD5_DIGEST_LENGTH], i;
    CC_MD5([string UTF8String], (CC_LONG)[string lengthOfBytesUsingEncoding:NSUTF8StringEncoding], digest);
    NSMutableString *ms = [NSMutableString string];
    for (i=0;i<CC_MD5_DIGEST_LENGTH;i++) {
        [ms appendFormat: @"%02x", (int)(digest[i])];
    }
    return [ms copy];
}


-(NSCache *)cache
{
    if (!_cache) {
        _cache = [[NSCache alloc] init];
    }
    return _cache;
}

@end
