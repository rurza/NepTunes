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
#import "SpotifySearch.h"
#import "ITunesSearch.h"
#import "DebugMode.h"

NSString * const kiTunesBundleIdentifier = @"com.apple.iTunes";
NSString * const kSpotifyBundlerIdentifier = @"com.spotify.client";
NSString * const kCannotGetInfoFromSpotify = @"cannotGetInfoFromSpotify";


@interface MusicPlayer ()

@property (atomic, readwrite) MusicPlayerApplication currentPlayer;
@property (nonatomic, readwrite) Track *currentTrack;
@property (nonatomic, readwrite) MusicPlayerState playerState;

@property (nonatomic) NSTimer * _noDurationTimer;
@property (nonatomic, readonly) SpotifyTrack *_currentSpotifyTrack;
@property (nonatomic, readonly) iTunesTrack *_currentiTunesTrack;

@property (nonatomic) iTunesApplication *_iTunesApp;
@property (nonatomic) SpotifyApplication *_spotifyApp;
@property (nonatomic) ItunesSearch *iTunesSearch;
@property (nonatomic, readonly) BOOL isiTunesRunning;
@property (nonatomic, readonly) BOOL isSpotifyRunning;
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
        if ([app.bundleIdentifier isEqualToString:kiTunesBundleIdentifier]) {
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
    self.currentPlayer = MusicPlayeriTunes;
    if (self.currentPlayer == MusicPlayeriTunes) {
        [self invalidateNoDurationTimerIfNeeded];
        NSDictionary *userInfoFromNotification = notification.userInfo;
        [self setCurrentTrackFromiTunesOrUserInfo:userInfoFromNotification];
        [self.delegate trackChanged];
    }
}

-(void)setCurrentTrackFromiTunesOrUserInfo:(NSDictionary *)userInfo
{
    
    if (self._currentiTunesTrack.name.length && self._currentiTunesTrack.duration) {
        self.currentTrack = [Track trackWithiTunesTrack:self._currentiTunesTrack];
        if ([userInfo objectForKey:@"Category"]) {
            self.currentTrack.trackKind = TrackKindUndefined;
        }
    } else {
        if (self.isiTunesRunning && userInfo) {
            self.currentTrack = [[Track alloc] initWithTrackName:userInfo[@"Name"] artist:userInfo[@"Artist"] album:userInfo[@"Album"] andDuration:[userInfo[@"Total Time"] doubleValue] / 1000];
            if ([[userInfo objectForKey:@"Store URL"] containsString:@"itms://itunes.com/link?"] || [userInfo objectForKey:@"Category"]) {
                self.currentTrack.trackKind = TrackKindUndefined;
            } else {
                self.currentTrack.trackKind = TrackKindMusic;
            }
            if ([userInfo[@"Total Time"] isEqualToNumber:@(0)] || !userInfo[@"Total Time"]) {
                self._noDurationTimer = [NSTimer scheduledTimerWithTimeInterval:DELAY_FOR_RADIO target:self selector:@selector(updateTrackDuration:) userInfo:nil repeats:NO];
            }
            self.currentTrack.trackOrigin = TrackFromiTunes;
        }
    }
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

#pragma mark iTunes playback
-(void)fastForward
{
    if (self.currentPlayer == MusicPlayeriTunes) {
        [self._iTunesApp fastForward];
    }
}
-(void)rewind
{
    if (self.currentPlayer == MusicPlayeriTunes) {
        [self._iTunesApp rewind];
    }
}
-(void)resume
{
    if (self.currentPlayer == MusicPlayeriTunes) {
        [self._iTunesApp resume];
    }
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
        [[SpotifySearch sharedInstance] searchForArtistWithName:artistName limit:@1 successHandler:^(NSArray * _Nullable result) {
            if (result.count) {
                NSDictionary *firstResult = [result firstObject];
                NSString *link = [firstResult objectForKey:@"uri"];
                [weakSelf openLocationWithURL:link];
            } else {
                if (failureHandler) {
                    failureHandler();
                }
            }
        } failureHandler:^(NSError * _Nonnull error) {
            if (failureHandler) {
                failureHandler();
            }
        }];
    } else if (player == MusicPlayeriTunes) {
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
    if (self.currentPlayer == MusicPlayeriTunes) {
        NSString *link = [url stringByReplacingOccurrencesOfString:@"https://" withString:@"itmss://"];
        link = [link stringByAppendingString:@"&ct=neptunes"];
        [self bringPlayerToFront];
        if (self.isiTunesRunning) {
            [self._iTunesApp openLocation:link];
        } else {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self._iTunesApp openLocation:link];
            });
        }
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
        [[SpotifySearch sharedInstance] searchForArtistWithName:artist limit:@1 successHandler:^(NSArray * _Nullable result) {
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
                handler(nil);
            }
        } failureHandler:^(NSError * _Nonnull error) {
            if (failureHandler) {
                failureHandler(error);
            }
        }];
    } else if (player == MusicPlayeriTunes) {
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
        if (weakSelf.currentPlayer == MusicPlayeriTunes) {
            [weakSelf bringPlayerToFront];
            urlString = [urlString stringByReplacingOccurrencesOfString:@"https://" withString:@"itmss://"];
            if (weakSelf.isiTunesRunning) {
                [weakSelf._iTunesApp openLocation:urlString];
            } else {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [weakSelf._iTunesApp openLocation:urlString];
                });
            }
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
    MusicPlayerApplication player;
    if (track.trackOrigin == TrackFromSpotify) {
        player = MusicPlayerSpotify;
    } else if (track.trackOrigin == TrackFromiTunes) {
        player = MusicPlayeriTunes;
    }
    [self getTrackURL:track forPlayer:player publicLink:publicLink withCompletionHandler:handler failureHandler:failureHandler];
}

-(void)getTrackURL:(Track *)track publicLink:(BOOL)publicLink forCurrentPlayerWithCompletionHandler:(void(^)(NSString *urlString))handler failureHandler:(void(^)(NSError *error))failureHandler
{
    [self getTrackURL:track forPlayer:self.currentPlayer publicLink:publicLink withCompletionHandler:handler failureHandler:failureHandler];
}

-(void)getTrackURL:(Track *)track forPlayer:(MusicPlayerApplication)player publicLink:(BOOL)publicLink withCompletionHandler:(void(^)(NSString *urlString))handler failureHandler:(void(^)(NSError *error))failureHandler
{
    if (player == MusicPlayeriTunes) {
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
        SpotifySearch *spotifySearch = [SpotifySearch sharedInstance];
        if (track.spotifyID) {
            [spotifySearch getTrackWithID:track.spotifyID successHandler:^(NSArray * _Nullable result) {
                NSDictionary *firstResult = result.firstObject;
                NSString *resultString;
                if (!publicLink) {
                    resultString = [firstResult objectForKey:@"uri"];
                } else {
                    resultString = [[firstResult objectForKey:@"external_urls"] objectForKey:@"spotify"];
                }
                handler(resultString);
            } failureHandler:^(NSError * _Nonnull error) {
                handler(nil);
            }];
        } else {
            [spotifySearch getTrackWithName:track.trackName artist:track.artist album:track.album limit:@1 successHandler:^(NSArray * _Nullable result) {
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
            } failureHandler:^(NSError * _Nonnull error) {
                handler(nil);
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
        self._currentiTunesTrack.rating = ((Track *)note.object).rating;
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
    }
}

-(NSInteger)soundVolume
{
    if (self.currentPlayer == MusicPlayerSpotify) {
        return self._spotifyApp.soundVolume;
    } else if (self.currentPlayer == MusicPlayeriTunes) {
        return self._iTunesApp.soundVolume;
    } else return 100;
}

#pragma mark Playback
-(void)playPause
{
    if (self.currentPlayer == MusicPlayeriTunes && self.isiTunesRunning && self.playerState != MusicPlayerStateUndefined) {
        [self._iTunesApp playpause];
    } else if (self.currentPlayer == MusicPlayerSpotify && self.isSpotifyRunning && self.playerState != MusicPlayerStateUndefined) {
        [self._spotifyApp playpause];
    }
}

-(void)nextTrack
{
    if (self.currentPlayer == MusicPlayeriTunes && self.isiTunesRunning && self.playerState != MusicPlayerStateUndefined) {
        [self._iTunesApp nextTrack];
    } else if (self.currentPlayer == MusicPlayerSpotify && self.isSpotifyRunning && self.playerState != MusicPlayerStateUndefined) {
        [self._spotifyApp nextTrack];
    }
}
-(void)backTrack
{
    if (self.currentPlayer == MusicPlayeriTunes && self.isiTunesRunning && self.playerState != MusicPlayerStateUndefined) {
        [self._iTunesApp backTrack];
    } else if (self.currentPlayer == MusicPlayerSpotify && self.isSpotifyRunning && self.playerState != MusicPlayerStateUndefined) {
        [self._spotifyApp previousTrack];
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
        self.numberOfPlayers++;
        if (self.currentPlayer == MusicPlayerUndefined) {
            self.currentPlayer = MusicPlayeriTunes;
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
    NSUInteger numberOfPlayers = self.numberOfPlayers;
    if ([[note.userInfo objectForKey:@"NSApplicationBundleIdentifier"] isEqualToString:kSpotifyBundlerIdentifier]) {
        self.numberOfPlayers--;
        if (self.isiTunesRunning) {
            self.currentPlayer = MusicPlayeriTunes;
        }
    } else if ([[note.userInfo objectForKey:@"NSApplicationBundleIdentifier"] isEqualToString:kiTunesBundleIdentifier]) {
        self.numberOfPlayers--;
        
        if (self.isSpotifyRunning) {
            self.currentPlayer = MusicPlayerSpotify;
        }
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
    }
    else return MusicPlayerStateUndefined;
}

-(BOOL)isPlayerRunning
{
    if (self.currentPlayer == MusicPlayeriTunes) {
        return self.isiTunesRunning;
    } else if (self.currentPlayer == MusicPlayerSpotify) {
        return self.isSpotifyRunning;
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

-(SpotifyApplication *)_spotifyApp
{
    NSRunningApplication *spotify;
    if (!__spotifyApp) {
        NSArray *runningApps = [NSWorkspace sharedWorkspace].runningApplications;
        for (NSRunningApplication *app in runningApps) {
            if ([app.bundleIdentifier isEqualToString:kSpotifyBundlerIdentifier]) {
                spotify = app;
            }
        }
        if (spotify) {
            __spotifyApp = (SpotifyApplication *)[SBApplication applicationWithBundleIdentifier:kSpotifyBundlerIdentifier];
        }
    }
    if (__spotifyApp && ![__spotifyApp respondsToSelector:@selector(playerState)]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kCannotGetInfoFromSpotify object:self];
        return nil;
    }
    return __spotifyApp;
}

-(iTunesApplication *)_iTunesApp
{
    NSRunningApplication *iTunes;
    if (!__iTunesApp) {
        NSArray *runningApps = [NSWorkspace sharedWorkspace].runningApplications;
        for (NSRunningApplication *app in runningApps) {
            if ([app.bundleIdentifier isEqualToString:kiTunesBundleIdentifier]) {
                iTunes = app;
            }
        }
        if (iTunes) {
            __iTunesApp = (iTunesApplication *)[SBApplication applicationWithBundleIdentifier:kiTunesBundleIdentifier];
        } else {
            __iTunesApp = nil;
        }
    }
    return __iTunesApp;
}

-(BOOL)canObtainCurrentTrackFromiTunes
{
    if (self.isiTunesRunning && self._currentiTunesTrack.name.length) {
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
    }
    return _iTunesSearch;
}


@end
