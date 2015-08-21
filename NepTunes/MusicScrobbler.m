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

@interface MusicScrobbler ()

@property NSUInteger scrobbleTryCounter;
@property NSUInteger nowPlayingTryCounter;
@property NSUInteger loveSongTryCounter;



@end

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
    //NSLog(@"Scrobbling method called");
    if (self.iTunes.isRunning) {
        if (self.iTunes.playerState == iTunesEPlSPlaying && self.scrobbler.session) {
            //NSLog(@"iTunes is running and playing music. User logged in");

            //when iTunes is playing right now and when there is user logged in
            if (!self.iTunes.currentTrack.name && !self.iTunes.currentTrack.artist) {
                //NSLog(@"Scrobbling method \"alternative\" chosen");
                [self.scrobbler sendScrobbledTrack:self.trackName
                                          byArtist:self.artist
                                           onAlbum:self.album
                                      withDuration:self.duration
                                       atTimestamp:(int)[[NSDate date] timeIntervalSince1970]
                                    successHandler:^(NSDictionary *result) {
                                        //succesHandler - nothing to do
                                        //NSLog(@"%@ by %@ alternatively scrobbled!", self.trackName, self.artist);
                                        self.scrobbleTryCounter = 0;
                                    } failureHandler:^(NSError *error) {
                                        if (error) {
                                            //NSLog(@"Error! %@ %lu. try",error.localizedDescription, (signed long)self.scrobbleTryCounter + 1);
                                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                                if (++self.scrobbleTryCounter < 3) {
                                                    [self scrobbleCurrentTrack];
                                                } else self.scrobbleTryCounter = 0;
                                                
                                            });
                                        }
                                    }];
            }
            else {
                //NSLog(@"Scrobbling method \"normal\" chosen");
                [self.scrobbler sendScrobbledTrack:self.iTunes.currentTrack.name
                                          byArtist:self.iTunes.currentTrack.artist
                                           onAlbum:self.iTunes.currentTrack.album
                                      withDuration:self.iTunes.currentTrack.duration
                                       atTimestamp:(int)[[NSDate date] timeIntervalSince1970]
                                    successHandler:^(NSDictionary *result)
                                     {
                                         //succesHandler - nothing to do
                                         //NSLog(@"%@ by %@ normally scrobbled!", self.iTunes.currentTrack.name, self.iTunes.currentTrack.artist);
                                         self.scrobbleTryCounter = 0;
                                     } failureHandler:^(NSError *error) {
                                         if (error) {
                                             //NSLog(@"Error! %@ %lu. try", error.localizedDescription, (signed long)self.scrobbleTryCounter + 1);
                                             dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                                 if (++self.scrobbleTryCounter < 3) {
                                                     [self scrobbleCurrentTrack];
                                                 } else self.scrobbleTryCounter = 0;
                                                 
                                             });
                                         }
                                     }];
            }
        }
    }
}

/*----------------------------------------------------------------------------------------------------------*/


-(void)nowPlayingCurrentTrack
{
    if (self.iTunes.isRunning) {
        if (self.scrobbler.session && self.iTunes.playerState == iTunesEPlSPlaying) {
            
            if (!self.iTunes.currentTrack.name && !self.iTunes.currentTrack.artist) {
                [self.scrobbler sendNowPlayingTrack:self.trackName
                                           byArtist:self.artist
                                            onAlbum:self.album
                                       withDuration:self.duration / 2
                                     successHandler:^(NSDictionary *result) {
                                         //succesHandler - nothing to do
                                         self.nowPlayingTryCounter = 0;
                                     } failureHandler:^(NSError *error) {
                                         if (error.code == -1001) {
                                             dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                                 if (++self.nowPlayingTryCounter < 3) {
                                                     [self nowPlayingCurrentTrack];
                                                 }
                                                 else self.nowPlayingTryCounter = 0;
                                             });
                                         }
                                     }];
            }
            else {
                
                [[LastFm sharedInstance] sendNowPlayingTrack:self.iTunes.currentTrack.name
                                                    byArtist:self.iTunes.currentTrack.artist
                                                     onAlbum:self.iTunes.currentTrack.album
                                                withDuration:self.iTunes.currentTrack.duration / 2
                                              successHandler:^(NSDictionary *result) {
                                                  //succesHandler - nothing to do
                                              } failureHandler:^(NSError *error) {
                                                  if (error.code == -1001) {
                                                      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                                          if (++self.nowPlayingTryCounter < 3) {
                                                              [self nowPlayingCurrentTrack];
                                                          }
                                                          else self.nowPlayingTryCounter = 0;
                                                          
                                                      });
                                                  }
                                              }];
            }
        }
    }
}

/*----------------------------------------------------------------------------------------------------------*/

-(void)loveCurrentTrackWithCompletionHandler:(void(^)(void))completion
{
    if (self.scrobbler.session && self.iTunes.isRunning) {
        if (!self.iTunes.currentTrack.name && !self.iTunes.currentTrack.album) {
            [self.scrobbler loveTrack:self.trackName artist:self.artist successHandler:^(NSDictionary *result) {
                if (completion) {
                    completion();
                }
                self.loveSongTryCounter = 0;
            } failureHandler:^(NSError *error) {
                if (error.code == -1001 || error.code == 16) {
                    if (++self.loveSongTryCounter < 3) {
                        [self loveCurrentTrackWithCompletionHandler:completion];
                    }
                    else self.loveSongTryCounter = 0;
                }
            }];
        }
        else {
            [self.scrobbler loveTrack:self.iTunes.currentTrack.name artist:self.iTunes.currentTrack.artist successHandler:^(NSDictionary *result) {
                if (completion) {
                    completion();
                }
                self.loveSongTryCounter = 0;
            } failureHandler:^(NSError *error) {
                if (error.code == -1001 || error.code == 16) {
                    if (++self.loveSongTryCounter < 3) {
                        [self loveCurrentTrackWithCompletionHandler:completion];
                    }
                    else self.loveSongTryCounter = 0;
                    
                }
            }];
        }
        
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
        _scrobbler.timeoutInterval = 20;
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
    _artist = [infoAboutCurrentTrack objectForKey:@"Artist"];
    _album = [infoAboutCurrentTrack objectForKey:@"Album"];
    _trackName = [infoAboutCurrentTrack objectForKey:@"Name"];
    self.duration = [[infoAboutCurrentTrack objectForKey:@"Total Time"] doubleValue] / 1000;
}

-(void)setDuration:(double)duration
{
    _duration = duration;
    if (duration == 0) {
        _scrobbler.timeoutInterval = 5.0f;
    }
    else {
    _scrobbler.timeoutInterval = duration / 6 - 2;
    }
    //NSLog(@"timeout interval for scrobbler == %f", _scrobbler.timeoutInterval);

}


@end
