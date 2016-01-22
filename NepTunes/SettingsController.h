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
@property (nonatomic) NSString *session;
@property (nonatomic) NSString *username;
@property (nonatomic) NSNumber *numberOfTracksInRecent;
@property (nonatomic,weak) IBOutlet NSPopUpButton *numberOfRecentItems;
@property (nonatomic,weak) IBOutlet NSButton *launchAtLoginCheckbox;
@property (nonatomic,weak) IBOutlet MenuController *menuController;


+(SettingsController *)sharedSettings;
-(void)saveSettings;
-(IBAction)changeNumberOfRecentItems:(NSPopUpButton *)popUp;
-(IBAction)toggleLaunchAtLogin:(NSButton *)sender;

@end
