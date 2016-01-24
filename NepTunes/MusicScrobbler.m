//
//  MusicScrobbler.m
//  NepTunes
//
//  Created by rurza on 04/07/15.
//  Copyright (c) 2015 micropixels. All rights reserved.
//


#import "MusicScrobbler.h"
#import "SavedSong.h"
#import "OfflineScrobbler.h"
#import "SettingsController.h"

static NSString *const kAPIKey = @"3a26162db61a3c47204396401baf2bf7";
static NSString *const kAPISecret = @"679d4509ae07a46400dd27a05c7e9885";

@interface MusicScrobbler ()

@property (nonatomic) NSUInteger loveSongTryCounter;

@end

@implementation MusicScrobbler

+(MusicScrobbler *)sharedScrobbler
{
    static MusicScrobbler *sharedScrobbler = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedScrobbler = [[MusicScrobbler alloc] init];
        sharedScrobbler.lastfmCache = [[LastFmCache alloc] init];
        sharedScrobbler.username = [SettingsController sharedSettings].username;
        [OfflineScrobbler sharedInstance];
    });
    return sharedScrobbler;
}

/*----------------------------------------------------------------------------------------------------------*/
-(void)scrobbleOfflineTrack:(Song *)song atTimestamp:(NSTimeInterval)timestamp withTryCounter:(NSUInteger)tryCounter
{
    __weak typeof(self) weakSelf = self;
    [self.scrobbler sendScrobbledTrack:song.trackName byArtist:song.artist onAlbum:song.album withDuration:song.duration atTimestamp:timestamp successHandler:^(NSDictionary *result) {
        [weakSelf.delegate songWasSuccessfullyScrobbled:song];
    } failureHandler:^(NSError *error) {
        if (error.code == -1001) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((1 * tryCounter) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (tryCounter <= 3) {
                    [weakSelf scrobbleOfflineTrack:song atTimestamp:timestamp withTryCounter:tryCounter + 1];
                }
            });
        }
    }];
}

-(void)scrobbleOfflineTrack:(SavedSong *)song
{
    [self scrobbleOfflineTrack:song atTimestamp:[song.date timeIntervalSince1970] withTryCounter:1];
}

#pragma mark - Last.fm related methods

#pragma mark - Scrobble online
-(void)scrobbleCurrentTrack
{
    if (self.iTunes.isRunning) {
        if (self.iTunes.playerState == iTunesEPlSPlaying && self.scrobbler.session) {
            [self scrobbleTrack:self.currentTrack atTimestamp:[[NSDate date] timeIntervalSince1970] withTryCounter:1];
        }
    }
}

-(void)scrobbleTrack:(Song *)track atTimestamp:(NSTimeInterval)timestamp withTryCounter:(NSUInteger)tryCounter
{
    if (self.iTunes.isRunning && self.iTunes.playerState == iTunesEPlSPlaying && self.scrobbler.session) {
        __weak typeof(self) weakSelf = self;
        [self.scrobbler sendScrobbledTrack:track.trackName byArtist:track.artist onAlbum:track.album withDuration:track.duration atTimestamp:timestamp successHandler:^(NSDictionary *result) {
        } failureHandler:^(NSError *error) {
            if ([OfflineScrobbler sharedInstance].areWeOffline) {
                [[OfflineScrobbler sharedInstance] saveSong:weakSelf.currentTrack];
            } else if (error.code == -1001) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    if (tryCounter <= 3) {
                        [weakSelf scrobbleTrack:track atTimestamp:timestamp withTryCounter:(tryCounter + 1)];
                    } else {
                        NSLog(@"Error, track not scrobbled: %@", [error localizedDescription]);
                    }
                });
            }
        }];
    }
}

/*----------------------------------------------------------------------------------------------------------*/


-(void)nowPlayingCurrentTrack
{
    [self nowPLayingTrack:self.currentTrack withTryCounter:1];
}

-(void)nowPLayingTrack:(Song *)track withTryCounter:(NSUInteger)tryCounter
{
    if (self.iTunes.isRunning) {
        if (self.scrobbler.session && self.iTunes.playerState == iTunesEPlSPlaying) {
            __weak typeof(self) weakSelf = self;
            [self.scrobbler sendNowPlayingTrack:track.trackName byArtist:track.artist onAlbum:track.album withDuration:track.duration successHandler:^(NSDictionary *result) {
                
            } failureHandler:^(NSError *error) {
                if ([OfflineScrobbler sharedInstance].areWeOffline) {
                } else if (error.code == -1001) {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        if (tryCounter <= 3) {
                            [weakSelf nowPLayingTrack:track withTryCounter:(tryCounter + 1)];
                        }
                    });
                }
            }];
        }
    }
}

/*----------------------------------------------------------------------------------------------------------*/

-(void)loveCurrentTrackWithCompletionHandler:(void(^)(void))completion
{
    [self loveTrack:self.currentTrack withTryCounter:1 withCompletionHandler:completion];
}

-(void)loveTrack:(Song *)track withTryCounter:(NSUInteger)tryCounter withCompletionHandler:(void(^)(void))completion
{
    if (self.scrobbler.session && self.iTunes.isRunning) {
        __weak typeof(self) weakSelf = self;
        [self.scrobbler loveTrack:track.trackName artist:track.artist successHandler:^(NSDictionary *result) {
            completion();
        } failureHandler:^(NSError *error) {
            if (error.code == -1001 || error.code == 16) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    if (tryCounter <= 3) {
                        [weakSelf loveTrack:track withTryCounter:(tryCounter + 1) withCompletionHandler:completion];
                    } else {
                        [weakSelf sendNotificationToUserThatLoveSongFailedWithError:error];
                    }
                });
            }
        }];
    }
}

-(void)sendNotificationToUserThatLoveSongFailedWithError:(NSError *)error
{
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title = NSLocalizedString(@"Houston, we got a problem!", nil);
    notification.informativeText = [NSString stringWithFormat:@"%@ %@", error.localizedDescription, @"Maybe Last.fm servers are down?"];
    [notification setDeliveryDate:[NSDate dateWithTimeInterval:1 sinceDate:[NSDate date]]];
    [[NSUserNotificationCenter defaultUserNotificationCenter] scheduleNotification:notification];
}


/*----------------------------------------------------------------------------------------------------------*/

-(void)logInWithCredentials:(NSDictionary *)info
{
    [SettingsController sharedSettings].session = info[@"key"];
    
    // Also set the session of the LastFm object
    self.scrobbler.session = info[@"key"];
    self.scrobbler.username = info[@"name"];
}

-(void)logOut
{
    [self.scrobbler logout];
    [SettingsController sharedSettings].session = nil;
    [SettingsController sharedSettings].username = nil;
}

#pragma mark - Overrided Methods

-(NSString *)description
{
    return [NSString stringWithFormat:@"scrobbler: username = %@, iTunes: currentTrack = %@, duration = %f", self.scrobbler.username, self.iTunes.currentTrack.name, self.iTunes.currentTrack.duration];
}

#pragma mark - Getters

-(LastFm *)scrobbler
{
    if (!_scrobbler) {
        _scrobbler = [LastFm sharedInstance];
        _scrobbler.apiKey = kAPIKey;
        _scrobbler.apiSecret = kAPISecret;
        _scrobbler.session = [SettingsController sharedSettings].session;
        _scrobbler.username = [SettingsController sharedSettings].username;
        _scrobbler.cacheDelegate = self.lastfmCache;
        _scrobbler.timeoutInterval = 10;
    }
    return _scrobbler;
}


-(iTunesApplication *)iTunes
{
    if (!_iTunes) {
        _iTunes = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
    }
    return _iTunes;
}

#pragma mark - Setters

-(void)setInfoAboutCurrentTrack:(NSDictionary *)infoAboutCurrentTrack
{
    _infoAboutCurrentTrack = infoAboutCurrentTrack;
    NSString *artist = [infoAboutCurrentTrack objectForKey:@"Artist"];
    NSString *album = [infoAboutCurrentTrack objectForKey:@"Album"];
    NSString *trackName = [infoAboutCurrentTrack objectForKey:@"Name"];
    double duration = [[infoAboutCurrentTrack objectForKey:@"Total Time"] doubleValue] / 1000;
    self.currentTrack = [[Song alloc] initWithTrackName:trackName artist:artist album:album andDuration:duration];
}

#pragma mark - Offline scrobbler


@end