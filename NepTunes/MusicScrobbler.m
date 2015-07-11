//
//  MusicScrobbler.m
//  NepTunes
//
//  Created by rurza on 04/07/15.
//  Copyright (c) 2015 micropixels. All rights reserved.
//


#import "MusicScrobbler.h"

static NSString *const kUsernameKey = @"pl.micropixels.neptunes.usernameKey";
static NSString *const kSessionKey = @"pl.micropixels.neptunes.sessionKey";
static NSString *const kAPIKey = @"3a26162db61a3c47204396401baf2bf7";
static NSString *const kAPISecret = @"679d4509ae07a46400dd27a05c7e9885";

@implementation MusicScrobbler

+(MusicScrobbler *)sharedScrobbler
{
    static MusicScrobbler *sharedScrobbler = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedScrobbler = [[MusicScrobbler alloc] init];
        sharedScrobbler.lastfmCache = [[LastFmCache alloc] init];
    });
    return sharedScrobbler;
}

/*----------------------------------------------------------------------------------------------------------*/


#pragma mark - Last.fm related methods

-(void)scrobbleCurrentTrack
{
    if (self.iTunes.playerState == iTunesEPlSPlaying && self.scrobbler.session) {
        //when iTunes is playing right now and when there is user logged in
        __weak MusicScrobbler *weakSelf = self;
        [self.scrobbler sendScrobbledTrack:self.iTunes.currentTrack.name
                                  byArtist:self.iTunes.currentTrack.artist
                                   onAlbum:self.iTunes.currentTrack.album
                              withDuration:self.iTunes.currentTrack.duration
                               atTimestamp:(int)[[NSDate date] timeIntervalSince1970]
                            successHandler:^(NSDictionary *result) {
                                //succesHandler - nothing to do
                            } failureHandler:^(NSError *error) {
                                if (error.code == -1001) {
                                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                        [weakSelf scrobbleCurrentTrack];
                                        
                                    });
                                }
                            }];
    }
    
}

/*----------------------------------------------------------------------------------------------------------*/


-(void)nowPlayingCurrentTrack
{
    if (self.scrobbler.session && self.iTunes.playerState == iTunesEPlSPlaying) {
        __weak MusicScrobbler *weakSelf = self;
        [[LastFm sharedInstance] sendNowPlayingTrack:self.iTunes.currentTrack.name
                                            byArtist:self.iTunes.currentTrack.artist
                                             onAlbum:self.iTunes.currentTrack.album
                                        withDuration:self.iTunes.currentTrack.duration / 2
                                      successHandler:^(NSDictionary *result) {
                                          //succesHandler - nothing to do
                                      } failureHandler:^(NSError *error) {
                                          if (error.code == -1001) {
                                              dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                                  [weakSelf nowPlayingCurrentTrack];
                                                  
                                              });
                                          }
                                      }];
    }
    
}

/*----------------------------------------------------------------------------------------------------------*/

-(void)loveCurrentTrackWithCompletionHandler:(void(^)(void))completion
{
    if (self.scrobbler.session) {
        [self.scrobbler loveTrack:self.iTunes.currentTrack.name artist:self.iTunes.currentTrack.artist successHandler:^(NSDictionary *result) {
            if (completion) {
                completion();
            }
        } failureHandler:^(NSError *error) {
            if (error.code == -1001 || error.code == 16) {
                [self loveCurrentTrackWithCompletionHandler:completion];
            }
        }];
    }
}

/*----------------------------------------------------------------------------------------------------------*/

-(void)logInWithCredentials:(NSDictionary *)info
{
    [[NSUserDefaults standardUserDefaults] setObject:info[@"key"] forKey:kSessionKey];
    [[NSUserDefaults standardUserDefaults] setObject:info[@"name"] forKey:kUsernameKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Also set the session of the LastFm object
    self.scrobbler.session = info[@"key"];
    self.scrobbler.username = info[@"name"];
}

-(void)logOut
{
    [self.scrobbler logout];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kSessionKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kUsernameKey];
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
        _scrobbler.session = [[NSUserDefaults standardUserDefaults] stringForKey:kSessionKey];
        _scrobbler.username = [[NSUserDefaults standardUserDefaults] stringForKey:kUsernameKey];
        _scrobbler.cacheDelegate = self.lastfmCache;
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


@end
