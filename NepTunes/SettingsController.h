//
//  SettingsController.h
//  NepTunes
//
//  Created by rurza on 22/01/16.
//  Copyright © 2016 micropixels. All rights reserved.
//

@import AppKit;
@class MenuController;

@interface SettingsController : NSObject

@property (nonatomic) NSImage *userAvatar;
@property (nonatomic) BOOL launchAtLogin;
@property (nonatomic) BOOL hideStatusBarIcon;
@property (nonatomic) BOOL openPreferencesWhenThereIsNoUser;
@property (nonatomic) BOOL hideNotifications;
@property (nonatomic) BOOL userWasLoggedOut;
@property (nonatomic) BOOL debugMode;

//Menu
@property (nonatomic) BOOL integrationWithMusicPlayer;
@property (nonatomic) BOOL loveTrackOniTunes;
@property (nonatomic) BOOL showSimilarArtistsOnMusicPlayer;
@property (nonatomic) BOOL showRecentTrackOnMusicPlayer;

//Player
@property (nonatomic) BOOL spotifyOnly;
@property (nonatomic) BOOL iTunesOnly;

//Scrobbler And General
@property (nonatomic) NSString *session;
@property (nonatomic) NSString *username;
@property (nonatomic) NSNumber *numberOfTracksInRecent;
@property (nonatomic) NSNumber *percentForScrobbleTime;
@property (nonatomic) BOOL scrobblePodcastsAndiTunesU;
@property (nonatomic) BOOL scrobbleFromSpotify;
@property (nonatomic) BOOL cutExtraTags;

@property (nonatomic,weak) IBOutlet NSPopUpButton *numberOfRecentItems;
@property (nonatomic,weak) IBOutlet NSButton *launchAtLoginCheckbox;
@property (nonatomic,weak) IBOutlet NSButton *hideStatusBarCheckbox;
@property (nonatomic,weak) IBOutlet NSButton *openPreferencesWhenThereIsNoUserCheckbox;
@property (nonatomic,weak) IBOutlet NSButton *hideNotificationsCheckbox;
@property (nonatomic,weak) IBOutlet NSSlider *percentForScrobbleTimeSlider;
@property (nonatomic,weak) IBOutlet NSButton *scrobblePodcastsAndiTunesUCheckbox;
@property (nonatomic,weak) IBOutlet NSButton *scrobbleFromSpotifyCheckbox;
@property (nonatomic,weak) IBOutlet NSButton *cutExtraTagsCheckbox;

//Menu
@property (nonatomic,weak) IBOutlet NSButton *integrationWithMusicPlayerCheckbox;
@property (nonatomic,weak) IBOutlet NSButton *loveTrackOniTunesCheckbox;
@property (nonatomic,weak) IBOutlet NSButton *showSimilarArtistsOnMusicPlayerCheckbox;
@property (nonatomic,weak) IBOutlet NSButton *showRecentTrackOnMusicPlayerCheckbox;

//Social
@property (nonatomic) BOOL automaticallyShareOnFacebook;
@property (nonatomic) BOOL automaticallyShareOnTwitter;
@property (nonatomic,weak) IBOutlet NSButton *automaticallyShareOnFacebookCheckbox;
@property (nonatomic,weak) IBOutlet NSButton *automaticallyShareOnTwitterCheckbox;

+(SettingsController *)sharedSettings;
-(void)saveSettings;
-(IBAction)changeNumberOfRecentItems:(NSPopUpButton *)popUp;
-(IBAction)toggleLaunchAtLogin:(NSButton *)sender;
-(IBAction)toggleHideStatusBarIcon:(NSButton *)sender;
-(IBAction)toggleOpenPreferencesWhenThereIsNoUser:(NSButton *)sender;
-(IBAction)toggleHideNotifications:(NSButton *)sender;
//Menu
-(IBAction)toggleIntegrationWithiTunes:(NSButton *)sender;
-(IBAction)toggleLoveTrackOniTunes:(NSButton *)sender;
-(IBAction)toggleShowSimilarArtistsOnAppleMusic:(NSButton *)sender;
-(IBAction)toggleShowRecentTrackIniTunes:(NSButton *)sender;

- (IBAction)toggleScrobblePodcastsAndiTunesU:(NSButton *)sender;
- (IBAction)toggleCutExtraTags:(NSButton *)sender;

//Social
-(IBAction)toggleAutomaticallyShareOnFacebook:(NSButton *)sender;
-(IBAction)toggleAutomaticallyShareOnTwitter:(NSButton *)sender;
//Spotify
-(IBAction)toggleScrobbleFromSpotify:(NSButton *)sender;

@end