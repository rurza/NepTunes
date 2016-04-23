//
//  VolumeViewController.m
//  NepTunes
//
//  Created by rurza on 15/02/16.
//  Copyright © 2016 micropixels. All rights reserved.
//

#import "VolumeViewController.h"
#import "CoverWindowController.h"
#import "ControlViewController.h"
#import "MusicPlayer.h"

@interface VolumeViewController ()
@property (weak) IBOutlet CoverWindowController *coverWindowController;

@end

@implementation VolumeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

-(void)viewWillAppear
{
    self.slider.integerValue = [MusicPlayer sharedPlayer].soundVolume;
}

- (IBAction)changeVolume:(NSSlider *)sender
{
    [self updateVolumeWithValue:sender.integerValue];
}

-(void)updateVolumeWithValue:(NSInteger)value
{
    [MusicPlayer sharedPlayer].soundVolume = value;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.coverWindowController.controlViewController updateVolumeIcon];
    });
    self.slider.integerValue = [MusicPlayer sharedPlayer].soundVolume;
}

-(void)updateVolumeWithDeltaValue:(NSInteger)delta
{
    NSInteger newValue = [MusicPlayer sharedPlayer].soundVolume + delta;
    [self updateVolumeWithValue:newValue];
}

@end
