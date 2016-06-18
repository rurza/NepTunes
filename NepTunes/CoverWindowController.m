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
#import "CoverLabel.h"
#import "ControlViewController.h"
#import <pop/POP.h>
#import "ControlView.h"
#import "MenuController.h"
#import "VolumeViewController.h"
#import "MusicPlayer.h"

@interface CoverWindowController () <CoverGetterDelegate, ControlViewDelegate>
@property (nonatomic) CoverWindow *window;
@property (nonatomic) BOOL changeTrackAnimation;
@property (nonatomic) CoverLabel *artistLabel;
@property (nonatomic) CoverLabel *trackLabel;
@property (nonatomic) NSTrackingArea *hoverArea;
@property (nonatomic) NSTimer *controlsTimer;
@property (nonatomic) IBOutlet VolumeViewController *volumeViewController;
@property (nonatomic) GetCover *getCover;
@property (nonatomic) NSClickGestureRecognizer *doubleClickRecognizer;
@property (nonatomic) CGRect artistViewOriginalRect;
@end

@implementation CoverWindowController
@dynamic window;
@synthesize popoverIsShown = _popoverIsShown;

- (void)windowDidLoad
{
    [super windowDidLoad];

    self.hoverArea = [[NSTrackingArea alloc] initWithRect:self.window.contentView.frame
                                                  options:NSTrackingMouseEnteredAndExited | NSTrackingAssumeInside | NSTrackingActiveAlways
                                                    owner:self userInfo:nil];
    [self.window.contentView addTrackingArea:self.hoverArea];
    self.window.contentView.acceptsTouchEvents = YES;
    self.doubleClickRecognizer = [[NSClickGestureRecognizer alloc] initWithTarget:self action:@selector(bringiTunesToFront:)];
    self.doubleClickRecognizer.numberOfClicksRequired = 2;
    self.doubleClickRecognizer.delaysPrimaryMouseButtonEvents = NO;
    [self.window.controlView addGestureRecognizer:self.doubleClickRecognizer];
    self.controlViewController.delegate = self;
    self.getCover = [[GetCover alloc] init];
    self.getCover.delegate = self;
    [self readSettings];
    self.shouldCascadeWindows = NO;
}

-(void)updateCoverWithTrack:(Track *)track
{
    if (track) {
        [self updateWithTrack:track];
        if (self.window && [MusicPlayer sharedPlayer].isPlayerRunning) {
            if ([MusicPlayer sharedPlayer].playerState == MusicPlayerStatePlaying) {
                [self displayFullInfoForTrack:track];
            }
            __weak typeof(self) weakSelf = self;
            [self.getCover getCoverWithTrack:track withCompletionHandler:^(NSImage *cover) {
                [weakSelf updateWith:track andCover:cover];
            }];
        } else {
            self.window.alphaValue = 0;
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
    POPBasicAnimation *fadeInAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerOpacity];
    if (direction) {
        fadeInAnimation.toValue = @(1);
        [self.window.coverView.coverImageView.layer pop_addAnimation:fadeInAnimation forKey:@"coverImageView opacity"];
    } else {
        fadeInAnimation.toValue = @(0);
        [self.window.coverView.coverImageView.layer pop_addAnimation:fadeInAnimation forKey:@"coverImageView opacity"];
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

#pragma mark - Full info

-(void)displayFullInfoForTrack:(Track *)track
{
    if (self.changeTrackAnimation) {
        self.artistLabel.stringValue = [NSString stringWithFormat:@"%@", track.artist];
        self.trackLabel.stringValue = [NSString stringWithFormat:@"%@", track.trackName];
        [self updateHeightForLabels];
        [self updateOriginsOfLabels];
        return;
    }
    self.artistViewOriginalRect = self.window.coverView.artistView.frame;
    self.changeTrackAnimation = YES;
    CALayer *layer = self.window.coverView.titleLabel.layer;
    layer.opacity = 0;

    __weak typeof(self) weakSelf = self;
    POPBasicAnimation *showFullInfoAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPViewFrame];
    showFullInfoAnimation.toValue = [NSValue valueWithRect:self.window.coverView.frame];
    showFullInfoAnimation.completionBlock = ^(POPAnimation *animation, BOOL completion) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf hideFullTrackInfo];
        });
        [self.window.coverView.artistView pop_removeAllAnimations];
    };
    [self.window.coverView.artistView pop_addAnimation:showFullInfoAnimation forKey:@"frame"];
    weakSelf.artistLabel.stringValue = [NSString stringWithFormat:@"%@", track.artist];
    weakSelf.trackLabel.stringValue = [NSString stringWithFormat:@"%@", track.trackName];
    [self updateHeightForLabels];
    [self updateOriginsOfLabels];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        POPBasicAnimation *labelOpacity = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerOpacity];
        labelOpacity.toValue = @(1);
        labelOpacity.completionBlock = ^(POPAnimation *animation, BOOL ended) {
            if (ended) {
                [self.artistLabel.layer pop_removeAllAnimations];
                [self.trackLabel.layer pop_removeAllAnimations];
            }
        };
        [self.artistLabel.layer pop_addAnimation:labelOpacity forKey:@"opacity"];
        [self.trackLabel.layer pop_addAnimation:labelOpacity forKey:@"opacity"];
    });
}


-(void)hideFullTrackInfo
{
    CALayer *layer = self.window.coverView.titleLabel.layer;
    __weak typeof(self) weakSelf = self;
    POPBasicAnimation *labelOpacity = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerOpacity];
    labelOpacity.toValue = @(0);
    labelOpacity.completionBlock = ^(POPAnimation *animation, BOOL completion) {
        POPSpringAnimation *hideFullInfoAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPViewFrame];
        hideFullInfoAnimation.completionBlock = ^(POPAnimation *animation, BOOL completion) {
         };
        hideFullInfoAnimation.springBounciness = 14;

        hideFullInfoAnimation.toValue = [NSValue valueWithRect:self.artistViewOriginalRect];
        [weakSelf.window.coverView.artistView pop_addAnimation:hideFullInfoAnimation forKey:@"frame"];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            POPBasicAnimation *titleLabelOpacity = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerOpacity];
            titleLabelOpacity.toValue = @(1);
            titleLabelOpacity.completionBlock = ^(POPAnimation *animation, BOOL completion) {
                weakSelf.changeTrackAnimation = NO;
                [weakSelf.window.contentView setNeedsDisplay:YES];
            };
            [layer pop_addAnimation:titleLabelOpacity forKey:@"titlelabel opacity"];
        });

        [self.artistLabel.layer pop_removeAllAnimations];
        [self.trackLabel.layer pop_removeAllAnimations];
    };
    [self.artistLabel.layer pop_addAnimation:labelOpacity forKey:@"opacity"];
    [self.trackLabel.layer pop_addAnimation:labelOpacity forKey:@"opacity"];
    
}

-(CoverLabel *)artistLabel
{
    if (!_artistLabel) {
        _artistLabel  = [[CoverLabel alloc] initWithFrame:NSMakeRect(10, 80, self.window.frame.size.width-20, 60)];
        _artistLabel.font = [NSFont systemFontOfSize:15];
         [self.window.coverView.artistView addSubview:_artistLabel];
    }
    return _artistLabel;
}

-(CoverLabel *)trackLabel
{
    if (!_trackLabel) {
        _trackLabel  = [[CoverLabel alloc] initWithFrame:NSMakeRect(10, 20, self.window.frame.size.width-20, 60)];
        _trackLabel.font = [NSFont systemFontOfSize:13];
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
    
    self.trackLabel.frame = NSMakeRect(10, (self.window.frame.size.height-labelsHeight)/2-5, self.window.frame.size.width-20, self.trackLabel.frame.size.height);
    self.artistLabel.frame = NSMakeRect(10, (self.window.frame.size.height-labelsHeight)/2+5 + self.trackLabel.frame.size.height, self.window.frame.size.width-20, self.artistLabel.frame.size.height);
}

#pragma mark - Hover area

-(void)mouseEntered:(NSEvent *)event
{
    self.controlsTimer = [NSTimer scheduledTimerWithTimeInterval:.05f target:self selector:@selector(showControlsWithDelay:) userInfo:nil repeats:NO];
}

-(void)mouseExited:(NSEvent *)theEvent
{
    [self hideControls];
}

-(void)showControlsWithDelay:(NSTimer *)timer
{
    [self showControls];
}

-(void)showControls
{
    MusicPlayer *musicPlayer = [MusicPlayer sharedPlayer];
    if (!self.popoverIsShown) {
        POPBasicAnimation *controlOpacity = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerOpacity];
        controlOpacity.toValue = @(1);
        controlOpacity.duration = 0.2;
        [self.window.controlView.layer pop_addAnimation:controlOpacity forKey:@"fade"];
        [self.controlViewController updateVolumeIcon];
        if ((!musicPlayer.currentTrack.artist.length &&
            !musicPlayer.currentTrack.trackName.length &&
            ![SettingsController sharedSettings].session) || (![SettingsController sharedSettings].session && ![SettingsController sharedSettings].integrationWithMusicPlayer)) {
            self.controlViewController.loveButton.alphaValue = 0.5;
            self.controlViewController.loveButton.enabled = NO;
        } else {
            self.controlViewController.loveButton.alphaValue = 1;
            self.controlViewController.loveButton.enabled = YES;
        }
     }
    
    
//    if (musicPlayer.currentPlayer == MusicPlayeriTunes) {
//        [self updateUIbasedOnCurrentTrackRating];
//    } else {
//        self.controlViewController.ratingView.hidden = YES;
//    }
    [self.controlsTimer invalidate];
    self.controlsTimer = nil;
}

//-(void)updateUIbasedOnCurrentTrackRating
//{
//    MusicPlayer *musicPlayer = [MusicPlayer sharedPlayer];
//
//    NSInteger rating = musicPlayer.currentTrack.rating;
//    
//    NSImage *fullStarImage = [NSImage imageNamed:@"star-full"];
//    fullStarImage.template = YES;
//    NSImage *emptyStarImage = [NSImage imageNamed:@"star-empty"];
//    emptyStarImage.template = YES;
//    
//    [self.controlViewController.ratingButtons enumerateObjectsUsingBlock:^(NSButton *  _Nonnull starButton, NSUInteger idx, BOOL * _Nonnull stop) {
//        starButton.image = emptyStarImage;
//    }];
//    
//    if (rating > 80) {
//        [self.controlViewController.ratingButtons enumerateObjectsUsingBlock:^(NSButton *  _Nonnull starButton, NSUInteger idx, BOOL * _Nonnull stop) {
//            starButton.image = fullStarImage;
//        }];
//    } else if (rating > 60) {
//        [self.controlViewController.ratingButtons enumerateObjectsUsingBlock:^(NSButton *  _Nonnull starButton, NSUInteger idx, BOOL * _Nonnull stop) {
//            if (idx == 4) {
//                *stop = YES;
//            } else {
//                starButton.image = fullStarImage;
//            }
//        }];
//    } else if (rating > 40) {
//        [self.controlViewController.ratingButtons enumerateObjectsUsingBlock:^(NSButton *  _Nonnull starButton, NSUInteger idx, BOOL * _Nonnull stop) {
//            if (idx == 3) {
//                *stop = YES;
//            } else {
//                starButton.image = fullStarImage;
//            }
//        }];
//    } else if (rating > 20) {
//        [self.controlViewController.ratingButtons enumerateObjectsUsingBlock:^(NSButton *  _Nonnull starButton, NSUInteger idx, BOOL * _Nonnull stop) {
//            if (idx == 2) {
//                *stop = YES;
//            } else {
//                starButton.image = fullStarImage;
//            }
//        }];
//    } else if (rating >= 0 && musicPlayer.currentTrack.trackName.length && musicPlayer.currentTrack.artist.length && musicPlayer.currentTrack.kind.length) {
//        if (rating != 0) {
//            self.controlViewController.star01Button.image = fullStarImage;
//        }
//    }
//}

-(void)hideControls
{
    if (!self.popoverIsShown && !self.controlsTimer) {
        POPBasicAnimation *controlOpacity = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerOpacity];
        controlOpacity.toValue = @(0);
        controlOpacity.duration = 0.2;
        [self.window.controlView.layer pop_addAnimation:controlOpacity forKey:@"fade"];
    }
    [self.controlsTimer invalidate];
    self.controlsTimer = nil;
}

- (void)bringiTunesToFront:(NSGestureRecognizer *)gestureRecognizer
{
    CoverSettingsController *coverSettingsController = [[CoverSettingsController alloc] init];
    
    if (coverSettingsController.bringiTunesToFrontWithDoubleClick) {
        [[MusicPlayer sharedPlayer] bringPlayerToFront];
    }
}

-(void)readSettings
{
    CoverSettingsController *coverSettingsController = [[CoverSettingsController alloc] init];
    CoverPosition coverPosition = coverSettingsController.coverPosition;
    switch (coverPosition) {
        case CoverPositionStuckToTheDesktop:
            [self.window setLevel:kCGDesktopIconWindowLevel+1];
            if (coverSettingsController.ignoreMissionControl) {
                self.window.collectionBehavior = NSWindowCollectionBehaviorStationary | NSWindowCollectionBehaviorCanJoinAllSpaces | NSWindowCollectionBehaviorIgnoresCycle;
            } else {
                self.window.collectionBehavior = NSWindowCollectionBehaviorManaged | NSWindowCollectionBehaviorIgnoresCycle | NSWindowCollectionBehaviorCanJoinAllSpaces;
            }
            break;
        case CoverPositionAboveAllOtherWindows:
            [self.window setLevel:NSScreenSaverWindowLevel];
            if (coverSettingsController.ignoreMissionControl) {
                self.window.collectionBehavior = NSWindowCollectionBehaviorStationary | NSWindowCollectionBehaviorCanJoinAllSpaces | NSWindowCollectionBehaviorIgnoresCycle;
            } else {
                self.window.collectionBehavior = NSWindowCollectionBehaviorManaged | NSWindowCollectionBehaviorIgnoresCycle | NSWindowCollectionBehaviorCanJoinAllSpaces;
            }
            break;
        case CoverPositionMixedInWithOtherWindows:
            [self.window setLevel:NSNormalWindowLevel];
            if (coverSettingsController.ignoreMissionControl) {
                self.window.collectionBehavior = NSWindowCollectionBehaviorStationary | NSWindowCollectionBehaviorCanJoinAllSpaces | NSWindowCollectionBehaviorParticipatesInCycle;
            } else {
                self.window.collectionBehavior = NSWindowCollectionBehaviorManaged | NSWindowCollectionBehaviorParticipatesInCycle | NSWindowCollectionBehaviorCanJoinAllSpaces;
            }
            break;
        default:
            break;
    }
    CoverSize coverSize = coverSettingsController.coverSize;
    [self resizeCoverToSize:coverSize animated:NO];
    [self.window makeKeyAndOrderFront:nil];
}

#pragma mark - Resizing

-(void)resizeCoverToSize:(CoverSize)coverSize animated:(BOOL)animated
{
    switch (coverSize) {
        case 1:
            [self.window setFrame:NSRectFromCGRect(CGRectMake(self.window.frame.origin.x, self.window.frame.origin.y, 160, 160)) display:YES animate:animated];
            break;
        case 2:
            [self.window setFrame:NSRectFromCGRect(CGRectMake(self.window.frame.origin.x, self.window.frame.origin.y, 200, 200)) display:YES animate:animated];
            break;
        case 3:
            [self.window setFrame:NSRectFromCGRect(CGRectMake(self.window.frame.origin.x, self.window.frame.origin.y, 240, 240)) display:YES animate:animated];
            break;
        default:
            break;
    }
    [self.window.contentView removeTrackingArea:self.hoverArea];
    self.hoverArea = nil;
    
    self.hoverArea = [[NSTrackingArea alloc] initWithRect:self.window.contentView.frame
                                                  options:NSTrackingMouseEnteredAndExited | NSTrackingAssumeInside | NSTrackingActiveAlways
                                                    owner:self userInfo:nil];
    [self.window.contentView addTrackingArea:self.hoverArea];
}


-(void)rightMouseUp:(NSEvent *)theEvent
{
    [NSMenu popUpContextMenu:[MenuController sharedController].statusMenu withEvent:theEvent forView:self.window.controlView];
}

- (void)scrollWheel:(NSEvent *)theEvent
{
    CGFloat value;
    if (theEvent.isDirectionInvertedFromDevice) {
        value = -[theEvent scrollingDeltaY];
    } else {
        value = [theEvent scrollingDeltaY];
    }
    [self.volumeViewController updateVolumeWithDeltaValue:value];
}


-(BOOL)acceptsFirstResponder
{
    return YES;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end