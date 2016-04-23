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
#import "SettingsController.h"
#import <PINCache.h>
#include <CommonCrypto/CommonDigest.h>
#import "MusicPlayer.h"

@interface GetCover () <NSURLSessionDelegate>
@property (nonatomic) PINDiskCache *imagesCache;
@property (nonatomic) ItunesSearch *itunesSearch;
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
    if ([[MusicPlayer sharedPlayer] currentTrackCover]) {
        handler([[MusicPlayer sharedPlayer] currentTrackCover]);
        if ([self.delegate respondsToSelector:@selector(trackInfoShouldBeDisplayed)]) {
            [self.delegate trackInfoShouldBeDisplayed];
        }
    } else {
        NSImage *cover = [self cachedCoverImageForTrack:track];
        if (cover) {
            handler(cover);
            if ([self.delegate respondsToSelector:@selector(trackInfoShouldBeDisplayed)]) {
                [self.delegate trackInfoShouldBeDisplayed];
            }
            return;
        }
        if ([self.delegate respondsToSelector:@selector(trackInfoShouldBeRemoved)]) {
            [self.delegate trackInfoShouldBeRemoved];
        }
        __weak typeof(self) weakSelf = self;
        if ([FXReachability sharedInstance].isReachable) {
            [self getCoverURLFromiTunesAndSetItAsCoverForTrack:track inCompletionHandler:^(NSImage *cover) {
                handler(cover);
                if ([weakSelf.delegate respondsToSelector:@selector(trackInfoShouldBeDisplayed)]) {
                    [weakSelf.delegate trackInfoShouldBeDisplayed];
                }
            }];
        }
        else {
            NSImage *defaultCover = [self defaultCover];
            handler(defaultCover);
        }
    }
}

-(void)getCoverURLFromLastFmAndSetItAsCoverForTrack:(Track *)track inCompletionHandler:(void(^)(NSImage *cover))handler
{
    __weak typeof(self) weakSelf = self;
    [self getInfoWithLastFMForTrack:track withCompletionHandler:^(NSString *urlString) {
        if (urlString.length) {
            [weakSelf getCoverForTrack:track fromString:urlString andCompletionHandler:^(NSImage *cover) {
                handler(cover);
            }];
        } else {
            handler([self defaultCover]);
        }
    }];
}

-(void)getCoverURLFromiTunesAndSetItAsCoverForTrack:(Track *)track inCompletionHandler:(void(^)(NSImage *cover))handler
{
    __weak typeof(self) weakSelf = self;
    [self.itunesSearch getAlbumWithArtist:track.artist andName:track.album limitOrNil:@20 successHandler:^(NSArray *result) {
        NSString *coverURL;
        for (NSDictionary *singleResult in result) {
            if ([singleResult objectForKey:@"artworkUrl100"]) {
                coverURL = [singleResult objectForKey:@"artworkUrl100"];
                break;
            }
        }
        if (coverURL) {
            coverURL = [coverURL stringByReplacingOccurrencesOfString:@"100x100" withString:@"225x225"];
            [weakSelf getCoverForTrack:track fromString:coverURL andCompletionHandler:^(NSImage *cover) {
                handler(cover);
            }];
        } else {
            [weakSelf getCoverURLFromLastFmAndSetItAsCoverForTrack:track inCompletionHandler:^(NSImage *cover) {
                handler(cover);
            }];
        }
        if ([SettingsController sharedSettings].debugMode) {
            NSLog(@"coverURL from iTunes = %@", coverURL);
        }
    } failureHandler:^(NSError *error) {
        [weakSelf getCoverURLFromLastFmAndSetItAsCoverForTrack:track inCompletionHandler:^(NSImage *cover) {
            handler(cover);
        }];
    }];
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
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
    __weak typeof(self) weakSelf = self;
    NSURLSessionDownloadTask *artworkDownloadTask = [session downloadTaskWithRequest:albumArtworkRequest completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSImage *artwork = [[NSImage alloc] initWithContentsOfURL:location];
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf saveCoverImage:artwork forTrack:track];
            handler(artwork);
        });
    }];
    [artworkDownloadTask resume];
    [session finishTasksAndInvalidate];
}

-(NSImage *)defaultCover
{
    if ([SettingsController sharedSettings].debugMode) {
        NSLog(@"Using default cover");
    }
    if ([self.delegate respondsToSelector:@selector(trackInfoShouldBeDisplayed)]) {
        [self.delegate trackInfoShouldBeDisplayed];
    }
    return [NSImage imageNamed:@"nocover"];
}

#pragma mark - NSURLSession
- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(nullable NSError *)error
{
    if (error && [SettingsController sharedSettings].debugMode) {
        NSLog(@"Session invalid: %@", error.localizedDescription);
    }
    [session invalidateAndCancel];
    session = nil;
}

#pragma mark - Cache

-(void)saveCoverImage:(NSImage *)image forTrack:(Track *)track
{
    NSString *key = [self md5sumFromString: [NSString stringWithFormat:@"%@%@", track.artist, track.album]];
    [self.imagesCache setObject:image forKey:key];
    if ([SettingsController sharedSettings].debugMode) {
        NSLog(@"saving image to cache for key %@", key);
    }
}

-(NSImage *)cachedCoverImageForTrack:(Track *)track
{
    NSString *key = [self md5sumFromString:[NSString stringWithFormat:@"%@%@", track.artist, track.album]];
    if ([self.imagesCache objectForKey:key]) {
        if ([SettingsController sharedSettings].debugMode) {
            NSLog(@"Cover image for key %@", key);
        }
        return (NSImage *)[self.imagesCache objectForKey:key];
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


#pragma mark - Getters

-(PINDiskCache *)imagesCache
{
    if (!_imagesCache) {
        _imagesCache = [[PINDiskCache alloc] initWithName:@"imageCache"];
        _imagesCache.byteLimit = 1024 * 1024;
    }
    return _imagesCache;
}


-(ItunesSearch *)itunesSearch
{
    if (!_itunesSearch) {
        _itunesSearch = [[ItunesSearch alloc] init];
    }
    return _itunesSearch;
}

@end
