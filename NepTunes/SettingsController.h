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
@property (nonatomic) BOOL integrationWithiTunes;
@property (nonatomic) BOOL loveTrackOniTunes;
@property (nonatomic) BOOL showSimilarArtistsOnAppleMusic;
@property (nonatomic) BOOL showRecentTrackIniTunes;

//Scrobbler And General
@property (nonatomic) NSString *session;
@property (nonatomic) NSString *username;
@property (nonatomic) NSNumber *numberOfTracksInRecent;
@property (nonatomic) NSNumber *percentForScrobbleTime;
@property (nonatomic,weak) IBOutlet NSPopUpButton *numberOfRecentItems;
@property (nonatomic,weak) IBOutlet NSButton *launchAtLoginCheckbox;
@property (nonatomic,weak) IBOutlet NSButton *hideStatusBarCheckbox;
@property (nonatomic,weak) IBOutlet NSButton *openPreferencesWhenThereIsNoUserCheckbox;
@property (nonatomic,weak) IBOutlet NSButton *hideNotificationsCheckbox;
@property (nonatomic,weak) IBOutlet NSSlider *percentForScrobbleTimeSlider;

//Menu
@property (nonatomic,weak) IBOutlet NSButton *integrationWithiTunesCheckbox;
@property (nonatomic,weak) IBOutlet NSButton *loveTrackOniTunesCheckbox;
@property (nonatomic,weak) IBOutlet NSButton *showSimilarArtistsOnAppleMusicCheckbox;
@property (nonatomic,weak) IBOutlet NSButton *showRecentTrackIniTunesCheckbox;



@property (nonatomic,weak) IBOutlet MenuController *menuController;

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

@end