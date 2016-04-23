//
//  ControlViewController.m
//  NepTunes
//
//  Created by rurza on 15/02/16.
//  Copyright © 2016 micropixels. All rights reserved.
//

#import "ControlViewController.h"
#import "MusicController.h"
#import "SettingsController.h"
#import "MusicScrobbler.h"
#import "Track.h"
#import "CoverSettingsController.h"
#import <POP.h>
#import "MenuController.h"
#import "MusicPlayer.h"

static NSUInteger const kFPS = 30;
static NSUInteger const kNumberOfFrames = 10;

@interface ControlViewController () <NSPopoverDelegate>
@property (nonatomic) NSImage *playImage;
@property (nonatomic) NSImage *pauseImage;
@property (nonatomic) NSImage *emptyHeartImage;
@property (nonatomic) NSUInteger animationCurrentStep;
@property (nonatomic) MusicPlayer *musicPlayer;
@end

@implementation ControlViewController

-(void)awakeFromNib
{
    self.loveButton.image.template = YES;
    self.playButton.image.template = YES;
    self.forwardButton.image.template = YES;
    self.backwardButton.image.template = YES;
    self.volumeButton.image.template = YES;
    self.shareButton.image.template = YES;
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                        selector:@selector(updateControlsState:)
                                                            name:@"com.apple.iTunes.playerInfo"
                                                          object:nil];
    [self.forwardButton addGestureRecognizer:[[NSPressGestureRecognizer alloc] initWithTarget:self action:@selector(forwardButtonWasPressed:)]];
    [self.backwardButton addGestureRecognizer:[[NSPressGestureRecognizer alloc] initWithTarget:self action:@selector(backwardButtonWasPressed:)]];
    self.volumePopover.delegate = self;
    [self updateControlsState:nil];
    self.shareButton.action = @selector(openShareMenu:);
    self.shareButton.target = self;
}

-(void)updateControlsState:(NSNotification *)note
{
    if (self.musicPlayer.playerState == MusicPlayerStatePlaying) {
        self.playButton.image = self.pauseImage;
        if ([SettingsController sharedSettings].integrationWithiTunes && self.musicPlayer.currentTrack.loved) {
            self.loveButton.image = [NSImage imageNamed:@"fullheart"];
            self.loveButton.image.template = YES;
        } else {
            self.loveButton.image = self.emptyHeartImage;
        }

    } else {
        self.playButton.image = self.playImage;
    }
    if ([[note.userInfo objectForKey:@"Back Button State"] isEqualToString:@"Info"]) {
        self.backwardButton.enabled = NO;
        self.backwardButton.alphaValue = 0.5;
    } else {
        self.backwardButton.enabled = YES;
        self.backwardButton.alphaValue = 1;
    }
}

- (IBAction)playOrPauseTrack:(NSButton *)sender
{
    [self.musicPlayer playPause];
}

-(void)backwardButtonWasPressed:(NSGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state == NSGestureRecognizerStateBegan) {
        [self.backwardButton highlight:YES];
        [self.musicPlayer rewind];
    }
    if (gestureRecognizer.state == NSGestureRecognizerStateEnded || gestureRecognizer.state == NSGestureRecognizerStateCancelled || gestureRecognizer.state == NSGestureRecognizerStateFailed) {
        [self.backwardButton highlight:NO];
        [self.musicPlayer resume];
    }
    
}

-(void)forwardButtonWasPressed:(NSGestureRecognizer *)gestureRecognizer
{
    MusicController *musicController = [MusicController sharedController];
    
    if (gestureRecognizer.state == NSGestureRecognizerStateBegan) {
        [self.forwardButton highlight:YES];
        [self.musicPlayer fastForward];
    }
    if (gestureRecognizer.state == NSGestureRecognizerStateEnded || gestureRecognizer.state == NSGestureRecognizerStateCancelled || gestureRecognizer.state == NSGestureRecognizerStateFailed) {
        [self.forwardButton highlight:NO];
        [self.musicPlayer resume];
        
    }
}

-(void)updateVolumeIcon
{
    NSInteger soundVolume = self.musicPlayer.soundVolume;
    if (soundVolume > 66) {
        self.volumeButton.image = [NSImage imageNamed:@"volume-max"];
    } else if (soundVolume > 33) {
        self.volumeButton.image = [NSImage imageNamed:@"volume-mid"];
    } else if (soundVolume > 0) {
        self.volumeButton.image = [NSImage imageNamed:@"volume-min"];
    } else {
        self.volumeButton.image = [NSImage imageNamed:@"volume-mute"];
    }
    self.volumeButton.image.template = YES;
}

- (IBAction)backTrack:(NSButton *)sender
{
    [self.musicPlayer backTrack];
}

- (IBAction)nextTrack:(NSButton *)sender
{
    [self.musicPlayer nextTrack];
}

- (IBAction)loveTrack:(NSButton *)sender
{
    __weak typeof(self) weakSelf = self;
    [[MusicController sharedController] loveTrackWithCompletionHandler:^{
        [weakSelf animationLoveButton];
    }];
}

- (IBAction)changeVolume:(NSButton *)sender
{
    [self.volumePopover showRelativeToRect:sender.bounds ofView:sender preferredEdge:NSMinYEdge];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateVolumeIcon];
    });
}


- (void)popoverWillShow:(NSNotification *)notification
{
    self.delegate.popoverIsShown = YES;
}

-(void)popoverDidClose:(NSNotification *)notification
{
    self.delegate.popoverIsShown = NO;
    NSPoint mouseLoc = [NSEvent mouseLocation]; //get current mouse position
    if (!NSPointInRect(mouseLoc, [self.delegate window].frame)) {
        [self.delegate hideControls];
    }
}

-(void)animationLoveButton
{
    dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, 1.0 / kFPS * NSEC_PER_SEC);
    
    dispatch_after(delay, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        self.animationCurrentStep++;
        
        if (self.animationCurrentStep <= kNumberOfFrames) {
            [self animationLoveButton];
        } else {
            self.animationCurrentStep = 0;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            self.loveButton.image = [self imageForStep:self.animationCurrentStep];
        });
    });
}

#pragma mark - Sharing

-(void)openShareMenu:(NSButton *)button
{
    NSEvent *event = [NSEvent mouseEventWithType:NSLeftMouseDown location:NSPointFromCGPoint(CGPointMake(button.frame.origin.x + button.frame.size.width, button.frame.origin.y + button.frame.size.height)) modifierFlags:NSDeviceIndependentModifierFlagsMask timestamp:0 windowNumber:button.window.windowNumber context:button.window.graphicsContext eventNumber:0 clickCount:1 pressure:1];
    [NSMenu popUpContextMenu:[MenuController sharedController].shareMenu withEvent:event forView:button];
}



#pragma mark - Getters

-(NSImage *)imageForStep:(NSUInteger)step
{
    NSImage *image;
    if (step != 0) {
        image = [NSImage imageNamed:[NSString stringWithFormat:@"heart%lu", (unsigned long)step]];
    } else image = [NSImage imageNamed:@"fullheart"];
    
    [image setTemplate:YES];
    return image;
}


-(NSImage *)playImage
{
    if (!_playImage) {
        _playImage = [NSImage imageNamed:@"play"];
        _playImage.template = YES;
    }
    return _playImage;
}

-(NSImage *)pauseImage
{
    if (!_pauseImage) {
        _pauseImage = [NSImage imageNamed:@"pause"];
        _pauseImage.template = YES;
    }
    return _pauseImage;
}

-(NSImage *)emptyHeartImage
{
    if (!_emptyHeartImage) {
        _emptyHeartImage = [NSImage imageNamed:@"heart"];
        _emptyHeartImage.template = YES;
    }
    return _emptyHeartImage;
}

-(MusicPlayer *)musicPlayer
{
    if (!_musicPlayer) {
        _musicPlayer = [MusicPlayer sharedPlayer];
    }
    return _musicPlayer;
}

-(void)dealloc
{
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self name:@"com.apple.iTunes.playerInfo" object:nil];
}

@end