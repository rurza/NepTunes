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

static NSString *const kAPIKey = @"3a26162db61a3c47204396401baf2bf7";
static NSString *const kAPISecret = @"679d4509ae07a46400dd27a05c7e9885";

@interface MusicScrobbler ()

@property (nonatomic) NSUInteger scrobbleTryCounter;
@property (nonatomic) NSUInteger nowPlayingTryCounter;
@property (nonatomic) NSUInteger loveSongTryCounter;

@property (nonatomic) BOOL offlineScrobbler;

@end

@implementation MusicScrobbler

+(MusicScrobbler *)sharedScrobbler
{
    static MusicScrobbler *sharedScrobbler = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedScrobbler = [[MusicScrobbler alloc] init];
        sharedScrobbler.lastfmCache = [[LastFmCache alloc] init];
        sharedScrobbler.username = [[NSUserDefaults standardUserDefaults] objectForKey:kUsernameKey];
    });
    return sharedScrobbler;
}

/*----------------------------------------------------------------------------------------------------------*/
-(void)scrobbleTrack:(Song *)song atTimestamp:(NSTimeInterval)timestamp
{
    __weak typeof(self) weakSelf = self;
    [self.scrobbler sendScrobbledTrack:song.trackName byArtist:song.artist onAlbum:song.album withDuration:song.duration atTimestamp:timestamp successHandler:^(NSDictionary *result) {
        [weakSelf.delegate songWasSuccessfullyScrobbled:song];
    } failureHandler:^(NSError *error) {
        
    }];
}

-(void)scrobbleOfflineTrack:(SavedSong *)song
{
    [self scrobbleTrack:song atTimestamp:[song.date timeIntervalSince1970]];
}

#pragma mark - Last.fm related methods

-(void)scrobbleCurrentTrack
{
    if (self.iTunes.isRunning) {
        if (self.iTunes.playerState == iTunesEPlSPlaying && self.scrobbler.session) {
            __weak typeof(self) weakSelf = self;
                [self.scrobbler sendScrobbledTrack:self.currentTrack.trackName
                                          byArtist:self.currentTrack.artist
                                           onAlbum:self.currentTrack.album
                                      withDuration:self.currentTrack.duration
                                       atTimestamp:(int)[[NSDate date] timeIntervalSince1970]
                                    successHandler:^(NSDictionary *result) {
                                        weakSelf.scrobbleTryCounter = 0;
                                    } failureHandler:^(NSError *error) {
                                        if (error) {
                                            if ([OfflineScrobbler sharedInstance].areWeOffline) {
                                                [[OfflineScrobbler sharedInstance] saveSong:weakSelf.currentTrack];
                                            }
                                        }
                                    }];
        }
    }
}

/*----------------------------------------------------------------------------------------------------------*/


-(void)nowPlayingCurrentTrack
{
    if (self.iTunes.isRunning) {
        if (self.scrobbler.session && self.iTunes.playerState == iTunesEPlSPlaying) {
            __weak typeof(self) weakSelf = self;
                [self.scrobbler sendNowPlayingTrack:self.currentTrack.trackName
                                           byArtist:self.currentTrack.artist
                                            onAlbum:self.currentTrack.album
                                       withDuration:self.currentTrack.duration / 2
                                     successHandler:^(NSDictionary *result) {
                                         self.nowPlayingTryCounter = 0;
                                     } failureHandler:^(NSError *error) {
                                         if (error.code == -1001) {
                                             dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                                 if (++weakSelf.nowPlayingTryCounter < 3) {
                                                     [weakSelf nowPlayingCurrentTrack];
                                                 }
                                                 else weakSelf.nowPlayingTryCounter = 0;
                                             });
                                         }
                                     }];
        }
    }
}

/*----------------------------------------------------------------------------------------------------------*/

-(void)loveCurrentTrackWithCompletionHandler:(void(^)(void))completion
{
    if (self.scrobbler.session && self.iTunes.isRunning) {
        __weak typeof(self) weakSelf = self;
        [self.scrobbler loveTrack:self.currentTrack.trackName artist:self.currentTrack.artist successHandler:^(NSDictionary *result) {
                if (completion) {
                    completion();
                }
                weakSelf.loveSongTryCounter = 0;
            } failureHandler:^(NSError *error) {
                if (error.code == -1001 || error.code == 16) {
                    if (++weakSelf.loveSongTryCounter < 3) {
                        [weakSelf loveCurrentTrackWithCompletionHandler:completion];
                    }
                    else weakSelf.loveSongTryCounter = 0;
                }
            }];
    }
}

/*----------------------------------------------------------------------------------------------------------*/

-(void)logInWithCredentials:(NSDictionary *)info
{
    [[NSUserDefaults standardUserDefaults] setObject:info[@"key"] forKey:kSessionKey];
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
    NSString *artist = [infoAboutCurrentTrack objectForKey:@"Artist"];
    NSString *album = [infoAboutCurrentTrack objectForKey:@"Album"];
    NSString *trackName = [infoAboutCurrentTrack objectForKey:@"Name"];
    double duration = [[infoAboutCurrentTrack objectForKey:@"Total Time"] doubleValue] / 1000;
    self.currentTrack = [[Song alloc] initWithTrackName:trackName artist:artist album:album andDuration:duration];
}

#pragma mark - Offline scrobbler


@end
