//
//  HUDWindowController.h
//  NepTunes
//
//  Created by rurza on 13/03/16.
//  Copyright © 2016 micropixels. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface HUDWindowController : NSWindowController

@property (strong, nonatomic) IBOutlet NSImageView *centerImageView;
@property (strong, nonatomic) IBOutlet NSImageView *bottomImageView;
@property (strong) IBOutlet NSImageView *starsImageView;

@property (strong, nonatomic) IBOutlet NSVisualEffectView *bottomVisualEffectView;
@property (strong, nonatomic) IBOutlet NSVisualEffectView *visualEffectView;
@property (strong) IBOutlet NSTextField *bottomLabel;


@property (nonatomic) NSUInteger visibilityTime;
@property (nonatomic, readonly, getter=isVisible) BOOL visible;


-(void)presentHUD;
-(void)updateCurrentHUD;

@end
