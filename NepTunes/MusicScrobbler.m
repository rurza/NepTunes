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
#import "PreferencesController.h"
#import "MusicPlayer.h"
#import "DebugMode.h"

static NSString *const kAPIKey = @"3a26162db61a3c47204396401baf2bf7";
static NSString *const kAPISecret = @"679d4509ae07a46400dd27a05c7e9885";

@interface MusicScrobbler ()
@property (nonatomic) MusicController *musicController;
@property (nonatomic) NSUInteger loveSongTryCounter;
@property (nonatomic) MusicPlayer *musicPlayer;

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
        if ([SettingsController sharedSettings].cutExtraTags) {
            NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
            NSString *plistPath = [rootPath stringByAppendingPathComponent:@"NepTunesTagsToCut.plist"];
            self.tagsToCut = [NSArray arrayWithContentsOfFile:plistPath];
        }
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
    if (self.musicPlayer.isPlayerRunning) {
        [self scrobbleTrack:self.currentTrack atTimestamp:[[NSDate date] timeIntervalSince1970] withTryCounter:1 withSuccessHandler:^{
            [[MenuController sharedController] blinkMenuIcon];
        }];
    }
}

-(void)scrobbleTrack:(Track *)track atTimestamp:(NSTimeInterval)timestamp withTryCounter:(NSUInteger)tryCounter withSuccessHandler:(void(^)(void))successHandler
{
    if ((self.musicPlayer.playerState == MusicPlayerStatePlaying || self.delegate.tracks.count) && [SettingsController sharedSettings].username) {
        NSString *filteredName = [track.trackName copy];
        NSString *filteredAlbum = [track.album copy];
        if ([SettingsController sharedSettings].cutExtraTags) {
            filteredName = [[self stringsWithRemovedUnwantedTagsFromTrack:track] firstObject];
            filteredAlbum = [[self stringsWithRemovedUnwantedTagsFromTrack:track] lastObject];
        }
        __weak typeof(self) weakSelf = self;
        
        [self.scrobbler sendScrobbledTrack:filteredName byArtist:track.artist onAlbum:filteredAlbum withDuration:track.duration atTimestamp:timestamp successHandler:^(NSDictionary *result) {
            if ([OfflineScrobbler sharedInstance].lastFmIsDown) {
                [OfflineScrobbler sharedInstance].lastFmIsDown = NO;
            }
            DebugMode(@"%@ scrobbled!", track)
            if (successHandler) {
                successHandler();
            }
        } failureHandler:^(NSError *error) {
            
            //if session is broken and user was logged out
            if (error.code == -1001 || error.code == kLastFmerrorCodeServiceError) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    if (tryCounter <= 3) {
                        [weakSelf scrobbleTrack:track atTimestamp:timestamp withTryCounter:(tryCounter + 1) withSuccessHandler:successHandler];
                        DebugMode(@"Cannot scrobble. %@. Trying again", error.localizedDescription)
                        
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
                    DebugMode(@"Some issues with Last.fm service.")
                    
                }
                if ([OfflineScrobbler sharedInstance].areWeOffline || [SettingsController sharedSettings].userWasLoggedOut) {
                    [[OfflineScrobbler sharedInstance] saveTrack:track];
                    DebugMode(@"Saving track for offline scrobbling.")
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
    if (self.musicPlayer.isPlayerRunning) {
        if (self.scrobbler.session && self.musicPlayer.playerState == MusicPlayerStatePlaying) {
            NSString *filteredName = [track.trackName copy];
            NSString *filteredAlbum = [track.album copy];
            if ([SettingsController sharedSettings].cutExtraTags) {
                filteredName = [[self stringsWithRemovedUnwantedTagsFromTrack:track] firstObject];
                filteredAlbum = [[self stringsWithRemovedUnwantedTagsFromTrack:track] lastObject];
            }
            __weak typeof(self) weakSelf = self;
            [self.scrobbler sendNowPlayingTrack:filteredName byArtist:track.artist onAlbum:filteredAlbum withDuration:track.duration successHandler:^(NSDictionary *result) {
                
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
    if (self.scrobbler.session && self.musicPlayer.isPlayerRunning) {
        NSString *filteredName = [track.trackName copy];
        if ([SettingsController sharedSettings].cutExtraTags) {
            filteredName = [[self stringsWithRemovedUnwantedTagsFromTrack:track] firstObject];

        }
        __weak typeof(self) weakSelf = self;
        [self.scrobbler loveTrack:filteredName artist:track.artist successHandler:^(NSDictionary *result) {
            DebugMode(@"%@ loved!", track)
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

#pragma mark - Removing unwanted tags
-(NSArray *)stringsWithRemovedUnwantedTagsFromTrack:(Track *)track
{
    NSString *filteredName = [track.trackName copy];
    NSString *filteredAlbum = [track.album copy];

    for (NSString *tag in self.tagsToCut) {
        NSError *error;
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:tag options:NSRegularExpressionCaseInsensitive error:&error];
        NSArray *trackNameMatches = [regex matchesInString:filteredName options:0 range:NSMakeRange(0, filteredName.length)];
        if (trackNameMatches.count) {
            filteredName = [filteredName stringByReplacingOccurrencesOfString:tag withString:@"" options:NSCaseInsensitiveSearch|NSRegularExpressionSearch range:NSMakeRange(0, filteredName.length)];
        }
        NSArray *albumNameMatches = [regex matchesInString:filteredAlbum options:0 range:NSMakeRange(0, filteredAlbum.length)];
        if (albumNameMatches.count) {
            filteredAlbum = [filteredAlbum stringByReplacingOccurrencesOfString:tag withString:@"" options:NSCaseInsensitiveSearch|NSRegularExpressionSearch range:NSMakeRange(0, filteredAlbum.length)];
        }
    }
    return @[filteredName, filteredAlbum];
}

-(void)downloadNewTagsLibraryAndStoreIt
{
    NSURLSession *session = [NSURLSession sharedSession];
    __weak typeof(self) weakSelf = self;
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://raw.githubusercontent.com/rurza/Tags-to-cut/master/tags.json"] cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:5];
    [[session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            NSLog(@"Error downloading tags = %@", [error localizedDescription]);
        }
        if (data.length) {
            NSError *error;
            id tags = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
            if (error) {
                NSLog(@"Failed parsing JSON file. %@", error.localizedDescription);
            }
            if ([tags isKindOfClass:[NSDictionary class]]) {
                NSArray *tagsStrings = [tags objectForKey:@"tags"];
                if (tagsStrings.count) {
                    weakSelf.tagsToCut = tagsStrings;
                    NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
                    NSString *plistPath = [rootPath stringByAppendingPathComponent:@"NepTunesTagsToCut.plist"];
                    BOOL fileSaved = [tagsStrings writeToFile:plistPath atomically:YES];
                    if (fileSaved) {
                        DebugMode(@"Cut list saved")
                    }
                }
            }
        }
    }] resume];

}

#pragma mark - Overrided Methods

-(NSString *)description
{
    return [NSString stringWithFormat:@"scrobbler: username = %@, iTunes: currentTrack = %@, duration = %f", self.scrobbler.username, self.musicPlayer.currentTrack.trackName, self.musicPlayer.currentTrack.duration];
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

#pragma mark - Music Player
-(MusicPlayer *)musicPlayer
{
    if (!_musicPlayer) {
        _musicPlayer = [MusicPlayer sharedPlayer];
    }
    return _musicPlayer;
}

@end
