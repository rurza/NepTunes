//
//  CoverWindowController.m
//  NepTunes
//
//  Created by rurza on 11/02/16.
//  Copyright © 2016 micropixels. All rights reserved.
//

#import "CoverWindowController.h"
#import "Track.h"
#import "CoverWindow.h"
#import "CoverImageView.h"
#import "MusicController.h"
#import "iTunesSearch.h"
#import "CoverView.h"
#import "GetCover.h"

@import QuartzCore;

@interface CoverWindowController () <CoverGetterDelegate>
@property (nonatomic) CoverWindow *window;
@property (nonatomic) BOOL changeTrackAnimation;
@property (nonatomic) NSTextField *artistLabel;
@property (nonatomic) NSTextField *trackLabel;
@end

@implementation CoverWindowController
@dynamic window;

- (void)windowDidLoad {
    [super windowDidLoad];

}

-(void)updateCoverWithTrack:(Track *)track andUserInfo:(NSDictionary *)userInfo
{
    if (track) {
        [self displayFullInfoForTrack:track];
        [self updateWithTrack:track];
        [GetCover sharedInstance].delegate = self;
        if (self.window && [MusicController sharedController].isiTunesRunning) {
            __weak typeof(self) weakSelf = self;
            [[GetCover sharedInstance] getCoverWithTrack:track withCompletionHandler:^(NSImage *cover) {
                [weakSelf updateWith:track andCover:cover];
            }];
        } else {
            [self animateWindowOpacity:0];
        }
    } else {
        self.window.alphaValue = 0;
    }
}

-(void)updateWith:(Track *)track andCover:(NSImage *)cover
{
    CoverWindow *coverWindow = (CoverWindow *)self.window;
    coverWindow.coverView.coverImageView.image = cover;
    [self updateWithTrack:track];
}

-(void)updateWithTrack:(Track *)track
{
    CoverWindow *coverWindow = (CoverWindow *)self.window;
    coverWindow.coverView.titleLabel.stringValue = [NSString stringWithFormat:@"%@",track.trackName];
}


-(void)fadeCover:(BOOL)direction
{
    CABasicAnimation *fadeAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fadeAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    fadeAnimation.cumulative = YES;
    fadeAnimation.duration = .3;
    if (direction) {
        if (self.window.coverView.coverImageView.layer.opacity == 0) {
            fadeAnimation.fromValue = @(0);
            fadeAnimation.toValue = @(1);
            [self.window.coverView.coverImageView.layer addAnimation:fadeAnimation forKey:@"fade in"];
            self.window.coverView.coverImageView.layer.opacity = 1.0;
        }
    } else {
        if (self.window.coverView.coverImageView.layer.opacity == 1) {
            CABasicAnimation *fadeAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
            fadeAnimation.fromValue = @(1);
            fadeAnimation.toValue = @(0);
            [self.window.coverView.coverImageView.layer addAnimation:fadeAnimation forKey:@"fade out"];
            self.window.coverView.coverImageView.layer.opacity = 0;
        }
    }

}

-(void)trackInfoShouldBeRemoved
{
    [self fadeCover:NO];
}

-(void)trackInfoShouldBeDisplayed
{
    if (self.window.alphaValue == 0) {
        [self animateWindowOpacity:1.0];
    }
    [self fadeCover:YES];
}

-(void)animateWindowOpacity:(CGFloat)opacity
{
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:0.25];
    [[self.window animator] setAlphaValue:opacity];
    [NSAnimationContext endGrouping];
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
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:.45];
    [NSAnimationContext currentContext].timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [[self.window.coverView.artistView animator] setFrame:self.window.coverView.frame];
    [NSAnimationContext endGrouping];
    
    CALayer *layer = self.window.coverView.titleLabel.layer;
    CABasicAnimation *originalTitleOpacity = [CABasicAnimation animationWithKeyPath:@"opacity"];
    originalTitleOpacity.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    originalTitleOpacity.duration = .25;
    originalTitleOpacity.fromValue = @(1);
    originalTitleOpacity.toValue = @(0);
    layer.opacity = 0;
    [layer addAnimation:originalTitleOpacity forKey:@"opacity"];
    
    
    self.artistLabel.stringValue = [NSString stringWithFormat:@"%@", track.artist];
    self.trackLabel.stringValue = [NSString stringWithFormat:@"%@", track.trackName];
    [self updateHeightForLabels];
    [self updateOriginsOfLabels];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        CABasicAnimation *labelOpacity = [CABasicAnimation animationWithKeyPath:@"opacity"];
        labelOpacity.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        labelOpacity.duration = .45;
        labelOpacity.fromValue = @(0);
        labelOpacity.toValue = @(1);
        self.artistLabel.layer.opacity = 1;
        self.trackLabel.layer.opacity = 1;
        [self.artistLabel.layer addAnimation:labelOpacity forKey:@"opacity"];
        [self.trackLabel.layer addAnimation:labelOpacity forKey:@"opacity"];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
             [self hideFullTrackInfo];
        });
    });
}


-(void)hideFullTrackInfo
{
    CABasicAnimation *labelOpacity = [CABasicAnimation animationWithKeyPath:@"opacity"];
    labelOpacity.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    labelOpacity.duration = .2;
    labelOpacity.fromValue = @(1);
    labelOpacity.toValue = @(0);
    self.artistLabel.layer.opacity = 0;
    self.trackLabel.layer.opacity = 0;
    [self.artistLabel.layer addAnimation:labelOpacity forKey:@"opacity"];
    [self.trackLabel.layer addAnimation:labelOpacity forKey:@"opacity"];
    CALayer *layer = self.window.coverView.titleLabel.layer;

    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:.45];
    [NSAnimationContext currentContext].timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [[self.window.coverView.artistView animator] setFrame:NSMakeRect(0, 0, 160, 26)];
    [NSAnimationContext endGrouping];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.55 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        CABasicAnimation *originalTitleLabelOpacity = [CABasicAnimation animationWithKeyPath:@"opacity"];
        originalTitleLabelOpacity.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        originalTitleLabelOpacity.duration = .45;
        originalTitleLabelOpacity.fromValue = @(0);
        originalTitleLabelOpacity.toValue = @(1);
        layer.opacity = 1;
        [layer addAnimation:originalTitleLabelOpacity forKey:@"opacity"];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.45 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.changeTrackAnimation = NO;
        });
        
    });
}

-(NSTextField *)artistLabel
{
    if (!_artistLabel) {
        _artistLabel  = [[NSTextField alloc] initWithFrame:NSMakeRect(10, 80, 140, 60)];
        _artistLabel.textColor = [NSColor labelColor];
        _artistLabel.wantsLayer = YES;
        _artistLabel.layer.opacity = 0;
        _artistLabel.bezeled = NO;
        _artistLabel.bordered = NO;
        _artistLabel.drawsBackground = NO;
        _artistLabel.font = [NSFont systemFontOfSize:15];
        _artistLabel.alignment = NSTextAlignmentCenter;
        _artistLabel.selectable = NO;
        [[_artistLabel cell] setLineBreakMode:NSLineBreakByWordWrapping];
        [[_artistLabel cell] setTruncatesLastVisibleLine:YES];
        [self.window.coverView.artistView addSubview:_artistLabel];
    }
    return _artistLabel;
}

-(NSTextField *)trackLabel
{
    if (!_trackLabel) {
        _trackLabel  = [[NSTextField alloc] initWithFrame:NSMakeRect(10, 20, 140, 60)];
        _trackLabel.textColor = [NSColor labelColor];
        _trackLabel.wantsLayer = YES;
        _trackLabel.layer.opacity = 0;
        _trackLabel.bezeled = NO;
        _trackLabel.bordered = NO;
        _trackLabel.drawsBackground = NO;
        _trackLabel.font = [NSFont systemFontOfSize:13];
        _trackLabel.alignment = NSTextAlignmentCenter;
        _trackLabel.selectable = NO;
        [[_trackLabel cell] setLineBreakMode:NSLineBreakByWordWrapping];
        [[_trackLabel cell] setTruncatesLastVisibleLine:YES];
        [self.window.coverView.artistView addSubview:_trackLabel];
    }
    return _trackLabel;
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
    self.trackLabel.frame = NSMakeRect(10, (160-labelsHeight)/2-5, 140, self.trackLabel.frame.size.height);
    self.artistLabel.frame = NSMakeRect(10, (160-labelsHeight)/2+5 + self.trackLabel.frame.size.height, 140, self.artistLabel.frame.size.height);
}
@end
