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
#import "UserNotificationsController.h"
#import "MusicController.h"

static NSString *const kAPIKey = @"3a26162db61a3c47204396401baf2bf7";
static NSString *const kAPISecret = @"679d4509ae07a46400dd27a05c7e9885";

@interface MusicScrobbler ()
@property (nonatomic) MusicController *musicController;
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
    if (self.musicController.isiTunesRunning) {
        if (self.musicController.playerState == iTunesEPlSPlaying && self.scrobbler.session) {
            [self scrobbleTrack:self.currentTrack atTimestamp:[[NSDate date] timeIntervalSince1970] withTryCounter:1];
        }
    }
}

-(void)scrobbleTrack:(Song *)track atTimestamp:(NSTimeInterval)timestamp withTryCounter:(NSUInteger)tryCounter
{
    if (self.musicController.isiTunesRunning && self.musicController.playerState == iTunesEPlSPlaying && self.scrobbler.session) {
        __weak typeof(self) weakSelf = self;
        [self.scrobbler sendScrobbledTrack:track.trackName byArtist:track.artist onAlbum:track.album withDuration:track.duration atTimestamp:timestamp successHandler:^(NSDictionary *result) {
            if ([OfflineScrobbler sharedInstance].lastFmIsDown) {
                [OfflineScrobbler sharedInstance].lastFmIsDown = NO;
            }
#if DEBUG
                NSLog(@"%@ scrobbled!", track);
#endif
        } failureHandler:^(NSError *error) {
            if ([OfflineScrobbler sharedInstance].areWeOffline) {
                [[OfflineScrobbler sharedInstance] saveSong:track];
            } else if (error.code == -1001 || error.code == kLastFmerrorCodeServiceError) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    if (tryCounter <= 3) {
                        [weakSelf scrobbleTrack:track atTimestamp:timestamp withTryCounter:(tryCounter + 1)];
                    }
                });
            }
            else {
                [[UserNotificationsController sharedNotificationsController] displayNotificationThatTrackCanNotBeScrobbledWithError:error];
                if (error.code == kLastFmErrorCodeServiceOffline) {
                    [OfflineScrobbler sharedInstance].lastFmIsDown = YES;
                    [[OfflineScrobbler sharedInstance] saveSong:track];
                } else if (error.code == kLastFmErrorCodeInvalidSession) {
                    //if session is broken and user was logged out
                    [[OfflineScrobbler sharedInstance] saveSong:track];
                }
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
    if (self.musicController.isiTunesRunning) {
        if (self.scrobbler.session && self.musicController.playerState == iTunesEPlSPlaying) {
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

-(void)loveCurrentTrackWithCompletionHandler:(void(^)(Song *track))completion
{
    [self loveTrack:self.currentTrack withTryCounter:1 withCompletionHandler:completion];
}

-(void)loveTrack:(Song *)track withTryCounter:(NSUInteger)tryCounter withCompletionHandler:(void(^)(Song *track))completion
{
    if (self.scrobbler.session && self.musicController.isiTunesRunning) {
        __weak typeof(self) weakSelf = self;
        [self.scrobbler loveTrack:track.trackName artist:track.artist successHandler:^(NSDictionary *result) {
#if DEBUG
                NSLog(@"%@ loved!", track);
#endif
            if (completion) {
                completion(track);
            }
        } failureHandler:^(NSError *error) {
            if (error.code == -1001 || error.code == kLastFmerrorCodeServiceError) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    if (tryCounter <= 3) {
                        [weakSelf loveTrack:track withTryCounter:(tryCounter + 1) withCompletionHandler:completion];
                    } else {
                        [[UserNotificationsController sharedNotificationsController] displayNotificationThatLoveSongFailedWithError:error];
                    }
                });
            } else {
                [[UserNotificationsController sharedNotificationsController] displayNotificationThatLoveSongFailedWithError:error];
            }
        }];
    }
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
}

#pragma mark - Overrided Methods

-(NSString *)description
{
    return [NSString stringWithFormat:@"scrobbler: username = %@, iTunes: currentTrack = %@, duration = %f", self.scrobbler.username, self.musicController.iTunes.currentTrack.name, self.musicController.iTunes.currentTrack.duration];
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


#pragma mark - Update Track Info
-(void)updateCurrentTrackWithUserInfo:(NSDictionary *)userInfo
{
    NSString *artist = [userInfo objectForKey:@"Artist"];
    NSString *album = [userInfo objectForKey:@"Album"];
    NSString *trackName = [userInfo objectForKey:@"Name"];
    double duration = [[userInfo objectForKey:@"Total Time"] doubleValue] / 1000;
    if (artist.length && album.length && trackName.length) {
        self.currentTrack = [[Song alloc] initWithTrackName:trackName artist:artist album:album andDuration:duration];
    } else {
        self.currentTrack = nil;
    }
}

#pragma mark - Music controller
-(MusicController *)musicController
{
    if (!_musicController) {
        _musicController = [MusicController sharedController];
    }
    return _musicController;
}

@end
