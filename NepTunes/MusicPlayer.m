//
//  MusicPlayer.m
//  NepTunes
//
//  Created by Adam Różyński on 18/04/16.
//  Copyright © 2016 micropixels. All rights reserved.
//

#import "MusicPlayer.h"
#import <ScriptingBridge/ScriptingBridge.h>
#import "iTunes.h"
#import "Spotify.h"
#import "Track.h"
#import "MusicController.h"
#import "MPISpotifySearch.h"
#import "SettingsController.h"
#import "DebugMode.h"
#import <PINCache/PINCache.h>
#import "SBObject+Properties.h"
#import "Music.h"

@import iTunesSearch;

NSString * const kiTunesBundleIdentifier = @"com.apple.iTunes";
NSString * const kSpotifyBundlerIdentifier = @"com.spotify.client";
NSString * const kMusicAppBundleIdentifier = @"com.apple.Music";
NSString * const kCannotGetInfoFromSpotify = @"cannotGetInfoFromSpotify";


@interface MusicPlayer () <ItunesSearchCache>

@property (atomic, readwrite) MusicPlayerApplication currentPlayer;
@property (nonatomic, readwrite) Track *currentTrack;
@property (nonatomic, readwrite) MusicPlayerState playerState;

@property (nonatomic) NSTimer * _noDurationTimer;
@property (nonatomic, readonly) SpotifyTrack *_currentSpotifyTrack;
@property (nonatomic, readonly) iTunesTrack *_currentiTunesTrack;
@property (nonatomic, readonly) MusicTrack *_currentMusicTrack;

@property (nonatomic) iTunesApplication *_iTunesApp;
@property (nonatomic) SpotifyApplication *_spotifyApp;
@property (nonatomic) MusicApplication *_musicApp;
@property (nonatomic) ItunesSearch *iTunesSearch;
@property (nonatomic) PINCache *iTunesSearchCache;
@property (nonatomic, readonly) BOOL isiTunesRunning;
@property (nonatomic, readonly) BOOL isSpotifyRunning;
@property (nonatomic, readonly) BOOL isMusicAppRunning;
@property (nonatomic, readwrite) NSUInteger numberOfPlayers;

@end

@implementation MusicPlayer
@synthesize currentPlayer = _currentPlayer;

+ (id) allocWithZone:(NSZone*)z { return [self sharedPlayer];              }
+ (id) alloc                    { return [self sharedPlayer];              }
+ (id)_alloc                    { return [super allocWithZone:NULL]; }
- (id)_init                     { return [super init];               }


-(instancetype)init
{
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                        selector:@selector(notificationFromiTunes:)
                                                            name:@"com.apple.iTunes.playerInfo"
                                                          object:nil];
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                        selector:@selector(notificationFromMusicApp:)
                                                            name:@"com.apple.Music.playerInfo"
                                                          object:nil];
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                        selector:@selector(notificationFromSpotify:)
                                                            name:@"com.spotify.client.PlaybackStateChanged"
                                                          object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateRating:) name:kTrackRatingWasSetNotificationName object:nil];
    NSNotificationCenter *center = [[NSWorkspace sharedWorkspace] notificationCenter];
    [center addObserver:self
               selector:@selector(appLaunched:)
                   name:NSWorkspaceDidLaunchApplicationNotification
                 object:nil
     ];
    [center addObserver:self
               selector:@selector(appTerminated:)
                   name:NSWorkspaceDidTerminateApplicationNotification
                 object:nil
     ];
    
    
    self.delegate = [MusicController sharedController];
    return self;
}

-(void)awakeFromNib
{
    NSArray *runningApps = [NSWorkspace sharedWorkspace].runningApplications;
    for (NSRunningApplication *app in runningApps) {
        if ([app.bundleIdentifier isEqualToString:kMusicAppBundleIdentifier]) {
            self._musicApp = (MusicApplication *)[SBApplication applicationWithBundleIdentifier:kMusicAppBundleIdentifier];
            self.numberOfPlayers++;
        } else if ([app.bundleIdentifier isEqualToString:kiTunesBundleIdentifier]) {
            self._iTunesApp = (iTunesApplication *)[SBApplication applicationWithBundleIdentifier:kiTunesBundleIdentifier];
            self.numberOfPlayers++;
        } else if ([app.bundleIdentifier isEqualToString:kSpotifyBundlerIdentifier]) {
            self.numberOfPlayers++;
        }
    }
    
    [self detectCurrentPlayer];
    if (self.numberOfPlayers == 2) {
        if ([self.delegate respondsToSelector:@selector(bothPlayersAreAvailable)]) {
            [self.delegate bothPlayersAreAvailable];
        }
    }
}

+(instancetype)sharedPlayer
{
    static MusicPlayer *musicPlayer = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        musicPlayer = [[self _alloc] _init];
    });
    return musicPlayer;
}


#pragma mark - iTunes

-(void)notificationFromiTunes:(NSNotification *)notification
{
    ///for some fucking reason Music.app sends notifications for com.apple.iTunes
    if (!self.isiTunesRunning) {
        return;
    }
    self.currentPlayer = MusicPlayeriTunes;
    NSDictionary *userInfoFromNotification = notification.userInfo;
    if (self.currentPlayer == MusicPlayeriTunes && self._iTunesApp.playerState == iTunesEPlSPlaying) {
        [self invalidateNoDurationTimerIfNeeded];
        [self setCurrentTrackFromiTunesOrUserInfo:userInfoFromNotification];
        [self.delegate trackChanged];
    } else if (self.isiTunesRunning) {
        [self.delegate playerStateChanged];
    }
}

-(void)setCurrentTrackFromiTunesOrUserInfo:(NSDictionary *)userInfo
{
    if (self._currentiTunesTrack.name.length && self._currentiTunesTrack.time && !userInfo) {
        self.currentTrack = [Track trackWithiTunesTrack:self._currentiTunesTrack];
    } else {
        if (self.isiTunesRunning && userInfo) {
            self.currentTrack = [self trackFromiTunesUserInfo:userInfo];
            if ([userInfo[@"Total Time"] isEqualToNumber:@(0)] || !userInfo[@"Total Time"]) {
                self._noDurationTimer = [NSTimer scheduledTimerWithTimeInterval:DELAY_FOR_RADIO target:self selector:@selector(updateTrackDuration:) userInfo:nil repeats:NO];
            }
        }
    }
}

- (Track *)trackFromiTunesUserInfo:(NSDictionary *)userInfo
{
    Track *track = [[Track alloc] initWithTrackName:userInfo[@"Name"] artist:userInfo[@"Artist"] album:userInfo[@"Album"] andDuration:[userInfo[@"Total Time"] doubleValue] / 1000];
    track.rating = [[userInfo objectForKey:@"Rating"] integerValue];
    if ([[userInfo objectForKey:@"Store URL"] containsString:@"itms://itunes.com/link?"] || [userInfo objectForKey:@"Category"]) {
        track.trackKind = TrackKindUndefined;
    } else {
        track.trackKind = TrackKindMusic;
    }
    track.trackOrigin = TrackFromiTunes;
    return track;
}

-(void)updateTrackDuration:(NSTimer *)timer
{
    if (self.isiTunesRunning) {
        self.currentTrack.duration = self._currentiTunesTrack.duration;
    }
}

-(void)invalidateNoDurationTimerIfNeeded
{
    if (self._noDurationTimer) {
        [self._noDurationTimer invalidate];
        self._noDurationTimer = nil;
    }
}

-(void)loveCurrentTrackOniTunes
{
    self._iTunesApp.currentTrack.loved = YES;
}

-(NSImage *)currentiTunesTrackCover
{
    iTunesTrack *track = self._currentiTunesTrack;
    for (iTunesArtwork *artwork in track.artworks) {
        if ([artwork.data isKindOfClass:[NSImage class]]) {
            return artwork.data;
        } else if ([artwork.rawData isKindOfClass:[NSData class]]) {
            return [[NSImage alloc] initWithData:artwork.rawData];
        }
    }
    return nil;
}

-(NSImage *)currentMusicAppTrackCover
{
    MusicTrack *track = self._currentMusicTrack;
    for (MusicArtwork *artwork in track.artworks) {
        if ([artwork.data isKindOfClass:[NSImage class]]) {
            return artwork.data;
        } else if ([artwork.rawData isKindOfClass:[NSData class]]) {
            return [[NSImage alloc] initWithData:artwork.rawData];
        }
    }
    return nil;
}

#pragma mark iTunes playback
-(void)fastForward
{
    if (self.currentPlayer == MusicPlayeriTunes) {
        [self._iTunesApp fastForward];
    } else if (self.currentPlayer == MusicPlayerMusicApp) {
        [self._musicApp fastForward];
    }
}
-(void)rewind
{
    if (self.currentPlayer == MusicPlayeriTunes) {
        [self._iTunesApp rewind];
    } else if (self.currentPlayer == MusicPlayerMusicApp) {
        [self._musicApp rewind];
    }
}
-(void)resume
{
    if (self.currentPlayer == MusicPlayeriTunes) {
        [self._iTunesApp resume];
    } else if (self.currentPlayer == MusicPlayerMusicApp) {
        [self._musicApp resume];
    }
}

#pragma mark - Music App

-(void)notificationFromMusicApp:(NSNotification *)note
{
    self.currentPlayer = MusicPlayerMusicApp;
    NSDictionary *userInfoFromNotification = note.userInfo;
    if (self.isMusicAppRunning && self.currentPlayer == MusicPlayerMusicApp && self._musicApp.playerState == MusicEPlSPlaying) {
        [self invalidateNoDurationTimerIfNeeded];
        [self setCurrentTrackFromMusicAppOrUserInfo:userInfoFromNotification];
        [self.delegate trackChanged];
    } else if (self.isMusicAppRunning) {
        [self.delegate playerStateChanged];
    }
}

-(void)setCurrentTrackFromMusicAppOrUserInfo:(NSDictionary *)userInfo
{
    if (self._currentMusicTrack.artist.length && self._currentMusicTrack.time && !userInfo) {
        self.currentTrack = [Track trackWithMusicTrack:self._currentMusicTrack];
    } else {
        if (self.isMusicAppRunning && userInfo) {
            self.currentTrack = [self trackFromMusicAppUserInfo:userInfo];
            if ([userInfo[@"Total Time"] isEqualToNumber:@(0)] || !userInfo[@"Total Time"]) {
                self._noDurationTimer = [NSTimer scheduledTimerWithTimeInterval:DELAY_FOR_RADIO target:self selector:@selector(updateTrackDuration:) userInfo:nil repeats:NO];
            }
        }
    }
}

- (Track *)trackFromMusicAppUserInfo:(NSDictionary *)userInfo
{
    Track *track = [[Track alloc] initWithTrackName:userInfo[@"Name"] artist:userInfo[@"Artist"] album:userInfo[@"Album"] andDuration:[userInfo[@"Total Time"] doubleValue] / 1000];
    track.rating = [[userInfo objectForKey:@"Rating"] integerValue];
    if ([[userInfo objectForKey:@"Store URL"] containsString:@"itms://itunes.com/link?"] || [userInfo objectForKey:@"Category"]) {
        track.trackKind = TrackKindUndefined;
    } else {
        track.trackKind = TrackKindMusic;
    }
    track.trackOrigin = TrackFromMusicApp;
    return track;
}

#pragma mark - Spotify

-(void)notificationFromSpotify:(NSNotification *)notification
{
    if (![[notification.userInfo objectForKey:@"Player State"] isEqualToString:@"Stopped"]) {
        self.currentPlayer = MusicPlayerSpotify;
        if (self.currentPlayer == MusicPlayerSpotify) {
            [self setCurrentTrackFromSpotify];
            [self.delegate trackChanged];
        }
    } else {
        if (self.currentPlayer == MusicPlayerSpotify) {
            self.currentTrack = nil;
            [self.delegate trackChanged];
        }
    }
}

-(void)setCurrentTrackFromSpotify
{
    self.currentTrack = [Track trackWithSpotifyTrack:self._spotifyApp.currentTrack];
}

-(NSString *)currentSpotifyTrackCover
{
    if (self._currentSpotifyTrack.artworkUrl) {
        return self._currentSpotifyTrack.artworkUrl;
    }
    return nil;
}

#pragma mark - Common
-(void)detectCurrentPlayer
{
    if (self.isSpotifyRunning && self._spotifyApp.playerState == SpotifyEPlSPlaying) {
        self.currentPlayer = MusicPlayerSpotify;
        [self setCurrentTrackFromSpotify];
        [self.delegate trackChanged];
        [self.delegate newActivePlayer];
    } else if (self.isiTunesRunning && self._iTunesApp.playerState == iTunesEPlSPlaying) {
        self.currentPlayer = MusicPlayeriTunes;
        [self setCurrentTrackFromiTunesOrUserInfo:nil];
        [self.delegate trackChanged];
        [self.delegate newActivePlayer];
    } else if (self.isMusicAppRunning && self._musicApp.playerState == MusicEPlSPlaying) {
        self.currentPlayer = MusicPlayerMusicApp;
        [self setCurrentTrackFromMusicAppOrUserInfo:nil];
        [self.delegate trackChanged];
        [self.delegate newActivePlayer];
    }
}

-(void)openArtistPageForArtistName:(NSString *)artistName withFailureHandler:(void(^)(void))failureHandler
{
    [self openArtistPageInPlayer:self.currentPlayer forArtistName:artistName withFailureHandler:failureHandler];
}


-(void)openArtistPageInPlayer:(MusicPlayerApplication)player forArtistName:(NSString *)artistName withFailureHandler:(void(^)(void))failureHandler
{
    __weak typeof(self) weakSelf = self;
    if (player == MusicPlayerSpotify) {
        [[MPISpotifySearch sharedInstance] searchForArtistWithName:artistName limit:@1 handler:^(NSError * _Nullable error, NSArray * _Nullable result) {
            if (result.count) {
                NSDictionary *firstResult = [result firstObject];
                NSString *link = [firstResult objectForKey:@"uri"];
                [weakSelf openLocationWithURL:link];
            } else {
                if (failureHandler) {
                    failureHandler();
                }
            }
        }];
    } else if (player == MusicPlayeriTunes || player == MusicPlayerMusicApp) {
        [[ItunesSearch sharedInstance] getIdForArtist:artistName successHandler:^(NSArray *result) {
            if (result.count) {
                [weakSelf openLocationWithURL:(NSString *)result.firstObject[@"artistLinkUrl"]];
            } else {
                [[ItunesSearch sharedInstance] getIdForArtist:[self asciiString:artistName] successHandler:^(NSArray *result) {
                    if (result.count) {
                        [weakSelf openLocationWithURL:(NSString *)result.firstObject[@"artistLinkUrl"]];
                    }
                } failureHandler:^(NSError *error) {
                    if (failureHandler) {
                        failureHandler();
                    }
                }];
            }
        } failureHandler:^(NSError *error) {
            if (failureHandler) {
                failureHandler();
            }
        }];
    }
}

-(void)openLocationWithURL:(NSString *)url
{
    if (self.currentPlayer == MusicPlayeriTunes || self.currentPlayer == MusicPlayerMusicApp) {
        [self bringPlayerToFront];
        NSString * link = [url stringByReplacingOccurrencesOfString:@"https://" withString:@"itmss://"];
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:link]];
    } else if (self.currentPlayer == MusicPlayerSpotify) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
    }
}

-(void)getArtistURLForArtist:(NSString *)artist publicLink:(BOOL)publicLink forCurrentPlayerWithCompletionHandler:(void(^)(NSString *urlString))handler failureHandler:(void(^)(NSError *error))failureHandler;
{
    [self getArtistURLForArtist:artist forPlayer:self.currentPlayer publicLink:publicLink withCompletionHandler:handler failureHandler:failureHandler];
}

-(void)getArtistURLForArtist:(NSString *)artist forPlayer:(MusicPlayerApplication)player publicLink:(BOOL)publicLink withCompletionHandler:(void(^)(NSString *urlString))handler failureHandler:(void(^)(NSError *error))failureHandler
{
    if (player == MusicPlayerSpotify) {
        [[MPISpotifySearch sharedInstance] searchForArtistWithName:artist limit:@1 handler:^(NSError * _Nullable error, NSArray * _Nullable result) {
            if (result.count) {
                NSDictionary *firstResult = [result firstObject];
                NSString *link;
                if (!publicLink) {
                    link = [firstResult objectForKey:@"uri"];
                } else {
                    link = [[firstResult objectForKey:@"external_urls"] objectForKey:@"spotify"];
                }
                handler(link);
            } else {
                failureHandler(error);
            }
        }];

    } else if (player == MusicPlayeriTunes || player == MusicPlayerMusicApp) {
        __weak typeof(self) weakSelf = self;
        [self.iTunesSearch getIdForArtist:artist successHandler:^(NSArray *result) {
            if (result.count) {
                NSDictionary *firstResult = [result firstObject];
                NSString *link = firstResult[@"artistLinkUrl"];
                handler(link);
            } else {
                [weakSelf.iTunesSearch getIdForArtist:[weakSelf asciiString:artist] successHandler:^(NSArray *result) {
                    if (result.count) {
                        NSDictionary *firstResult = [result firstObject];
                        NSString *link = firstResult[@"artistLinkUrl"];
                        handler(link);
                    }
                } failureHandler:^(NSError *error) {
                    if (failureHandler) {
                        failureHandler(error);
                    }
                }];
            }
        } failureHandler:^(NSError *error) {
            if (failureHandler) {
                failureHandler(error);
            }
        }];
    } else {
        if (failureHandler) {
            failureHandler(nil);
        }
    }
}

-(void)openTrackPageForTrack:(Track *)track withFailureHandler:(void(^)(void))failureHandler
{
    __weak typeof(self) weakSelf = self;
    [self getTrackURL:track publicLink:NO forCurrentPlayerWithCompletionHandler:^(NSString *urlString) {
        if (weakSelf.currentPlayer == MusicPlayeriTunes || weakSelf.currentPlayer == MusicPlayerMusicApp) {
            [weakSelf bringPlayerToFront];
            urlString = [urlString stringByReplacingOccurrencesOfString:@"https://" withString:@"itmss://"];
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlString]];
        } else if (weakSelf.currentPlayer == MusicPlayerSpotify) {
            if (weakSelf.isSpotifyRunning) {
                [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlString]];
            } else {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlString]];
                });
            }
        }
    } failureHandler:^(NSError *error) {
        failureHandler();
    }];
}

-(void)getCurrentTrackURLPublicLink:(BOOL)publicLink withCompletionHandler:(void(^)(NSString *urlString))handler failureHandler:(void(^)(NSError *error))failureHandler;
{
    [self getTrackURL:self.currentTrack publicLink:publicLink withCompletionHandler:handler failureHandler:failureHandler];
}

-(void)getTrackURL:(Track *)track publicLink:(BOOL)publicLink withCompletionHandler:(void(^)(NSString *urlString))handler failureHandler:(void(^)(NSError *))failureHandler
{
    MusicPlayerApplication player = MusicPlayerUndefined;
    if (track.trackOrigin == TrackFromSpotify) {
        player = MusicPlayerSpotify;
    } else if (track.trackOrigin == TrackFromiTunes) {
        player = MusicPlayeriTunes;
    } else if (track.trackOrigin == TrackFromMusicApp) {
        player = MusicPlayerMusicApp;
    }
    if (player != MusicPlayerUndefined) {
        [self getTrackURL:track forPlayer:player publicLink:publicLink withCompletionHandler:handler failureHandler:failureHandler];
    }
}

-(void)getTrackURL:(Track *)track publicLink:(BOOL)publicLink forCurrentPlayerWithCompletionHandler:(void(^)(NSString *urlString))handler failureHandler:(void(^)(NSError *error))failureHandler
{
    [self getTrackURL:track forPlayer:self.currentPlayer publicLink:publicLink withCompletionHandler:handler failureHandler:failureHandler];
}

-(void)getTrackURL:(Track *)track forPlayer:(MusicPlayerApplication)player publicLink:(BOOL)publicLink withCompletionHandler:(void(^)(NSString *urlString))handler failureHandler:(void(^)(NSError *error))failureHandler
{
    if (player == MusicPlayeriTunes || player == MusicPlayerMusicApp) {
        [self.iTunesSearch getTrackWithName:track.trackName artist:track.artist album:track.album limitOrNil:nil successHandler:^(NSArray *result) {
            NSDictionary *firstResult = result.firstObject;
            NSString *resultString = [firstResult objectForKey:@"collectionViewUrl"];
            if (resultString && [resultString isKindOfClass:[NSString class]]) {
                handler(resultString);
            } else handler(nil);
        } failureHandler:^(NSError *error) {
            failureHandler(nil);
        }];
    } else if (player == MusicPlayerSpotify) {
        MPISpotifySearch *spotifySearch = [MPISpotifySearch sharedInstance];
        if (track.spotifyID) {
            [spotifySearch getTrackWithID:track.spotifyID handler:^(NSError * _Nullable error, id _Nullable result) {
                if (result) {
                    NSDictionary *firstResult = [(NSArray *)result firstObject];
                    NSString *resultString;
                    if (!publicLink) {
                        resultString = [firstResult objectForKey:@"uri"];
                    } else {
                        resultString = [[firstResult objectForKey:@"external_urls"] objectForKey:@"spotify"];
                    }
                    handler(resultString);
                } else {
                    failureHandler(error);
                }
            }];
            
        } else {
            
            [spotifySearch getTrackWithName:track.trackName artist:track.artist album:track.album limit:@1 handler:^(NSError * _Nullable error, NSArray * _Nullable result) {
                if (result.count) {
                    NSDictionary *firstResult = result.firstObject;
                    NSString *resultString;
                    if (!publicLink) {
                        resultString = [firstResult objectForKey:@"uri"];
                    } else {
                        resultString = [[firstResult objectForKey:@"external_urls"] objectForKey:@"spotify"];
                    }
                    handler(resultString);
                } else {
                    handler(nil);
                }
            }];
        }
    } else {
        failureHandler(nil);
    }
}

-(NSString *)asciiString:(NSString *)string
{
    NSData *asciiEncoded = [string.lowercaseString dataUsingEncoding:NSASCIIStringEncoding
                                                allowLossyConversion:YES];
    
    NSString *stringInAscii = [[NSString alloc] initWithData:asciiEncoded
                                                    encoding:NSASCIIStringEncoding];
    return stringInAscii;
    
}

-(void)bringPlayerToFront
{
    if (self.currentPlayer == MusicPlayeriTunes) {
        [[NSWorkspace sharedWorkspace] launchAppWithBundleIdentifier:kiTunesBundleIdentifier options:NSWorkspaceLaunchDefault additionalEventParamDescriptor:nil launchIdentifier:NULL];
    } else if (self.currentPlayer == MusicPlayerSpotify) {
        [[NSWorkspace sharedWorkspace] launchAppWithBundleIdentifier:kSpotifyBundlerIdentifier options:NSWorkspaceLaunchDefault additionalEventParamDescriptor:nil launchIdentifier:NULL];
    } else if (self.currentPlayer == MusicPlayerMusicApp) {
        [[NSWorkspace sharedWorkspace] launchAppWithBundleIdentifier:kMusicAppBundleIdentifier options:NSWorkspaceLaunchDefault additionalEventParamDescriptor:nil launchIdentifier:NULL];
    }
}

-(id)currentTrackCoverOrURL;
{
    if (self.currentPlayer == MusicPlayeriTunes) {
        return [self currentiTunesTrackCover];
    } else if (self.currentPlayer == MusicPlayerSpotify) {
        return [self currentSpotifyTrackCover];
    } else return nil;
}

-(void)updateRating:(NSNotification *)note
{
    if (self.currentPlayer == MusicPlayeriTunes) {
        NSInteger newRating = ((Track *)note.object).rating;
        if ((self._currentiTunesTrack.ratingKind == iTunesERtKComputed) && (self._currentiTunesTrack.rating == newRating)) {
            return ;
        }
        self._currentiTunesTrack.rating = newRating;
    }
}

#pragma mark Soundvolume
-(void)setSoundVolume:(NSInteger)soundVolume
{
    if (self.currentPlayer == MusicPlayerSpotify) {
        //strange fix for Spotify volume
        self._spotifyApp.soundVolume = soundVolume == 100 ? soundVolume : ++soundVolume;
    } else if (self.currentPlayer == MusicPlayeriTunes) {
        self._iTunesApp.soundVolume = soundVolume;
    } else if (self.currentPlayer == MusicPlayerMusicApp) {
        [self._musicApp setSoundVolume:soundVolume];
    }
}

-(NSInteger)soundVolume
{
    if (self.currentPlayer == MusicPlayerSpotify) {
        return self._spotifyApp.soundVolume;
    } else if (self.currentPlayer == MusicPlayeriTunes) {
        return self._iTunesApp.soundVolume;
    } else if (self.currentPlayer == MusicPlayerMusicApp) {
        return [self._musicApp soundVolume];
    } else return 100;
}

#pragma mark Playback
-(void)playPause
{
    if (self.currentPlayer == MusicPlayeriTunes && self.isiTunesRunning && self.playerState != MusicPlayerStateUndefined) {
        [self._iTunesApp playpause];
    } else if (self.currentPlayer == MusicPlayerSpotify && self.isSpotifyRunning && self.playerState != MusicPlayerStateUndefined) {
        [self._spotifyApp playpause];
    } else if (self.currentPlayer == MusicPlayerMusicApp && self.isMusicAppRunning && self.playerState != MusicPlayerStateUndefined) {
        [self._musicApp playpause];
    }
}

-(void)nextTrack
{
    if (self.currentPlayer == MusicPlayeriTunes && self.isiTunesRunning && self.playerState != MusicPlayerStateUndefined) {
        [self._iTunesApp nextTrack];
    } else if (self.currentPlayer == MusicPlayerSpotify && self.isSpotifyRunning && self.playerState != MusicPlayerStateUndefined) {
        [self._spotifyApp nextTrack];
    } else if (self.currentPlayer == MusicPlayerMusicApp && self.isMusicAppRunning && self.playerState != MusicPlayerStateUndefined) {
        [self._musicApp nextTrack];
    }
}
-(void)backTrack
{
    if (self.currentPlayer == MusicPlayeriTunes && self.isiTunesRunning && self.playerState != MusicPlayerStateUndefined) {
        [self._iTunesApp backTrack];
    } else if (self.currentPlayer == MusicPlayerSpotify && self.isSpotifyRunning && self.playerState != MusicPlayerStateUndefined) {
        [self._spotifyApp previousTrack];
    } else if (self.currentPlayer == MusicPlayerMusicApp && self.isMusicAppRunning && self.playerState != MusicPlayerStateUndefined) {
        [self._musicApp previousTrack];
    }
}

#pragma mark - iTunes and Spotify Lifecycle
-(void)appLaunched:(NSNotification *)note
{
    if ([[note.userInfo objectForKey:@"NSApplicationBundleIdentifier"] isEqualToString:kSpotifyBundlerIdentifier]) {
        self.numberOfPlayers++;
        if (self.currentPlayer == MusicPlayerUndefined) {
            self.currentPlayer = MusicPlayerSpotify;
        }
        
    } else if ([[note.userInfo objectForKey:@"NSApplicationBundleIdentifier"] isEqualToString:kiTunesBundleIdentifier]) {
        self._iTunesApp = (iTunesApplication *)[SBApplication applicationWithBundleIdentifier:kiTunesBundleIdentifier];
        
        self.numberOfPlayers++;
        if (self.currentPlayer == MusicPlayerUndefined) {
            self.currentPlayer = MusicPlayeriTunes;
        }
    } else if ([[note.userInfo objectForKey:@"NSApplicationBundleIdentifier"] isEqualToString:kMusicAppBundleIdentifier]) {
        self._musicApp = (MusicApplication *)[SBApplication applicationWithBundleIdentifier:kMusicAppBundleIdentifier];

        self.numberOfPlayers++;
        if (self.currentPlayer == MusicPlayerUndefined) {
            self.currentPlayer = MusicPlayerMusicApp;
        }
    }
    if (self.numberOfPlayers == 2) {
        if ([self.delegate respondsToSelector:@selector(bothPlayersAreAvailable)]) {
            [self.delegate bothPlayersAreAvailable];
        }
    }
    [self.delegate newActivePlayer];
}

-(void)appTerminated:(NSNotification *)note
{
    NSLog(@"appTerminated");
    NSUInteger numberOfPlayers = self.numberOfPlayers;
    if ([[note.userInfo objectForKey:@"NSApplicationBundleIdentifier"] isEqualToString:kSpotifyBundlerIdentifier]) {
        self.numberOfPlayers--;
        self._spotifyApp = nil;
        if (self.isiTunesRunning) {
            self.currentPlayer = MusicPlayeriTunes;
        } else if (self.isMusicAppRunning) {
            self.currentPlayer = MusicPlayerMusicApp;
        } else {
            self.currentPlayer = MusicPlayerUndefined;
        }
        self._spotifyApp = nil;
        [self.delegate playerStateChanged];
    } else if ([[note.userInfo objectForKey:@"NSApplicationBundleIdentifier"] isEqualToString:kiTunesBundleIdentifier]) {
        self.numberOfPlayers--;
        self._iTunesApp = nil;
        if (self.isSpotifyRunning) {
            self.currentPlayer = MusicPlayerSpotify;
        }  else {
            self.currentPlayer = MusicPlayerUndefined;
        }
        self._iTunesApp = nil;
        [self.delegate playerStateChanged];
    } else if ([[note.userInfo objectForKey:@"NSApplicationBundleIdentifier"] isEqualToString:kMusicAppBundleIdentifier]) {
        self._musicApp = nil;
        self.numberOfPlayers--;
        if (self.isSpotifyRunning) {
            self.currentPlayer = MusicPlayerSpotify;
        } else {
            self.currentPlayer = MusicPlayerUndefined;
        }
        [self.delegate playerStateChanged];
    }
    if (self.numberOfPlayers < 2 && numberOfPlayers == 2) {
        if ([self.delegate respondsToSelector:@selector(onePlayerIsAvailable)]) {
            [self.delegate onePlayerIsAvailable];
        }
    }
}

#pragma mark - Source
-(void)setCurrentPlayer:(MusicPlayerApplication)currentPlayer
{
    @synchronized (self) {
        if (_currentPlayer == MusicPlayerUndefined) {
            _currentPlayer = currentPlayer;
            [self.delegate newActivePlayer];
            return;
        }
        if (_currentPlayer == MusicPlayerSpotify && currentPlayer == MusicPlayeriTunes && (!self.isSpotifyRunning || self._spotifyApp.playerState != SpotifyEPlSPlaying)) {
            _currentPlayer = currentPlayer;
            [self.delegate newActivePlayer];
            return;
        }
        if (_currentPlayer == MusicPlayeriTunes && currentPlayer == MusicPlayerSpotify && (!self.isiTunesRunning || self._iTunesApp.playerState != iTunesEPlSPlaying)) {
            _currentPlayer = currentPlayer;
            [self.delegate newActivePlayer];
            
            return;
        }
        if (_currentPlayer == MusicPlayerSpotify && currentPlayer == MusicPlayerMusicApp && (!self.isSpotifyRunning || self._spotifyApp.playerState != SpotifyEPlSPlaying)) {
            _currentPlayer = currentPlayer;
            [self.delegate newActivePlayer];
            return;
        }
        if (_currentPlayer == MusicPlayerMusicApp && currentPlayer == MusicPlayerSpotify && (!self.isMusicAppRunning || self._musicApp.playerState != MusicEPlSPlaying)) {
            _currentPlayer = currentPlayer;
            [self.delegate newActivePlayer];
            return;
        }
    }
}

-(void)changeSourceTo:(MusicPlayerApplication)source
{
    _currentPlayer = source;
    [self.delegate newActivePlayer];
    if (source == MusicPlayerSpotify) {
        [self notificationFromSpotify:nil];
    } else if (source == MusicPlayeriTunes) {
        [self notificationFromiTunes:nil];
    } else if (source == MusicPlayerMusicApp) {
        [self notificationFromMusicApp:nil];
    }
}

-(NSString *)runningSystemPlayerName
{
    NSArray *runningApps = [NSWorkspace sharedWorkspace].runningApplications;
    for (NSRunningApplication *app in runningApps) {
        if ([app.bundleIdentifier isEqualToString:kMusicAppBundleIdentifier]) {
            return @"Music";
        } else if ([app.bundleIdentifier isEqualToString:kiTunesBundleIdentifier]) {
            return @"iTunes";
        }
    }
    return nil;
}

#pragma mark - iTunes Search Cache Delegate
- (NSArray *)cachedArrayForKey:(NSString *)key
{
    return [self.iTunesSearchCache objectForKey:key];
}

- (void)cacheArray:(NSArray *)array forKey:(NSString *)key requestParams:(NSDictionary *)params maxAge:(NSTimeInterval)maxAge
{
    if (array) {
        [self.iTunesSearchCache setObject:array forKey:key];
    }
}

#pragma mark - GETTERS

-(MusicPlayerApplication)currentPlayer
{
    if (_currentPlayer == MusicPlayerUndefined) {
        [self detectCurrentPlayer];
    }
    return _currentPlayer;
}

-(MusicPlayerState)playerState
{
    if (self.isiTunesRunning && self.currentPlayer == MusicPlayeriTunes) {
        switch (self._iTunesApp.playerState) {
            case iTunesEPlSPlaying:
                return MusicPlayerStatePlaying;
                break;
            case iTunesEPlSStopped:
                return MusicPlayerStateStopped;
                break;
            case iTunesEPlSPaused:
                return MusicPlayerStatePaused;
                break;
            default:
                return MusicPlayerStateUndefined;
                break;
        }
    } else if (self.currentPlayer == MusicPlayerSpotify) {
        switch (self._spotifyApp.playerState) {
            case SpotifyEPlSPlaying:
                return MusicPlayerStatePlaying;
                break;
            case SpotifyEPlSPaused:
                return MusicPlayerStatePaused;
                break;
            case SpotifyEPlSStopped:
                return MusicPlayerStateStopped;
                break;
            default:
                return MusicPlayerStateUndefined;
                break;
        }
    } else if (self.currentPlayer == MusicPlayerMusicApp) {
        switch (self._musicApp.playerState) {
            case MusicEPlSPlaying:
                return MusicPlayerStatePlaying;
                break;
            case MusicEPlSPaused:
                return MusicPlayerStatePaused;
                break;
            case MusicEPlSStopped:
                return MusicPlayerStateStopped;
                break;
            default:
                return MusicPlayerStateUndefined;
                break;
        }
    }
    else return MusicPlayerStateUndefined;
}

-(BOOL)isPlayerRunning
{
    if (self.currentPlayer == MusicPlayeriTunes) {
        return self.isiTunesRunning;
    } else if (self.currentPlayer == MusicPlayerSpotify) {
        return self.isSpotifyRunning;
    } else if (self.currentPlayer == MusicPlayerMusicApp) {
        return self.isMusicAppRunning;
    } else return NO;
}

-(BOOL)isiTunesRunning
{
    if (self._iTunesApp.isRunning) {
        return YES;
    }
    return NO;
}

-(BOOL)isSpotifyRunning
{
    if (self._spotifyApp.isRunning) {
        return YES;
    }
    return NO;
}

-(BOOL)isMusicAppRunning
{
    return self._musicApp.isRunning;
}

-(SpotifyTrack *)_currentSpotifyTrack
{
    if (self.currentPlayer == MusicPlayerSpotify && self.isSpotifyRunning) {
        return self._spotifyApp.currentTrack;
    }
    return nil;
}

-(iTunesTrack *)_currentiTunesTrack
{
    if (self.currentPlayer == MusicPlayeriTunes && self.isiTunesRunning) {
        return self._iTunesApp.currentTrack;
    }
    return nil;
}

-(MusicTrack *)_currentMusicTrack
{
    if (self.currentPlayer == MusicPlayerMusicApp && self.isMusicAppRunning) {
        return self._musicApp.currentTrack;
    }
    return nil;
}

-(SpotifyApplication *)_spotifyApp
{
    if (!__spotifyApp) {
        NSRunningApplication *spotify;
        NSArray *runningApps = [NSWorkspace sharedWorkspace].runningApplications;
        for (NSRunningApplication *app in runningApps) {
            if ([app.bundleIdentifier isEqualToString:kSpotifyBundlerIdentifier]) {
                spotify = app;
            }
        }
        if (spotify) {
            __spotifyApp  = (SpotifyApplication *)[SBApplication applicationWithBundleIdentifier:kSpotifyBundlerIdentifier];
        }
        if (__spotifyApp && ![__spotifyApp respondsToSelector:@selector(playerState)]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kCannotGetInfoFromSpotify object:self];
            return nil;
        }
    }

    return __spotifyApp;
}

//-(iTunesApplication *)_iTunesApp
//{
//    if (!__iTunesApp) {
//        NSRunningApplication *iTunes;
//        NSArray *runningApps = [NSWorkspace sharedWorkspace].runningApplications;
//        for (NSRunningApplication *app in runningApps) {
//            if ([app.bundleIdentifier isEqualToString:kiTunesBundleIdentifier]) {
//                iTunes = app;
//            }
//        }
//        if (iTunes) {
//            __iTunesApp = (iTunesApplication *)[SBApplication applicationWithBundleIdentifier:kiTunesBundleIdentifier];
//        }
//    }
//    return __iTunesApp;
//}

//- (MusicApplication *)_musicApp
//{
//    NSRunningApplication *musicApp;
//    NSArray *runningApps = [NSWorkspace sharedWorkspace].runningApplications;
//    for (NSRunningApplication *app in runningApps) {
//        if ([app.bundleIdentifier isEqualToString:kMusicAppBundleIdentifier]) {
//            musicApp = app;
//        }
//    }
//    if (musicApp) {
//        NSLog(@"_musicApp");
//        return (MusicApplication *)[SBApplication applicationWithBundleIdentifier:kMusicAppBundleIdentifier];
//    }
//    return nil;
//}

-(BOOL)canObtainCurrentTrackFromiTunes
{
    if (self.isiTunesRunning && self._currentiTunesTrack.name.length) {
        return YES;
    }
    return NO;
}

-(BOOL)canObtainCurrentTrackFromMusicApp
{
    if (self.isMusicAppRunning && self._currentMusicTrack.name.length) {
        return YES;
    }
    return NO;
}

-(ItunesSearch *)iTunesSearch
{
    if (!_iTunesSearch) {
        _iTunesSearch = [ItunesSearch sharedInstance];
        _iTunesSearch.affiliateToken = @"1010l3j7";
        _iTunesSearch.campaignToken = @"neptunes";
        _iTunesSearch.cacheDelegate = self;
    }
    return _iTunesSearch;
}

- (PINCache *)iTunesSearchCache
{
    if (!_iTunesSearchCache) {
        _iTunesSearchCache = [PINCache sharedCache];
    }
    return _iTunesSearchCache;
}


@end
