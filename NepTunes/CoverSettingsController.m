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
#import "MusicScrobbler.h"

static NSString *const kCoverPosition = @"CoverPosition";
static NSString *const kIgnoreMissionControl = @"IgnoreMissionControl";
static NSString *const kShowCover = @"ShowCover";
static NSString *const kBringiTunesToFrontWithDoubleClick = @"BringiTunesToFrontWithDoubleClick";
static NSString *const kCoverSize = @"CoverSize";
static NSString *const kSimpleMode = @"SimpleMode";
static NSString *const kNotificationsMode = @"NotificationsMode";


@interface CoverSettingsController ()
@property (nonatomic) NSUserDefaults *userDefaults;

- (IBAction)ignoreMissionControl:(NSButton *)sender;
- (IBAction)changeAlbumCoverPosition:(NSPopUpButton *)sender;
- (IBAction)showAlbumCover:(NSButton *)sender;
- (IBAction)changeCoverSize:(NSPopUpButton *)sender;


@end

@implementation CoverSettingsController

@synthesize showCover = _showCover, coverPosition = _coverPosition, ignoreMissionControl = _ignoreMissionControl, bringiTunesToFrontWithDoubleClick = _bringiTunesToFrontWithDoubleClick, coverSize = _coverSize, simpleMode = _simpleMode, notificationMode = _notificationMode;


#pragma mark - Initialization
+ (instancetype)sharedCoverSettings
{
    __strong static id _sharedInstance = nil;
    static dispatch_once_t onlyOnce;
    dispatch_once(&onlyOnce, ^{
        _sharedInstance = [[self _alloc] _init];
        [_sharedInstance registerDefaultsSettings];
    });
    return _sharedInstance;
}

+ (id) allocWithZone:(NSZone*)z { return [self sharedCoverSettings];              }
+ (id) alloc                    { return [self sharedCoverSettings];              }
- (id) init                     {return self;}
+ (id)_alloc                    { return [super allocWithZone:NULL]; }
- (id)_init                     {return [super init];}


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
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{kBringiTunesToFrontWithDoubleClick: @YES}];
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{kCoverSize: @1}];
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{kSimpleMode: @0}];
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{kNotificationsMode: @0}];



    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)updateUI
{
    self.albumCoverCheckbox.state = self.showCover;
    if (!self.showCover) {
        self.ignoreMissionControlCheckbox.enabled = NO;
        self.albumCoverPosition.enabled = NO;
        self.bringiTunesToFrontWithDoubleClickCheckbox.enabled = NO;
        self.coverSizePopUp.enabled = NO;
        self.notificationModeCheckbox.enabled = NO;
        self.simpleModeCheckbox.enabled = NO;
    } else {
        self.ignoreMissionControlCheckbox.enabled = YES;
        self.albumCoverPosition.enabled = YES;
        self.bringiTunesToFrontWithDoubleClickCheckbox.enabled = YES;
        self.coverSizePopUp.enabled = YES;
        self.notificationModeCheckbox.enabled = YES;
        self.simpleModeCheckbox.enabled = YES;
    }
    self.ignoreMissionControlCheckbox.state = self.ignoreMissionControl;
    self.bringiTunesToFrontWithDoubleClickCheckbox.state = self.bringiTunesToFrontWithDoubleClick;
    [self.albumCoverPosition selectItemWithTag:self.coverPosition];
    [self.coverSizePopUp selectItemWithTag:self.coverSize];
    self.notificationModeCheckbox.state = self.notificationMode;
    self.simpleModeCheckbox.state = self.simpleMode;
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
    self.coverPosition = sender.selectedTag;
}

- (void)updateAlbumPosition:(CoverPosition)position
{
    CoverWindow *window = (CoverWindow *)[MusicController sharedController].coverWindowController.window;

    switch (position) {
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

- (IBAction)changeCoverSize:(NSPopUpButton *)sender
{
    CoverWindow *window = (CoverWindow *)[MusicController sharedController].coverWindowController.window;
    self.coverSize = sender.selectedTag;
    [[MusicController sharedController].coverWindowController resizeCoverToSize:self.coverSize animated:YES];
    [window makeKeyAndOrderFront:nil];
}

-(IBAction)showAlbumCover:(NSButton *)sender
{
    self.showCover = sender.state;
    if (!sender.state) {
        self.ignoreMissionControlCheckbox.enabled = NO;
        self.albumCoverPosition.enabled = NO;
        self.bringiTunesToFrontWithDoubleClickCheckbox.enabled = NO;
        self.simpleModeCheckbox.enabled = NO;
        self.notificationModeCheckbox.enabled = NO;
        [[MusicController sharedController].coverWindowController.window close];
    } else {
        [[MusicController sharedController] setupCover];
        [[MusicController sharedController].coverWindowController updateCoverWithTrack:[MusicScrobbler sharedScrobbler].currentTrack];

        self.ignoreMissionControlCheckbox.enabled = YES;
        self.albumCoverPosition.enabled = YES;
        self.bringiTunesToFrontWithDoubleClickCheckbox.enabled = YES;
        
        self.simpleModeCheckbox.enabled = YES;
        self.notificationModeCheckbox.enabled = YES;
    }
}

-(IBAction)bringiTunesToFrontWithDoubleClick:(NSButton *)sender
{
    self.bringiTunesToFrontWithDoubleClick = sender.state;
}

-(IBAction)toggleSimpleMode:(NSButton *)sender
{
    self.simpleMode = sender.state;
    [[MusicController sharedController].coverWindowController toggleSimpleMode];
}

-(IBAction)toggleNotificationsMode:(NSButton *)sender
{
    self.notificationMode = sender.state;
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
    [self updateAlbumPosition:coverPosition];
}

#pragma mark Size
-(CoverSize)coverSize
{
    if (!_coverSize) {
        _coverSize = ![[self.userDefaults objectForKey:kCoverSize] integerValue] ? CoverSizeSmall : [[self.userDefaults objectForKey:kCoverSize] integerValue];
    }
    return _coverSize;
}

-(void)setCoverSize:(CoverSize)coverSize
{
    _coverSize = coverSize;
    [self.userDefaults setObject:@(coverSize) forKey:kCoverSize];
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

#pragma mark Bring iTunes to front
-(BOOL)bringiTunesToFrontWithDoubleClick
{
    if (!_bringiTunesToFrontWithDoubleClick) {
        _bringiTunesToFrontWithDoubleClick = [[self.userDefaults objectForKey:kBringiTunesToFrontWithDoubleClick] boolValue];
    }
    return _bringiTunesToFrontWithDoubleClick;
}

-(void)setBringiTunesToFrontWithDoubleClick:(BOOL)bringiTunesToFrontWithDoubleClick
{
    _bringiTunesToFrontWithDoubleClick = bringiTunesToFrontWithDoubleClick;
    [self.userDefaults setObject:@(bringiTunesToFrontWithDoubleClick) forKey:kBringiTunesToFrontWithDoubleClick];
    [self saveSettings];
}

#pragma mark Simple Mode

-(BOOL)simpleMode
{
    if (!_simpleMode) {
        _simpleMode = [[self.userDefaults objectForKey:kSimpleMode] boolValue];
    }
    return _simpleMode;
}

-(void)setSimpleMode:(BOOL)simpleMode
{
    _simpleMode = simpleMode;
    [self.userDefaults setObject:@(simpleMode) forKey:kSimpleMode];
    [self saveSettings];
}

#pragma mark Notifications Mode

-(BOOL)notificationMode
{
    if (!_notificationMode) {
        _notificationMode = [[self.userDefaults objectForKey:kNotificationsMode] boolValue];
    }
    return _notificationMode;
}


-(void)setNotificationMode:(BOOL)notificationMode
{
    _notificationMode = notificationMode;
    [self.userDefaults setObject:@(notificationMode) forKey:kNotificationsMode];
    [self saveSettings];
}
#pragma mark -

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
