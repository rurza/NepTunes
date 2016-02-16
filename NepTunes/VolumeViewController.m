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

@interface VolumeViewController ()
@property (weak) IBOutlet CoverWindowController *coverWindowController;

@end

@implementation VolumeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do view setup here.
}

-(void)viewWillAppear
{
    self.slider.integerValue = [MusicController sharedController].iTunes.soundVolume;
}

- (IBAction)changeVolume:(NSSlider *)sender
{
    [MusicController sharedController].iTunes.soundVolume = sender.integerValue;
}



@end
