//
//  VolumeViewController.m
//  NepTunes
//
//  Created by rurza on 15/02/16.
//  Copyright © 2016 micropixels. All rights reserved.
//

#import "VolumeViewController.h"
#import "MusicController.h"
#import "CoverWindowController.h"
#import "ControlViewController.h"

@interface VolumeViewController ()
@property (weak) IBOutlet CoverWindowController *coverWindowController;

@end

@implementation VolumeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

-(void)viewWillAppear
{
    self.slider.integerValue = [MusicController sharedController].iTunes.soundVolume;
}

- (IBAction)changeVolume:(NSSlider *)sender
{
    [self updateVolumeWithValue:sender.integerValue];
}

-(void)updateVolumeWithValue:(NSInteger)value
{
    [MusicController sharedController].iTunes.soundVolume = value;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.coverWindowController.controlViewController updateVolumeIcon];
    });
    self.slider.integerValue = [MusicController sharedController].iTunes.soundVolume;
}

-(void)updateVolumeWithDeltaValue:(NSInteger)delta
{
    NSInteger newValue = [MusicController sharedController].iTunes.soundVolume + delta;
    [self updateVolumeWithValue:newValue];
}

@end
