//
//  PreferencesController.h
//  NepTunes
//
//  Created by rurza on 16/02/16.
//  Copyright © 2016 micropixels. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MenuController.h"

@interface PreferencesController : NSWindowController

@property (weak, nonatomic) IBOutlet MenuController *menuController;
@property (weak, nonatomic) IBOutlet NSToolbar *settingsToolbar;
@property (nonatomic) NSString *lastChosenToolbarIdentifier;

+ (instancetype)sharedPreferences;
- (IBAction)logOut:(id)sender;
- (void)forceLogOut;

@end
