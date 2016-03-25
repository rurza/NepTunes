//
//  HUDWindowController.m
//  NepTunes
//
//  Created by rurza on 13/03/16.
//  Copyright © 2016 micropixels. All rights reserved.
//

#import "HUDWindowController.h"

#define ANIMATION_DELAY 3

@interface HUDWindowController ()
@property (nonatomic) NSTimer *animationTimer;
@property (nonatomic, readwrite, getter=isVisible) BOOL visible;
@property (nonatomic) BOOL inTransition;

@end

@implementation HUDWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    self.shouldCascadeWindows = NO;
    
    self.window.contentView.wantsLayer = YES;
    self.window.opaque = NO;
    [self.window setBackgroundColor:[NSColor clearColor]];
    
    
    self.window.level = NSScreenSaverWindowLevel;
    self.window.alphaValue = 0;
    self.visualEffectView.layer.cornerRadius = 6;
    self.centerImageView.image.template = YES;
    self.bottomImageView.image.template = YES;
    self.starsImageView.image.template = YES;
    self.bottomLabel.hidden = YES;
    [self.window makeKeyAndOrderFront:nil];
}


-(void)animateWindowOpacity:(CGFloat)opacity
{
    if (opacity > 0) {
        self.visible = YES;
    } else {
        self.inTransition = YES;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.visible = NO;
            self.inTransition = NO;
            [self.window close];
        });
    }
  
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
    [self animateWindowOpacity:1];
    self.animationTimer = [NSTimer scheduledTimerWithTimeInterval:self.visibilityTime target:self selector:@selector(fadeoutWindow) userInfo:nil repeats:NO];
}

-(void)updateCurrentHUD
{
    if (self.visible) {
        [self.animationTimer invalidate];
        self.animationTimer = nil;
        self.animationTimer = [NSTimer scheduledTimerWithTimeInterval:self.visibilityTime target:self selector:@selector(fadeoutWindow) userInfo:nil repeats:NO];
    } else if (self.inTransition) {
        self.animationTimer = nil;
        self.animationTimer = [NSTimer scheduledTimerWithTimeInterval:self.visibilityTime target:self selector:@selector(fadeoutWindow) userInfo:nil repeats:NO];
        [NSAnimationContext beginGrouping];
        [[NSAnimationContext currentContext] setDuration:0.25];
        [[self.window animator] setAlphaValue:1];
        [NSAnimationContext endGrouping];
    }
    self.bottomImageView.image = nil;
    self.centerImageView.image = nil;
    self.starsImageView.image = nil;
    self.bottomVisualEffectView.hidden = YES;
    self.bottomLabel.hidden = YES;
    self.bottomLabel.stringValue = @"";
}

-(NSUInteger)visibilityTime
{
    if (!_visibilityTime) {
        _visibilityTime = 3;
    }
    return _visibilityTime;
}

@end
