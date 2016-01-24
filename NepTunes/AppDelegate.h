//
//  AppDelegate.h
//  NepTunes
//
//  Created by rurza on 19.11.2014.
//  Copyright (c) 2014 micropixels. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MenuController.h"


@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (weak, nonatomic) IBOutlet NSWindow *window;
@property (weak, nonatomic) IBOutlet MenuController *menuController;
@property (weak, nonatomic) IBOutlet NSToolbar *settingsToolbar;
@property (nonatomic) NSString *lastChosenToolbarIdentifier;

@end

