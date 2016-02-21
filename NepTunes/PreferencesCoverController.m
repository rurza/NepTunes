//
//  PreferencesCoverController.m
//  NepTunes
//
//  Created by rurza on 18/02/16.
//  Copyright © 2016 micropixels. All rights reserved.
//

#import "PreferencesCoverController.h"
#import <POP.h>
#import "CoverView.h"
#import "GetCover.h"
#import "CoverImageView.h"
#import "CoverLabel.h"
#import "Track.h"
#import "MusicScrobbler.h"
#import "MusicController.h"
#import "iTunes.h"

static NSString *const kTrackInfoUpdated = @"trackInfoUpdated";

@interface PreferencesCoverController () <CoverGetterDelegate>
@property (strong, nonatomic) IBOutlet CoverView *coverView;
@property (nonatomic) IBOutlet NSView *shadowView;
@property (nonatomic, strong) IBOutlet NSImageView *blurredView;

@property (nonatomic) BOOL changeTrackAnimation;
@property (nonatomic) CoverLabel *artistLabel;
@property (nonatomic) CoverLabel *trackLabel;
@property (nonatomic) GetCover *getCover;
@property (nonatomic) CoverLabel *infoAboutiTunes;
@end

@implementation PreferencesCoverController

-(void)awakeFromNib
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateCover:) name:kTrackInfoUpdated object:nil];
    [self setupCoverView];
}


#pragma mark - Album Cover

-(void)setupCoverView
{
    [self.shadowView.layer setBackgroundColor:CGColorCreateGenericRGB(0.0, 0.0, 0.0, 1)];
    [self updateCoverWithTrack:[MusicScrobbler sharedScrobbler].currentTrack andUserInfo:nil andFullInfo:NO];
}

-(void)updateCover:(NSNotification *)note
{
    [self updateCoverWithTrack:[MusicScrobbler sharedScrobbler].currentTrack andUserInfo:note.userInfo andFullInfo:YES];
}

-(void)updateCoverWithTrack:(Track *)track andUserInfo:(NSDictionary *)userInfo andFullInfo:(BOOL)fullInfo
{
    if (track) {
        [self updateWithTrack:track];
        if ([MusicController sharedController].isiTunesRunning) {
            __weak typeof(self) weakSelf = self;
            if ([MusicController sharedController].playerState == iTunesEPlSPlaying) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (fullInfo) {
                        [weakSelf displayFullInfoForTrack:track];
                    }
                });
            }
            [self.getCover getCoverWithTrack:track withCompletionHandler:^(NSImage *cover) {
                [weakSelf updateWith:track andCover:cover];
            }];
        }
    } else {
        Track *noTrack;
        if (![MusicController sharedController].isiTunesRunning) {
            noTrack = [[Track alloc] initWithTrackName:@"Turn on iTunes" artist:@"" album:@"" andDuration:0];
        } else {
            noTrack = [[Track alloc] initWithTrackName:@"Pause/play track to refresh" artist:@"" album:@"" andDuration:0];
        }
        [self updateWith:noTrack andCover:[self.getCover defaultCover]];
        if (fullInfo) {
            [self displayFullInfoForTrack:noTrack];
        }
    }
}

-(void)animateCover
{
    if (![MusicScrobbler sharedScrobbler].currentTrack) {
        [self updateCoverWithTrack:nil andUserInfo:nil andFullInfo:YES];
    } else {
        [self updateCoverWithTrack:[MusicScrobbler sharedScrobbler].currentTrack andUserInfo:nil andFullInfo:YES];
    }
}

-(void)makeBlurredBackgroundWithImage:(NSImage *)image
{
    CIImage *backgroundCover = [CIImage imageWithData:image.TIFFRepresentation];
    CIFilter *blurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
    [blurFilter setDefaults];
    [blurFilter setValue:backgroundCover forKey:@"inputImage"];
    NSInteger blur = 24;
    [blurFilter setValue:@(blur) forKey:@"inputRadius"];
    CIImage *result = [blurFilter valueForKey:kCIOutputImageKey];
    
    result = [result imageByCroppingToRect:(CGRect){
        .origin.x = 0,
        .origin.y = 0,
        .size.width = backgroundCover.extent.size.width,
        .size.height = backgroundCover.extent.size.height
    }];
    
    NSImage *mask = [NSImage imageNamed:@"mask"];
    CIFilter *maskWithBlended = [CIFilter filterWithName:@"CIBlendWithAlphaMask"];
    CIImage *maskImage = [CIImage imageWithData:mask.TIFFRepresentation];
    [maskWithBlended setValue:maskImage forKey:@"inputMaskImage"];
    [maskWithBlended setValue:result forKey:kCIInputImageKey];
    result = [maskWithBlended valueForKey:kCIOutputImageKey];
    NSCIImageRep *rep = [NSCIImageRep imageRepWithCIImage:result];
    NSImage *nsImage = [[NSImage alloc] initWithSize:rep.size];
    [nsImage addRepresentation:rep];
    self.blurredView.image = nsImage;
}

-(void)updateWith:(Track *)track andCover:(NSImage *)cover
{
    self.coverView.coverImageView.image = cover;
    [self updateWithTrack:track];
    [self makeBlurredBackgroundWithImage:cover];
}

-(void)updateWithTrack:(Track *)track
{
    self.coverView.titleLabel.stringValue = [NSString stringWithFormat:@"%@",track.trackName];
}


-(void)fadeCover:(BOOL)direction
{
    POPBasicAnimation *fadeInAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerOpacity];
    if (direction) {
        fadeInAnimation.toValue = @(1);
        [self.coverView.coverImageView.layer pop_addAnimation:fadeInAnimation forKey:@"coverImageView opacity"];
    } else {
        fadeInAnimation.toValue = @(0);
        [self.coverView.coverImageView.layer pop_addAnimation:fadeInAnimation forKey:@"coverImageView opacity"];
    }
}

-(void)trackInfoShouldBeRemoved
{
    [self fadeCover:NO];
}

-(void)trackInfoShouldBeDisplayed
{
    [self fadeCover:YES];
}



-(void)displayFullInfoForTrack:(Track *)track
{
    if (self.changeTrackAnimation) {
        self.artistLabel.stringValue = [NSString stringWithFormat:@"%@", track.artist];
        self.trackLabel.stringValue = [NSString stringWithFormat:@"%@", track.trackName];
        [self updateHeightForLabels];
        [self updateOriginsOfLabels];
        return;
    }
    self.changeTrackAnimation = YES;
    CALayer *layer = self.coverView.titleLabel.layer;
    layer.opacity = 0;
    
    __weak typeof(self) weakSelf = self;
    POPBasicAnimation *showFullInfoAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPViewFrame];
    showFullInfoAnimation.toValue = [NSValue valueWithRect:self.coverView.bounds];
    showFullInfoAnimation.completionBlock = ^(POPAnimation *animation, BOOL completion) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf hideFullTrackInfo];
        });
    };
    [self.coverView.artistView pop_addAnimation:showFullInfoAnimation forKey:@"frame"];
    weakSelf.artistLabel.stringValue = [NSString stringWithFormat:@"%@", track.artist];
    weakSelf.trackLabel.stringValue = [NSString stringWithFormat:@"%@", track.trackName];
    [self updateHeightForLabels];
    [self updateOriginsOfLabels];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        POPBasicAnimation *labelOpacity = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerOpacity];
        labelOpacity.toValue = @(1);
        [self.artistLabel.layer pop_addAnimation:labelOpacity forKey:@"opacity"];
        [self.trackLabel.layer pop_addAnimation:labelOpacity forKey:@"opacity"];
    });
}


-(void)hideFullTrackInfo
{
    CALayer *layer = self.coverView.titleLabel.layer;
    __weak typeof(self) weakSelf = self;
    POPSpringAnimation *labelOpacity = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerOpacity];
    labelOpacity.toValue = @(0);
    labelOpacity.completionBlock = ^(POPAnimation *animation, BOOL completion) {
        POPSpringAnimation *hideFullInfoAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPViewFrame];
        hideFullInfoAnimation.completionBlock = ^(POPAnimation *animation, BOOL completion) {
        };
        hideFullInfoAnimation.springBounciness = 14;
        hideFullInfoAnimation.toValue = [NSValue valueWithRect:NSMakeRect(0, 0, 160, 26)];
        [weakSelf.coverView.artistView pop_addAnimation:hideFullInfoAnimation forKey:@"frame"];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            POPSpringAnimation *titleLabelOpacity = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerOpacity];
            titleLabelOpacity.toValue = @(1);
            titleLabelOpacity.completionBlock = ^(POPAnimation *animation, BOOL completion) {
                weakSelf.changeTrackAnimation = NO;
            };
            [layer pop_addAnimation:titleLabelOpacity forKey:@"titlelabel opacity"];
        });
        
        
    };
    [self.artistLabel.layer pop_addAnimation:labelOpacity forKey:@"opacity"];
    [self.trackLabel.layer pop_addAnimation:labelOpacity forKey:@"opacity"];
}

-(void)updateHeightForLabels
{
    for (NSTextField *label in @[self.artistLabel, self.trackLabel]) {
        NSRect r = NSMakeRect(0, 0, [label frame].size.width,
                              MAXFLOAT);
        NSSize s = [[label cell] cellSizeForBounds:r];
        [label setFrameSize:s];
    }
}

-(void)updateOriginsOfLabels
{
    NSUInteger labelsHeight = self.artistLabel.frame.size.height + self.trackLabel.frame.size.height;
    if (labelsHeight >= 130) {
        NSTextField *higherLabel = self.artistLabel;
        for (NSTextField *label in @[self.artistLabel, self.trackLabel]) {
            if (label.frame.size.height >= higherLabel.frame.size.height) {
                higherLabel = label;
            }
        }
        higherLabel.frame = NSMakeRect(0, 0, higherLabel.frame.size.width, higherLabel.frame.size.height - ((self.artistLabel.frame.size.height + self.trackLabel.frame.size.height) - 130));
        labelsHeight = self.artistLabel.frame.size.height + self.trackLabel.frame.size.height;
        
    }
    if (self.artistLabel.stringValue.length) {
        self.trackLabel.frame = NSMakeRect(10, (160-labelsHeight)/2-5, 140, self.trackLabel.frame.size.height);
        self.artistLabel.frame = NSMakeRect(10, (160-labelsHeight)/2+5 + self.trackLabel.frame.size.height, 140, self.artistLabel.frame.size.height);
    } else {
        self.artistLabel.frame = NSMakeRect(0, 0, 0, 0);
        self.trackLabel.frame = NSMakeRect(10, (160-labelsHeight)/2, 140, self.trackLabel.frame.size.height);
    }

}

-(CoverLabel *)artistLabel
{
    if (!_artistLabel) {
        _artistLabel  = [[CoverLabel alloc] initWithFrame:NSMakeRect(10, 80, 140, 60)];
        _artistLabel.font = [NSFont systemFontOfSize:15];
        [self.coverView.artistView addSubview:_artistLabel];
    }
    return _artistLabel;
}

-(CoverLabel *)trackLabel
{
    if (!_trackLabel) {
        _trackLabel  = [[CoverLabel alloc] initWithFrame:NSMakeRect(10, 20, 140, 60)];
        _trackLabel.font = [NSFont systemFontOfSize:13];
        [self.coverView.artistView addSubview:_trackLabel];
    }
    return _trackLabel;
}

-(GetCover *)getCover
{
    if (!_getCover) {
        _getCover = [[GetCover alloc] init];
        _getCover.delegate = self;
    }
    return _getCover;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kTrackInfoUpdated object:nil];
    CGColorRelease(self.shadowView.layer.backgroundColor);
}
@end
