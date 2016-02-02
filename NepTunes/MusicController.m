//
//  MusicController.m
//  NepTunes
//
//  Created by rurza on 02/02/16.
//  Copyright © 2016 micropixels. All rights reserved.
//

#import "MusicController.h"
#import "MusicScrobbler.h"
#import "SettingsController.h"
#import "MenuController.h"
#import "Track.h"

@interface MusicController ()
@property (nonatomic) MusicScrobbler *musicScrobbler;
@property (nonatomic) SettingsController *settingsController;
@property (nonatomic) IBOutlet MenuController *menuController;
@property (nonatomic) NSTimer* scrobbleTimer;
@property (nonatomic) NSTimer* nowPlayingTimer;
@end

@implementation MusicController

#pragma mark - Responding to notifications

+ (instancetype)sharedController
{
    __strong static id _sharedInstance = nil;
    static dispatch_once_t onlyOnce;
    dispatch_once(&onlyOnce, ^{
        _sharedInstance = [[self _alloc] _init];
        
    });
    return _sharedInstance;
}

+ (id) allocWithZone:(NSZone*)z { return [self sharedController];              }
+ (id) alloc                    { return [self sharedController];              }
- (id) init                     { return self;}
+ (id)_alloc                    { return [super allocWithZone:NULL]; }
- (id)_init                     { return [super init];               }

-(void)awakeFromNib
{
    [self setupNotifications];
}

-(void)setupNotifications
{
    [self updateTrackInfo:nil];

    [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                        selector:@selector(updateTrackInfo:)
                                                            name:@"com.apple.iTunes.playerInfo"
                                                          object:nil];
    
    
}


- (void)updateTrackInfo:(NSNotification *)note {
    [self invalidateTimers];
    [self getInfoAboutTrackFromNotificationOrFromiTunes:note.userInfo];
    [self updateMenu];
    
    if (self.isiTunesRunning) {
        if (self.playerState == iTunesEPlSPlaying) {
            //NSLog(@"%@ by %@ with length = %f after 2 sec.", self.musicScrobbler.trackName, self.musicScrobbler.artist, self.musicScrobbler.duration);
            NSTimeInterval trackLength;
            
            
            if (self.iTunes.currentTrack.artist && self.iTunes.currentTrack.artist.length) {
                trackLength = (NSTimeInterval)self.iTunes.currentTrack.duration;
            }
            else {
                trackLength = (NSTimeInterval)self.musicScrobbler.currentTrack.duration;
            }
            
            NSTimeInterval scrobbleTime = ((trackLength * (self.settingsController.percentForScrobbleTime.floatValue / 100)) < 240) ? (trackLength * (self.settingsController.percentForScrobbleTime.floatValue / 100)) : 240;
            
            if ((self.settingsController.percentForScrobbleTime.floatValue / 100) > 0.95) {
                scrobbleTime -= 2;
            }
            
#if DEBUG
            NSLog(@"Scrobble time for %@ is %f", self.musicScrobbler.currentTrack, scrobbleTime);
#endif
            
            if (trackLength >= 31.0f) {
                self.nowPlayingTimer = [NSTimer scheduledTimerWithTimeInterval:5
                                                                        target:self
                                                                      selector:@selector(nowPlaying)
                                                                      userInfo:nil
                                                                       repeats:NO];
            }
            if (trackLength >= 31.0f) {
                NSDictionary *userInfo = [note.userInfo copy];
                self.scrobbleTimer = [NSTimer scheduledTimerWithTimeInterval:scrobbleTime
                                                                      target:self
                                                                    selector:@selector(scrobble:)
                                                                    userInfo:userInfo
                                                                     repeats:NO];
            }
        }
    }
}

-(void)invalidateTimers
{
    if (self.scrobbleTimer) {
        [self.scrobbleTimer invalidate];
        self.scrobbleTimer = nil;
    }
    if (self.nowPlayingTimer) {
        [self.nowPlayingTimer invalidate];
        self.nowPlayingTimer = nil;
    }
}

-(void)getInfoAboutTrackFromNotificationOrFromiTunes:(NSDictionary *)userInfo
{
    [self.musicScrobbler updateCurrentTrackWithUserInfo:userInfo];
    
    //2s są po to by Itunes sie ponownie nie wlaczal
    //    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    if (self.isiTunesRunning) {
        if (self.musicScrobbler.currentTrack.trackName && self.musicScrobbler.currentTrack.artist && self.musicScrobbler.currentTrack.duration == 0 && self.iTunes.currentTrack.artist.length) {
            self.musicScrobbler.currentTrack.duration = self.iTunes.currentTrack.duration;
        }
        else if (self.iTunes.currentTrack.name && self.iTunes.currentTrack.album) {
            self.musicScrobbler.currentTrack = [Track trackWithiTunesTrack:self.iTunes.currentTrack];
            [self updateMenu];
        }
    }
}

-(void)updateMenu
{
    [self.menuController changeState];
}

-(void)scrobble:(NSTimer *)timer
{
    [self.musicScrobbler scrobbleCurrentTrack];
}

-(void)nowPlaying
{
    [self.musicScrobbler nowPlayingCurrentTrack];
}

#pragma mark - Getters
-(MusicScrobbler *)musicScrobbler
{
    if (!_musicScrobbler) {
        _musicScrobbler = [MusicScrobbler sharedScrobbler];
    }
    return _musicScrobbler;
}


-(SettingsController *)settingsController
{
    if (!_settingsController) {
        _settingsController = [SettingsController sharedSettings];
    }
    return _settingsController;
}


-(iTunesApplication *)iTunes
{
    if (!_iTunes) {
        _iTunes = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
    }
    return _iTunes;
}

-(iTunesEPlS)playerState
{
    return self.iTunes.playerState;
}

-(BOOL)isiTunesRunning
{
    return self.iTunes.isRunning;
}

@end