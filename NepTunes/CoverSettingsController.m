//
//  CoverSettingsController.m
//  NepTunes
//
//  Created by rurza on 18/02/16.
//  Copyright © 2016 micropixels. All rights reserved.
//

#import "CoverSettingsController.h"
#import "MusicController.h"
#import "CoverWindowController.h"
#import "CoverWindow.h"

static NSString *const kCoverPosition = @"CoverPosition";
static NSString *const kIgnoreMissionControl = @"IgnoreMissionControl";
static NSString *const kShowCover = @"ShowCover";


@interface CoverSettingsController ()
@property (nonatomic) NSUserDefaults *userDefaults;

- (IBAction)ignoreMissionControl:(NSButton *)sender;
- (IBAction)changeAlbumCoverPosition:(NSPopUpButton *)sender;
- (IBAction)showAlbumCover:(NSButton *)sender;

@end

@implementation CoverSettingsController

@synthesize showCover = _showCover, coverPosition = _coverPosition, ignoreMissionControl = _ignoreMissionControl;


#pragma mark - Initialization
-(instancetype)init
{
    if (self = [super init]) {
        [self registerDefaultsSettings];
    }
    return self;
}

-(void)awakeFromNib
{
    [self updateUI];
    [self saveSettings];
}

-(void)registerDefaultsSettings
{
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{kShowCover: @YES}];
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{kIgnoreMissionControl: @YES}];
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{kCoverPosition: @1}];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)updateUI
{
    self.albumCoverCheckbox.state = self.showCover;
    if (!self.showCover) {
        self.ignoreMissionControlCheckbox.enabled = NO;
        self.albumCoverPosition.enabled = NO;
    } else {
        self.ignoreMissionControlCheckbox.enabled = YES;
        self.albumCoverPosition.enabled = YES;
    }
    self.ignoreMissionControlCheckbox.state = self.ignoreMissionControl;
    [self.albumCoverPosition selectItemWithTag:self.coverPosition];
}

#pragma mark - Target Action


- (IBAction)ignoreMissionControl:(NSButton *)sender
{
    self.ignoreMissionControl = sender.state;
    CoverWindow *window = (CoverWindow *)[MusicController sharedController].coverWindowController.window;
    if (self.ignoreMissionControl) {
        if (self.coverPosition == CoverPositionStuckToTheDesktop || self.coverPosition == CoverPositionAboveAllOtherWindows) {
            window.collectionBehavior = NSWindowCollectionBehaviorStationary | NSWindowCollectionBehaviorCanJoinAllSpaces | NSWindowCollectionBehaviorIgnoresCycle;
        } else if (self.coverPosition == CoverPositionMixedInWithOtherWindows) {
            window.collectionBehavior = NSWindowCollectionBehaviorStationary | NSWindowCollectionBehaviorCanJoinAllSpaces | NSWindowCollectionBehaviorParticipatesInCycle;
        }
 
    } else {
        if (self.coverPosition == CoverPositionStuckToTheDesktop || self.coverPosition == CoverPositionAboveAllOtherWindows) {
            window.collectionBehavior = NSWindowCollectionBehaviorManaged | NSWindowCollectionBehaviorIgnoresCycle | NSWindowCollectionBehaviorCanJoinAllSpaces;
        } else if (self.coverPosition == CoverPositionMixedInWithOtherWindows) {
            window.collectionBehavior = NSNormalWindowLevel | NSWindowCollectionBehaviorCanJoinAllSpaces;
        }
    }
}

- (IBAction)changeAlbumCoverPosition:(NSPopUpButton *)sender
{
    CoverWindow *window = (CoverWindow *)[MusicController sharedController].coverWindowController.window;
    self.coverPosition = sender.selectedTag;
    switch (self.coverPosition) {
        case 1:
            [window setLevel:kCGDesktopIconWindowLevel+1];
            if (self.ignoreMissionControl) {
                window.collectionBehavior = NSWindowCollectionBehaviorStationary | NSWindowCollectionBehaviorCanJoinAllSpaces | NSWindowCollectionBehaviorIgnoresCycle;
            } else {
                window.collectionBehavior = NSWindowCollectionBehaviorManaged | NSWindowCollectionBehaviorIgnoresCycle | NSWindowCollectionBehaviorCanJoinAllSpaces;
            }
            break;
        case 2:
            [window setLevel:NSScreenSaverWindowLevel];
            if (self.ignoreMissionControl) {
                window.collectionBehavior = NSWindowCollectionBehaviorStationary | NSWindowCollectionBehaviorCanJoinAllSpaces | NSWindowCollectionBehaviorIgnoresCycle;
            } else {
                window.collectionBehavior = NSWindowCollectionBehaviorManaged | NSWindowCollectionBehaviorIgnoresCycle | NSWindowCollectionBehaviorCanJoinAllSpaces;
            }
            break;
        case 3:
            [window setLevel:NSNormalWindowLevel];
            if (self.ignoreMissionControl) {
               window.collectionBehavior = NSWindowCollectionBehaviorStationary | NSWindowCollectionBehaviorCanJoinAllSpaces | NSWindowCollectionBehaviorParticipatesInCycle;
            } else {
            window.collectionBehavior = NSWindowCollectionBehaviorManaged | NSWindowCollectionBehaviorParticipatesInCycle | NSWindowCollectionBehaviorCanJoinAllSpaces;
            }

            break;
        default:
            break;
    }
    [window makeKeyAndOrderFront:nil];
}

-(IBAction)showAlbumCover:(NSButton *)sender
{
    self.showCover = sender.state;
    if (!sender.state) {
        self.ignoreMissionControlCheckbox.enabled = NO;
        self.albumCoverPosition.enabled = NO;
        [[MusicController sharedController].coverWindowController.window close];
    } else {
        [[MusicController sharedController] setupCover];
        self.ignoreMissionControlCheckbox.enabled = YES;
        self.albumCoverPosition.enabled = YES;
    }
}

#pragma mark Show Cover
-(BOOL)showCover
{
    if (!_showCover) {
        _showCover = [[self.userDefaults objectForKey:kShowCover] boolValue];
    }
    return _showCover;
}

-(void)setShowCover:(BOOL)showCover
{
    _showCover = showCover;
    [self.userDefaults setObject:@(showCover) forKey:kShowCover];
    [self saveSettings];
}

#pragma mark Position
-(CoverPosition)coverPosition
{
    if (!_coverPosition) {
        _coverPosition = ![[self.userDefaults objectForKey:kCoverPosition] integerValue] ? CoverPositionStuckToTheDesktop : [[self.userDefaults objectForKey:kCoverPosition] integerValue];
    }
    return _coverPosition;
}

-(void)setCoverPosition:(CoverPosition)coverPosition
{
    _coverPosition = coverPosition;
    [self.userDefaults setObject:@(coverPosition) forKey:kCoverPosition];
    [self saveSettings];
}

#pragma mark Ignore Mission Control
-(BOOL)ignoreMissionControl
{
    if (!_ignoreMissionControl) {
        _ignoreMissionControl = [[self.userDefaults objectForKey:kIgnoreMissionControl] boolValue];
    }
    return _ignoreMissionControl;
}

-(void)setIgnoreMissionControl:(BOOL)ignoreMissionControl
{
    _ignoreMissionControl = ignoreMissionControl;
    [self.userDefaults setObject:@(ignoreMissionControl) forKey:kIgnoreMissionControl];
    [self saveSettings];
}

-(NSUserDefaults *)userDefaults
{
    if (!_userDefaults) {
        _userDefaults = [NSUserDefaults standardUserDefaults];
    }
    return _userDefaults;
}

#pragma mark - Save
-(void)saveSettings
{
    [self.userDefaults synchronize];
}


@end
