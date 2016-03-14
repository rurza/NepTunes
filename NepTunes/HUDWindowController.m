//
//  HUDWindowController.m
//  NepTunes
//
//  Created by rurza on 13/03/16.
//  Copyright © 2016 micropixels. All rights reserved.
//

#import "HUDWindowController.h"

#define ANIMATION_DELAY 4

@interface HUDWindowController ()
@property (nonatomic) NSTimer *animationTimer;
@end

@implementation HUDWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    self.window.contentView.wantsLayer = YES;
    self.window.opaque = NO;
    [self.window setBackgroundColor:[NSColor clearColor]];

    self.window.contentView.layer.cornerRadius = 6;
    self.bottomVisualEffectView.wantsLayer = YES;
    self.bottomVisualEffectView.layer.cornerRadius = 10;
    self.centerImageView.image.template = YES;
    self.bottomImageView.image.template = YES;
    self.window.level = NSScreenSaverWindowLevel;
    self.window.alphaValue = 0;
 }


-(void)animateWindowOpacity:(CGFloat)opacity
{
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:0.25];
    [[self.window animator] setAlphaValue:opacity];
    [NSAnimationContext endGrouping];
}

-(void)fadeoutWindow
{
    [self animateWindowOpacity:0];
}

-(void)presentHUD
{
    [self.window makeKeyAndOrderFront:nil];
    [self animateWindowOpacity:1];
    self.animationTimer = [NSTimer scheduledTimerWithTimeInterval:ANIMATION_DELAY target:self selector:@selector(fadeoutWindow) userInfo:nil repeats:NO];
}

@end
