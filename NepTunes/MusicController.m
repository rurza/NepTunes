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
#import "CoverWindowController.h"
#import "UserNotificationsController.h"
#import "CoverSettingsController.h"
#import "HUDWindowController.h"
#import "SocialMessage.h"
@import Social;
@import Accounts;

#define FOUR_MINUTES 60 * 4
#define DELAY_FOR_RADIO 2

static NSString *const kTrackInfoUpdated = @"trackInfoUpdated";

@interface MusicController ()
@property (nonatomic) MusicScrobbler *musicScrobbler;
@property (nonatomic) SettingsController *settingsController;
@property (nonatomic) IBOutlet MenuController *menuController;
@property (nonatomic) NSTimer* scrobbleTimer;
@property (nonatomic) NSTimer* nowPlayingTimer;
@property (nonatomic) NSTimer* mainTimer;
@property (nonatomic) HUDWindowController *hud;
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
//    [self setupCover];
}

-(void)setupNotifications
{
    [self updateTrackInfo:nil];

    [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                        selector:@selector(updateTrackInfo:)
                                                            name:@"com.apple.iTunes.playerInfo"
                                                          object:nil];
}




-(void)updateTrackInfo:(NSNotification *)note
{
    if (self.settingsController.debugMode) {
        NSLog(@"Notification sent from iTunes");
    }
    [self invalidateTimers];
    self.mainTimer = [NSTimer scheduledTimerWithTimeInterval:DELAY_FOR_RADIO target:self selector:@selector(prepareTrack:) userInfo:note.userInfo ? note.userInfo : nil repeats:NO];
    [self getInfoAboutTrackFromNotificationOrFromiTunes:note.userInfo];
    [self updateCoverWithInfo:note.userInfo];
    [self updateMenu];
    [[NSNotificationCenter defaultCenter] postNotificationName:kTrackInfoUpdated object:nil userInfo:note.userInfo];
}

-(void)prepareTrack:(NSTimer *)timer
{
    if (self.settingsController.debugMode) {
        NSLog(@"prepareTrack called");
    }
   
    if ([timer isValid]) {
        [self getInfoAboutTrackFromNotificationOrFromiTunes:timer.userInfo];
        [self updateMenu];
        
        if (self.isiTunesRunning) {
            if (self.settingsController.debugMode) {
                NSLog(@"iTunes is running");
            }

            if (self.playerState == iTunesEPlSPlaying && !self.musicScrobbler.currentTrack.itIsNotMusic && self.musicScrobbler.currentTrack) {
                NSTimeInterval trackLength;
                
                
                if (self.currentTrack.artist && self.currentTrack.artist.length) {
                    trackLength = (NSTimeInterval)self.currentTrack.duration;
                }
                else {
                    trackLength = (NSTimeInterval)self.musicScrobbler.currentTrack.duration;
                }
                
                NSTimeInterval scrobbleTime = ((trackLength * (self.settingsController.percentForScrobbleTime.floatValue / 100)) < FOUR_MINUTES) ? (trackLength * (self.settingsController.percentForScrobbleTime.floatValue / 100)) : FOUR_MINUTES;
                
                if ((self.settingsController.percentForScrobbleTime.floatValue / 100) > 0.95) {
                    scrobbleTime -= 2;
                }
                if (self.settingsController.debugMode) {
                    NSLog(@"Scrobble time for track %@ is %f", self.musicScrobbler.currentTrack, scrobbleTime); 
                }
                
                scrobbleTime -=DELAY_FOR_RADIO;
                
                if (scrobbleTime == 0) {
                    scrobbleTime = 16.0f;
                }
                
                if (trackLength >= 31.0f) {
                    self.nowPlayingTimer = [NSTimer scheduledTimerWithTimeInterval:5
                                                                            target:self
                                                                          selector:@selector(nowPlaying)
                                                                          userInfo:nil
                                                                           repeats:NO];
                }
                if (trackLength >= 31.0f) {
                    NSDictionary *userInfo = [timer.userInfo copy];
                    self.scrobbleTimer = [NSTimer scheduledTimerWithTimeInterval:scrobbleTime
                                                                          target:self
                                                                        selector:@selector(scrobble:)
                                                                        userInfo:userInfo
                                                                         repeats:NO];
                }
            }
        }
    }
}

-(void)updateCoverWithInfo:(NSDictionary *)info
{
    if (self.musicScrobbler.currentTrack && self.isiTunesRunning) {
        if (!self.coverWindowController) {
            [self setupCover];
        }
        [self.coverWindowController updateCoverWithTrack:self.musicScrobbler.currentTrack andUserInfo:info];
    } else {
        [self.coverWindowController updateCoverWithTrack:self.musicScrobbler.currentTrack andUserInfo:info];
        [self.coverWindowController.window close];

        self.coverWindowController = nil;
    }
}

-(void)setupCover
{
    CoverSettingsController *coverSettingsController = [[CoverSettingsController alloc] init];
    if (coverSettingsController.showCover) {
        self.coverWindowController = [[CoverWindowController alloc] initWithWindowNibName:@"CoverWindow"];
        if (self.playerState == iTunesEPlSPlaying && self.musicScrobbler.currentTrack) {
            [self.coverWindowController showWindow:self];
            [self.coverWindowController updateCoverWithTrack:self.musicScrobbler.currentTrack andUserInfo:nil];
            [self.coverWindowController.window makeKeyAndOrderFront:nil];
            HUDWindowController *window =[[HUDWindowController alloc] initWithWindowNibName:@"HUDWindowController"];
            [window.window makeKeyAndOrderFront:nil];
            
        }
    }
}

-(void)invalidateTimers
{
    if (self.mainTimer) {
        [self.mainTimer invalidate];
        self.mainTimer = nil;
    }
    if (self.scrobbleTimer) {
        [self.scrobbleTimer invalidate];
        self.scrobbleTimer = nil;
    }
    if (self.nowPlayingTimer) {
        [self.nowPlayingTimer invalidate];
        self.nowPlayingTimer = nil;
    }
    if (self.settingsController.debugMode) {
        NSLog(@"Timers invalidated");
    }
}

-(void)getInfoAboutTrackFromNotificationOrFromiTunes:(NSDictionary *)userInfo
{
//    NSLog(@"%@", userInfo);
    [self.musicScrobbler updateCurrentTrackWithUserInfo:userInfo];
    //2s są po to by Itunes sie ponownie nie wlaczal
    //    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    if (self.musicScrobbler.currentTrack.trackName && self.musicScrobbler.currentTrack.artist && self.musicScrobbler.currentTrack.duration == 0 && self.currentTrack.artist.length) {
        self.musicScrobbler.currentTrack.duration = self.iTunes.currentTrack.duration;
    }
    else if (self.currentTrack.name && self.currentTrack.artist) {
        self.musicScrobbler.currentTrack = [Track trackWithiTunesTrack:self.currentTrack];
    }
    if (!self.settingsController.scrobblePodcastsAndiTunesU) {
        if (self.currentTrack.podcast || self.currentTrack.iTunesU || [userInfo objectForKey:@"Category"] || ([(NSString *)[userInfo objectForKey:@"Store URL"] containsString:@"itms://itunes.com/link?"] && (!self.currentTrack.name || !self.currentTrack.artist))) {
            if (self.settingsController.debugMode) {
                if ([(NSString *)[userInfo objectForKey:@"Store URL"] containsString:@"itms://itunes.com/link?"]) {
                    NSLog(@"userInfo link contains: itms://itunes.com/link? and I don't have name of track or artist in tags");
                }
                if (self.currentTrack.podcast) {
                    NSLog(@"iTunes tells me that this is a podcast");
                }
                if (self.currentTrack.iTunesU) {
                    NSLog(@"iTunes tells me that this is a iTunes U");
                }
                if ([userInfo objectForKey:@"Category"]) {
                    NSLog(@"userInfo contains Category");
                }
                self.musicScrobbler.currentTrack.itIsNotMusic = YES;
                NSLog(@"This isn't a music track from Library (or Apple Music stream) or iTunes switched playing from one streaming to another.");
            }
        }
    }
}

-(void)loveTrackOniTunes
{
    self.currentTrack.loved = YES;
}

-(void)updateMenu
{
    [self.menuController updateMenu];
}

-(void)scrobble:(NSTimer *)timer
{
    [self.musicScrobbler scrobbleCurrentTrack];
}

-(void)nowPlaying
{
    [self.musicScrobbler nowPlayingCurrentTrack];
}

-(void)loveTrackWithCompletionHandler:(void(^)(void))handler
{
    SettingsController *settings = [SettingsController sharedSettings];
    if (settings.session) {
        [self.musicScrobbler loveCurrentTrackWithCompletionHandler:^(Track *track, NSImage *artwork) {
            [[UserNotificationsController sharedNotificationsController] displayNotificationThatTrackWasLoved:track withArtwork:(NSImage *)artwork];
            if (handler) {
                handler();
            }
        }];
    }
    if (settings.integrationWithiTunes && settings.loveTrackOniTunes) {
        [self loveTrackOniTunes];
        if (handler && !settings.session) {
            handler();
        }
    }
//    NSSharingService *service = [NSSharingService sharingServiceNamed:NSSharingServiceNamePostOnFacebook];
//
//    if (settings.automaticallyShareOnFacebook && [service canPerformWithItems:nil]) {
//        ACAccountStore *accountStore = [[ACAccountStore alloc] init];
//        
//        ACAccountType *accountTypeFacebook =
//        [accountStore accountTypeWithAccountTypeIdentifier:
//         ACAccountTypeIdentifierFacebook];
//        
//        NSDictionary *options = @{
//                                  ACFacebookAppIdKey: @"557679431058428",
//                                  ACFacebookPermissionsKey: @[@"basic_info", @"publish_actions"],
//                                  ACFacebookAudienceKey: ACFacebookAudienceFriends
//                                  };
//        
//        [accountStore requestAccessToAccountsWithType:accountTypeFacebook options:options completion:^(BOOL granted, NSError *error) {
//            if (granted) {
//                
//                NSArray *accounts = [accountStore accountsWithAccountType:accountTypeFacebook];
//                ACAccount* facebookAccount = [accounts lastObject];
//                
//                [SocialMessage messageForLovedTrackWithCompletionHandler:^(NSString *message) {
//                    NSDictionary *parameters =
//                    @{@"access_token":facebookAccount.credential.oauthToken,
//                      @"message": message};
//                    
//                    NSURL *feedURL = [NSURL
//                                      URLWithString:@"https://graph.facebook.com/me/feed"];
//                    
//                    SLRequest *feedRequest = [SLRequest requestForServiceType:SLServiceTypeFacebook requestMethod:SLRequestMethodPOST URL:feedURL parameters:parameters];
//                    
//                    [feedRequest performRequestWithHandler:^(NSData *responseData,
//                                                 NSHTTPURLResponse *urlResponse, NSError *error)
//                     {
//                         NSLog(@"Request failed, %@", [urlResponse description]);
//                     }];
//                }];
//            } else {
//                NSLog(@"Access Denied");
//                NSLog(@"[%@]",[error localizedDescription]);
//            }
//        }];
//    }
//    
//    service = [NSSharingService sharingServiceNamed:NSSharingServiceNamePostOnTwitter];
//
//    if (settings.automaticallyShareOnTwitter && [service canPerformWithItems:nil]) {
//        ACAccountStore *account = [[ACAccountStore alloc] init];
//        ACAccountType *accountType = [account accountTypeWithAccountTypeIdentifier:
//                                      ACAccountTypeIdentifierTwitter];
//        
//        [account requestAccessToAccountsWithType:accountType options:nil
//                                      completion:^(BOOL granted, NSError *error)
//         {
//             if (granted == YES)
//             {
//                 NSArray *arrayOfAccounts = [account
//                                             accountsWithAccountType:accountType];
//                 
//                 if ([arrayOfAccounts count] > 0)
//                 {
//                     ACAccount *twitterAccount = [arrayOfAccounts lastObject];
//                     [SocialMessage messageForLovedTrackWithCompletionHandler:^(NSString *message) {
//                         NSDictionary *parameters = @{@"status": message};
//                         
//                         NSURL *requestURL = [NSURL
//                                              URLWithString:@"http://api.twitter.com/1/statuses/update.json"];
//                         
//                         SLRequest *postRequest = [SLRequest requestForServiceType:SLServiceTypeTwitter
//                                                                     requestMethod:SLRequestMethodPOST
//                                                                               URL:requestURL
//                                                                        parameters:parameters];
//                         
//                         postRequest.account = twitterAccount;
//                         
//                         [postRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error)
//                          {
//                              if (settings.debugMode) {
//                                  NSLog(@"Twitter HTTP response: %li", (long)[urlResponse statusCode]);
//                              }
//                          }];
//                         
//                     }];
//                 }
//             }
//             else {
//                 if (settings.debugMode) {
//                     NSLog(@"Access to Twitter Accounts not granted: %@", error.localizedDescription);
//                 }
//             }
//         }];
//    }
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

#pragma mark - iTunes

-(iTunesApplication *)iTunes
{
    if (!_iTunes) {
        _iTunes = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
    }
    return _iTunes;
}

-(iTunesEPlS)playerState
{
    if (self.isiTunesRunning) {
        return self.iTunes.playerState;
    }
    return iTunesEPlSStopped;
}

-(BOOL)isiTunesRunning
{
    return self.iTunes.isRunning;
}

-(iTunesTrack *)currentTrack
{
    if (self.isiTunesRunning) {
        return self.iTunes.currentTrack;
    }
    return nil;
}

-(NSImage *)currentTrackCover
{
    iTunesTrack *track = self.currentTrack;
    for (iTunesArtwork *artwork in track.artworks) {
        if ([artwork.data isKindOfClass:[NSImage class]]) {
            return artwork.data;
        } else if ([artwork.rawData isKindOfClass:[NSData class]]) {
            return [[NSImage alloc] initWithData:artwork.rawData];
        }
    }
    return nil;
}

#pragma mark - Spotify

@end