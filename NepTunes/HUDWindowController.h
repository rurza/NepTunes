//
//  HUDWindowController.h
//  NepTunes
//
//  Created by rurza on 13/03/16.
//  Copyright © 2016 micropixels. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface HUDWindowController : NSWindowController

@property (strong) IBOutlet NSImageView *centerImageView;
@property (strong) IBOutlet NSTextField *bottomLabel;
@property (strong) IBOutlet NSImageView *bottomImageView;
@property (strong) IBOutlet NSVisualEffectView *bottomVisualEffectView;

-(void)presentHUD;

@end
