//
//  MusicScrobbler.m
//  NepTunes
//
//  Created by rurza on 04/07/15.
//  Copyright (c) 2015 micropixels. All rights reserved.
//


#import "MusicScrobbler.h"
#import "SavedTrack.h"
#import "OfflineScrobbler.h"
#import "SettingsController.h"
#import "UserNotificationsController.h"
#import "MusicController.h"
#import "AppDelegate.h"
#import "CoverWindowController.h"
#import "GetCover.h"

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
    });
    return sharedScrobbler;
}

-(instancetype)init
{
    if (self = [super init]) {
        self.lastfmCache = [[LastFmCache alloc] init];
        self.username = [SettingsController sharedSettings].username;
        [OfflineScrobbler sharedInstance];
    }
    return self;
}

/*----------------------------------------------------------------------------------------------------------*/

-(void)scrobbleOfflineTrack:(SavedTrack *)track
{
    __weak typeof(self) weakSelf = self;
    [self scrobbleTrack:track atTimestamp:[track.date timeIntervalSince1970] withTryCounter:1 withSuccessHandler:^{
        [weakSelf.delegate trackWasSuccessfullyScrobbled:track];
    }];
}

#pragma mark - Last.fm related methods

#pragma mark - Scrobble online
-(void)scrobbleCurrentTrack
{
    if (self.musicController.isiTunesRunning) {
        [self scrobbleTrack:self.currentTrack atTimestamp:[[NSDate date] timeIntervalSince1970] withTryCounter:1 withSuccessHandler:^{
            [((AppDelegate *)[NSApplication sharedApplication].delegate).menuController blinkMenuIcon];
        }];
    }
}

-(void)scrobbleTrack:(Track *)track atTimestamp:(NSTimeInterval)timestamp withTryCounter:(NSUInteger)tryCounter withSuccessHandler:(void(^)(void))successHandler
{
    if (self.musicController.isiTunesRunning && self.musicController.playerState == iTunesEPlSPlaying && [SettingsController sharedSettings].username) {
        __weak typeof(self) weakSelf = self;
        [self.scrobbler sendScrobbledTrack:track.trackName byArtist:track.artist onAlbum:track.album withDuration:track.duration atTimestamp:timestamp successHandler:^(NSDictionary *result) {
            if ([OfflineScrobbler sharedInstance].lastFmIsDown) {
                [OfflineScrobbler sharedInstance].lastFmIsDown = NO;
            }
            if ([SettingsController sharedSettings].debugMode) {
                NSLog(@"%@ scrobbled!", track);
            }
            if (successHandler) {
                successHandler();
            }
        } failureHandler:^(NSError *error) {
            
            //if session is broken and user was logged out
            if (error.code == -1001 || error.code == kLastFmerrorCodeServiceError) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    if (tryCounter <= 3) {
                        [weakSelf scrobbleTrack:track atTimestamp:timestamp withTryCounter:(tryCounter + 1) withSuccessHandler:successHandler];
                        if ([SettingsController sharedSettings].debugMode) {
                            NSLog(@"Cannot scrobble. %@. Trying again", error.localizedDescription);
                        }

                    }
                });
            }
            else {
                if (![OfflineScrobbler sharedInstance].userWasLoggedOut && ![OfflineScrobbler sharedInstance].areWeOffline) {
                    [[UserNotificationsController sharedNotificationsController] displayNotificationThatTrackCanNotBeScrobbledWithError:error];
                }
                //if there are some problems with with Last.fm service and the user isn't logged in
                if (error.code == kLastFmErrorCodeServiceOffline && ![OfflineScrobbler sharedInstance].userWasLoggedOut) {
                    [OfflineScrobbler sharedInstance].lastFmIsDown = YES;
                    [[OfflineScrobbler sharedInstance] saveTrack:track];
                    NSLog(@"Some issues with Last.fm service.");

                }
                if ([OfflineScrobbler sharedInstance].areWeOffline || [SettingsController sharedSettings].userWasLoggedOut) {
                    [[OfflineScrobbler sharedInstance] saveTrack:track];
                    if ([SettingsController sharedSettings].debugMode) {
                        NSLog(@"Saving track for offline scrobbling.");
                    }
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

-(void)nowPLayingTrack:(Track *)track withTryCounter:(NSUInteger)tryCounter
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

-(void)loveCurrentTrackWithCompletionHandler:(void(^)(Track *track, NSImage *artwork))completion
{
    [self loveTrack:self.currentTrack withTryCounter:1 withCompletionHandler:completion];
}

-(void)loveTrack:(Track *)track withTryCounter:(NSUInteger)tryCounter withCompletionHandler:(void(^)(Track *track, NSImage *artwork))completion
{
    if (self.scrobbler.session && self.musicController.isiTunesRunning) {
        __weak typeof(self) weakSelf = self;
        [self.scrobbler loveTrack:track.trackName artist:track.artist successHandler:^(NSDictionary *result) {
            if ([SettingsController sharedSettings].debugMode) {
                NSLog(@"%@ loved!", track);
            }
            [[GetCover sharedInstance] getCoverWithTrack:track withCompletionHandler:^(NSImage *cover) {
                completion(track, cover);
            }];           
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
        self.currentTrack = [[Track alloc] initWithTrackName:trackName artist:artist album:album andDuration:duration];
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
