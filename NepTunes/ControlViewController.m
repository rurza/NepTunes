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
#import <POP.h>

static NSUInteger const kFPS = 30;
static NSUInteger const kNumberOfFrames = 10;

@interface ControlViewController () <NSPopoverDelegate>
@property (nonatomic) NSImage *playImage;
@property (nonatomic) NSImage *pauseImage;
@property (nonatomic) NSImage *emptyHeartImage;
@property (nonatomic) NSUInteger animationCurrentStep;
@end

@implementation ControlViewController

-(void)awakeFromNib
{
    self.loveButton.image.template = YES;
    self.playButton.image.template = YES;
    self.forwardButton.image.template = YES;
    self.backwardButton.image.template = YES;
    self.volumeButton.image.template = YES;
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                        selector:@selector(updateControlsState:)
                                                            name:@"com.apple.iTunes.playerInfo"
                                                          object:nil];
    [self.forwardButton addGestureRecognizer:[[NSPressGestureRecognizer alloc] initWithTarget:self action:@selector(forwardButtonWasPressed:)]];
    [self.backwardButton addGestureRecognizer:[[NSPressGestureRecognizer alloc] initWithTarget:self action:@selector(backwardButtonWasPressed:)]];
    self.volumePopover.delegate = self;
    [self updateControlsState:nil];
    
}

-(void)updateControlsState:(NSNotification *)note
{
    if ([MusicController sharedController].playerState == iTunesEPlSPlaying) {
        self.playButton.image = self.pauseImage;
        if ([SettingsController sharedSettings].integrationWithiTunes && [MusicController sharedController].currentTrack.loved) {
            self.loveButton.image = [NSImage imageNamed:@"fullheart"];
            self.loveButton.image.template = YES;
        } else {
            self.loveButton.image = self.emptyHeartImage;
        }

    } else {
        self.playButton.image = self.playImage;
    }
}

- (IBAction)playOrPauseTrack:(NSButton *)sender
{
    [[MusicController sharedController].iTunes playpause];
}

-(void)backwardButtonWasPressed:(NSGestureRecognizer *)gestureRecognizer
{
    MusicController *musicController = [MusicController sharedController];

    if (gestureRecognizer.state == NSGestureRecognizerStateBegan) {
        [self.backwardButton highlight:YES];
        [musicController.iTunes rewind];
    }
    if (gestureRecognizer.state == NSGestureRecognizerStateEnded || gestureRecognizer.state == NSGestureRecognizerStateCancelled || gestureRecognizer.state == NSGestureRecognizerStateFailed) {
        [self.backwardButton highlight:NO];
        [musicController.iTunes resume];
    }
    
}

-(void)forwardButtonWasPressed:(NSGestureRecognizer *)gestureRecognizer
{
    MusicController *musicController = [MusicController sharedController];
    
    if (gestureRecognizer.state == NSGestureRecognizerStateBegan) {
        [self.forwardButton highlight:YES];
        [musicController.iTunes fastForward];
    }
    if (gestureRecognizer.state == NSGestureRecognizerStateEnded || gestureRecognizer.state == NSGestureRecognizerStateCancelled || gestureRecognizer.state == NSGestureRecognizerStateFailed) {
        [self.forwardButton highlight:NO];
        [musicController.iTunes resume];
        
    }
    
}

-(void)updateVolumeIcon
{
    NSInteger soundVolume = [MusicController sharedController].iTunes.soundVolume;
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
    [[MusicController sharedController].iTunes backTrack];
}

- (IBAction)nextTrack:(NSButton *)sender
{
    [[MusicController sharedController].iTunes nextTrack];
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

-(void)dealloc
{
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self name:@"com.apple.iTunes.playerInfo" object:nil];
}

@end