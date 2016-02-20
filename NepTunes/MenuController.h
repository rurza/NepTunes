//
//  MenuController.h
//  NepTunes
//
//  Created by rurza on 08/08/15.
//  Copyright (c) 2015 micropixels. All rights reserved.
//
@import Cocoa;

#import <Foundation/Foundation.h>

@interface MenuController : NSObject

@property (weak, nonatomic) IBOutlet NSMenuItem *loveSongMenuTitle;
@property (weak, nonatomic) IBOutlet NSMenuItem *profileMenuTitle;
@property (weak, nonatomic) IBOutlet NSMenuItem *similarArtistMenuTtitle;
@property (nonatomic) IBOutlet NSMenu *statusMenu;

+(instancetype)sharedController;
-(IBAction)loveSong:(id)sender;
-(IBAction)showUserProfile:(id)sender;
-(IBAction)showSimilarArtists:(id)sender;
-(IBAction)openPreferences:(id)sender;
-(IBAction)quit:(id)sender;
-(void)forceLogOut;
-(void)updateMenu;
-(void)prepareRecentItemsMenu;
-(void)installStatusBar;
-(void)removeStatusBarItem;
-(void)hideRecentMenu;
-(void)showRecentMenu;
-(void)blinkMenuIcon;

@end
