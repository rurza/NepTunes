//
//  PreferencesController.m
//  NepTunes
//
//  Created by rurza on 16/02/16.
//  Copyright © 2016 micropixels. All rights reserved.
//

#import "PreferencesController.h"
#import "MusicScrobbler.h"
#import "Track.h"
#import "FXReachability.h"
#import "OfflineScrobbler.h"
#import "SettingsController.h"
#import "LastFm.h"
#import "UserNotificationsController.h"
#import "MusicController.h"
#import "CoverWindowController.h"
#import <POP.h>
#import "CoverView.h"
#import "GetCover.h"
#import "CoverImageView.h"
#import "CoverLabel.h"

static NSString *const kAccountItemToolbarIdentifier = @"Account";
static NSString *const kTrackInfoUpdated = @"trackInfoUpdated";


@interface PreferencesController () <NSTextFieldDelegate, CoverGetterDelegate>
@property (nonatomic) IBOutlet NSTextField *loginField;
@property (nonatomic) IBOutlet NSSecureTextField *passwordField;
@property (nonatomic) IBOutlet NSButton *loginButton;
@property (nonatomic) IBOutlet NSButton *logoutButton;

@property (nonatomic) IBOutlet NSView *accountView;
@property (nonatomic) IBOutlet NSView *loggedInUserView;
@property (nonatomic) IBOutlet NSView *hotkeyView;
@property (nonatomic) IBOutlet NSView *generalView;
@property (nonatomic) IBOutlet NSView *menuView;
@property (nonatomic) IBOutlet NSView *albumCoverView;


@property (nonatomic) IBOutlet NSImageView *userAvatar;

@property (nonatomic) IBOutlet NSButton *createAccountButton;
@property (nonatomic) IBOutlet NSProgressIndicator *indicator;
@property (nonatomic) IBOutlet NSProgressIndicator *avatarIndicator;

@property (nonatomic) int currentViewTag;
@property (nonatomic) IBOutlet NSToolbarItem *accountToolbarItem;
@property (nonatomic) IBOutlet NSToolbarItem *hotkeysToolbarItem;
@property (nonatomic) IBOutlet NSToolbarItem *generalToolbarItem;
@property (nonatomic) IBOutlet NSToolbarItem *menuToolbarItem;
@property (nonatomic) IBOutlet NSToolbarItem *albumCoverToolbarItem;


//reachability
@property (nonatomic) BOOL reachability;
//Offline
@property (nonatomic) OfflineScrobbler *offlineScrobbler;
//Settings
@property (nonatomic) SettingsController *settingsController;
//Scrobbler
@property (nonatomic) MusicScrobbler *musicScrobbler;
//Music Controller
@property (nonatomic) MusicController *musicController;

@property (nonatomic) GetCover *getCover;

@property (strong) IBOutlet NSButton *albumCoverCheckbox;
@property (strong) IBOutlet NSPopUpButton *albumCoverPosition;
@property (strong) IBOutlet NSButton *ignoreMissionControlCheckbox;
@property (strong) IBOutlet CoverView *coverView;
@property (nonatomic) BOOL changeTrackAnimation;
@property (nonatomic) CoverLabel *artistLabel;
@property (nonatomic) CoverLabel *trackLabel;

- (IBAction)loginClicked:(id)sender;
- (IBAction)logOut:(id)sender;
- (IBAction)createNewLastFmAccountInWebBrowser:(id)sender;
- (IBAction)ignoreMissionControl:(NSButton *)sender;
- (IBAction)changeAlbumCoverPosition:(NSPopUpButton *)sender;
- (IBAction)showAlbumCover:(id)sender;



@end

@implementation PreferencesController

#pragma mark - Initialization
+ (instancetype)sharedPreferences
{
    __strong static id _sharedInstance = nil;
    static dispatch_once_t onlyOnce;
    dispatch_once(&onlyOnce, ^{
        _sharedInstance = [[self _alloc] _init];
        
    });
    return _sharedInstance;
}

+ (id) allocWithZone:(NSZone*)z { return [self sharedPreferences];              }
+ (id) alloc                    { return [self sharedPreferences];              }
- (id) init                     { return self;}
+ (id)_alloc                    { return [super allocWithZone:NULL]; }
- (id)_init                     { return [super init];               }



- (void)windowDidLoad
{
    [super windowDidLoad];
    [self setupReachability];
    self.passwordField.delegate = self;
    self.loginField.delegate = self;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateCover:) name:kTrackInfoUpdated object:nil];
    [self updateCover:nil];
    [self setupCoverView];
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
 }



-(void)setupReachability
{
    //1. this must be first
    self.reachability = YES;
    //2. this must be second
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityDidChange:) name:FXReachabilityStatusDidChangeNotification object:nil];
    
}


-(void)awakeFromNib {
    if (self.settingsController.session) {
        self.accountToolbarItem.tag = 0;
        [[self window] setContentSize:[self.loggedInUserView frame].size];
        [[[self window] contentView ] addSubview:self.loggedInUserView];
        [self.settingsToolbar setSelectedItemIdentifier:kAccountItemToolbarIdentifier];
        [self.logoutButton setTitle:[NSString stringWithFormat:@"Log out %@", self.musicScrobbler.scrobbler.username]];
        [self setAvatarForUserWithInfo:nil];
    }
    else {
        [[self window] setContentSize:[self.accountView frame].size];
        [[[self window] contentView ] addSubview:self.accountView];
        [self.settingsToolbar setSelectedItemIdentifier:kAccountItemToolbarIdentifier];
        [self.loginButton setEnabled:NO];
        self.accountToolbarItem.tag = 1;
        [self switchView:self.accountToolbarItem];
        
    }
    [self.window recalculateKeyViewLoop];
    
    NSColor *color = [NSColor colorWithSRGBRed:0.2896 green:0.5448 blue:0.9193 alpha:1.0];
    NSMutableAttributedString *colorTitle = [[NSMutableAttributedString alloc] initWithAttributedString:[self.createAccountButton attributedTitle]];
    NSRange titleRange = NSMakeRange(0, [colorTitle length]);
    [colorTitle addAttribute:NSForegroundColorAttributeName value:color range:titleRange];
    [self.createAccountButton setAttributedTitle:colorTitle];
}


/*----------------------------------------------------------------------------------------------------------*/
#pragma mark - Managing account

-(IBAction)loginClicked:(id)sender
{
    [self loginWithTryCounter:1];
}

-(void)loginWithTryCounter:(NSUInteger)tryCounter
{
    if (!([self.passwordField.stringValue isEqualTo: @""] || [self.loginField.stringValue isEqualTo: @""]))
    {
        [self.indicator startAnimation:self];
        
        self.loginField.hidden = YES;
        self.passwordField.hidden = YES;
        [self.createAccountButton setHidden:YES];
        if (![self.loginField.stringValue.lowercaseString isEqualToString:self.settingsController.username.lowercaseString]) {
            [self.offlineScrobbler deleteAllSavedTracks];
        }
        
        [self.loginButton setTitle:@"Logging in..."];
        [self.loginButton setEnabled:NO];
        __weak typeof(self) weakSelf = self;
        self.musicScrobbler.username = self.loginField.stringValue;
        [self.musicScrobbler.scrobbler getSessionForUser:self.loginField.stringValue
                                                password:self.passwordField.stringValue
                                          successHandler:^(NSDictionary *result)
         {
             //login success handler
             [weakSelf.musicScrobbler logInWithCredentials:result];
             weakSelf.settingsController.username = weakSelf.musicScrobbler.username;
             weakSelf.offlineScrobbler.userWasLoggedOut = NO;
             
             [weakSelf.musicScrobbler.scrobbler getInfoForUserOrNil:self.loginField.stringValue successHandler:^(NSDictionary *result) {
                 [weakSelf setAvatarForUserWithInfo:result];
             } failureHandler:nil];
             [weakSelf setUserAvatarRoundedBorder];
             weakSelf.accountToolbarItem.tag = 0;
             [weakSelf switchView:weakSelf.accountToolbarItem];
             [weakSelf.menuController updateMenu];
             
             
             [weakSelf.indicator stopAnimation:weakSelf];
             weakSelf.loginField.hidden = NO;
             weakSelf.passwordField.hidden = NO;
             [weakSelf.createAccountButton setHidden:NO];
             
             [weakSelf.loginButton setTitle:@"Log in"];
             [weakSelf.logoutButton setTitle:[NSString stringWithFormat:@"Log out %@", weakSelf.musicScrobbler.username]];
             weakSelf.passwordField.stringValue = @"";
             [weakSelf.musicController updateTrackInfo:nil];
         } failureHandler:^(NSError *error) {
             if (error.code == -1001) {
                 if (tryCounter <= 3) {
                     [weakSelf loginWithTryCounter:(tryCounter + 1)];
                 }
             }
             else {
                 [weakSelf.indicator stopAnimation:weakSelf];
                 
                 weakSelf.passwordField.stringValue = @"";
                 [weakSelf.loginButton setTitle:@"Log in"];
                 [weakSelf.loginButton setEnabled:NO];
                 weakSelf.loginField.hidden = NO;
                 weakSelf.passwordField.hidden = NO;
                 [weakSelf.createAccountButton setHidden:NO];
                 NSAlert *alert = [[NSAlert alloc] init];
                 alert.alertStyle = NSCriticalAlertStyle;
                 if (error.code == kLastFmErrorCodeAuthenticationFailed) {
                     alert.informativeText = @"It looks like you typed wrong username or/and password. 😤";
                 } else {
                     alert.informativeText = [error localizedDescription];
                 }
                 alert.messageText = NSLocalizedString(@"Try again :)", nil);
                 [alert beginSheetModalForWindow:weakSelf.window completionHandler:^(NSModalResponse returnCode) {
                     [alert.window close];
                 }];
             }
         }];
    }
}

- (IBAction)logOut:(id)sender
{
    [self logOutUser];
    self.settingsController.username = nil;
    [self.musicController invalidateTimers];
}

-(void)forceLogOut
{
    [self logOutUser];
}

-(void)logOutUser
{
    [self.loginButton setEnabled:NO];
    self.settingsController.session = nil;
    [self.musicScrobbler logOut];
    
    self.userAvatar.image = nil;
    self.settingsController.userAvatar = nil;
    [self.menuController updateMenu];
    
    self.accountToolbarItem.tag = 1;
    [self switchView:self.accountToolbarItem];
    
}

- (IBAction)createNewLastFmAccountInWebBrowser:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://secure.last.fm/join"]];
}


#pragma mark - Album Cover

-(void)setupCoverView
{
//    self.coverView.layer.shadowOpacity = 1;
//    self.coverView.layer.shadowColor = [NSColor blackColor].CGColor;
//    self.coverView.layer.shadowOffset = CGSizeMake(-3, -3);
//    [self.coverView.layer setNeedsLayout];

//    self.coverView.shadow = [[NSShadow alloc] init];
//    self.coverView.shadow.
}

-(void)updateCover:(NSNotification *)note
{
    [self updateCoverWithTrack:self.musicScrobbler.currentTrack andUserInfo:note.userInfo];
}

-(void)updateCoverWithTrack:(Track *)track andUserInfo:(NSDictionary *)userInfo
{
    if (track) {
        [self updateWithTrack:track];
        if ([MusicController sharedController].isiTunesRunning) {
            if ([MusicController sharedController].playerState == iTunesEPlSPlaying) {
                [self displayFullInfoForTrack:track];
            }
            __weak typeof(self) weakSelf = self;
            [self.getCover getCoverWithTrack:track withCompletionHandler:^(NSImage *cover) {
                [weakSelf updateWith:track andCover:cover];
            }];
        } else {
//            [self animateWindowOpacity:0];
        }
    } else {
//        [self animateWindowOpacity:0];
    }
}

-(void)updateWith:(Track *)track andCover:(NSImage *)cover
{
    
    self.coverView.coverImageView.image = cover;
    [self updateWithTrack:track];
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
    self.trackLabel.frame = NSMakeRect(10, (160-labelsHeight)/2-5, 140, self.trackLabel.frame.size.height);
    self.artistLabel.frame = NSMakeRect(10, (160-labelsHeight)/2+5 + self.trackLabel.frame.size.height, 140, self.artistLabel.frame.size.height);
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



- (IBAction)ignoreMissionControl:(NSButton *)sender
{
    
}

- (IBAction)changeAlbumCoverPosition:(NSPopUpButton *)sender
{
    
}

- (IBAction)showAlbumCover:(id)sender
{
    
}

/*----------------------------------------------------------------------------------------------------------*/




#pragma mark - preferences

-(NSRect)newFrameForNewContentView:(NSView *)view {
    NSWindow *window = self.window;
    NSRect newFrameRect = [window frameRectForContentRect:[view frame]];
    NSRect oldFrameRect = [window frame];
    NSSize newSize = newFrameRect.size;
    NSSize oldSize = oldFrameRect.size;
    
    NSRect frame  = [window frame];
    frame.size = newSize;
    frame.origin.y -= (newSize.height - oldSize.height);
    return frame;
}

-(NSView *)viewForTag:(int)viewtag {
    NSView *view = nil;
    switch (viewtag) {
        case 1:
            view = self.accountView;
            break;
        case 2:
            view = self.generalView;
            break;
        case 3:
            view = self.hotkeyView;
            break;
        case 4:
            view = self.menuView;
            break;
        case 5:
            view = self.albumCoverView;
            break;
        case 0:
            view = self.loggedInUserView;
            break;
        default:
            view = self.loggedInUserView;
            break;
    }
    return view;
}


-(BOOL)validateToolbarItem:(NSToolbarItem *)item {
    if ([item tag] == self.currentViewTag) return NO;
    else return YES;
}


-(IBAction)switchView:(id)sender {
    
    int senderTag = (int)[sender tag];
    
    NSView *view = [self viewForTag:senderTag];
    NSView *previousView = [self viewForTag:self.currentViewTag];
    
    self.currentViewTag = senderTag;
    
    NSRect newFrame = [self newFrameForNewContentView:view];
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:0.2];
    if ([[NSApp currentEvent] modifierFlags] & NSShiftKeyMask) {
        [[NSAnimationContext currentContext] setDuration:2];
    }
    [[[self window] animator] setFrame:newFrame display:YES];
    [[[[self window] contentView] animator] replaceSubview:previousView with:view];
    [NSAnimationContext endGrouping];
    [self.window recalculateKeyViewLoop];
    [self.window invalidateShadow];
}

-(NSString *)lastChosenToolbarIdentifier
{
    NSString *identifier;
    switch (self.currentViewTag) {
        case 0:
            identifier = @"Account";
            break;
        case 1:
            identifier = @"Account";
            break;
        case 2:
            identifier = @"General";
            break;
        case 3:
            identifier = @"Hotkeys";
            break;
        case 4:
            identifier = @"Menu";
            break;
        case 5:
            identifier = @"Album Cover";
            break;
        default:
            identifier = @"Account";
            break;
    }
    return identifier;
}

#pragma mark - NSTextField Delegate

-(void)controlTextDidChange:(NSNotification *)obj
{
    if (obj.object == self.passwordField || obj.object == self.loginField) {
        if ([self.passwordField.stringValue length] > 3 && [self.loginField.stringValue length] > 2) {
            [self.loginButton setEnabled:YES];
        }
        else {
            [self.loginButton setEnabled:NO];
        }
    }
}

#pragma mark - User Avatar Method

-(void)setAvatarForUserWithInfo:(NSDictionary *)userInfo
{
    [self.avatarIndicator startAnimation:nil];
    [self setUserAvatarRoundedBorder];

    __block NSImage *image;
    __weak typeof(self) weakSelf = self;
    NSBlockOperation *getAvatarOperation;
    if ([userInfo objectForKey:@"image"]) {
        getAvatarOperation = [NSBlockOperation blockOperationWithBlock:^{
            NSData *imageData = [NSData dataWithContentsOfURL:[userInfo objectForKey:@"image"]];
            NSImage *avatar = [[NSImage alloc] initWithData:imageData];
            image = avatar;
            weakSelf.settingsController.userAvatar = avatar;
                weakSelf.userAvatar.image = avatar;
        }];
    }
    
    else if (self.settingsController.userAvatar) {
        getAvatarOperation = [NSBlockOperation blockOperationWithBlock:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                image = self.settingsController.userAvatar;
                self.userAvatar.image = image;
            });
        }];
    }
    else {
        [self.musicScrobbler.scrobbler getInfoForUserOrNil:self.musicScrobbler.scrobbler.username successHandler:^(NSDictionary *result) {
            if ([result objectForKey:@"image"]) {
                NSData *imageData = [NSData dataWithContentsOfURL:[userInfo objectForKey:@"image"]];
                image = [[NSImage alloc] initWithData:imageData];
                weakSelf.settingsController.userAvatar = image;
                dispatch_async(dispatch_get_main_queue(), ^{
                    weakSelf.userAvatar.image = image;
                    [weakSelf.avatarIndicator stopAnimation:nil];
                });
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    //default avatar
                    weakSelf.userAvatar.image = weakSelf.settingsController.userAvatar;
                    [weakSelf.avatarIndicator stopAnimation:nil];
                    [weakSelf animateAvatar];
                });
            }
        } failureHandler:^(NSError *error) {
            [weakSelf.avatarIndicator stopAnimation:weakSelf];
            weakSelf.userAvatar.image = weakSelf.settingsController.userAvatar;
            [weakSelf.avatarIndicator stopAnimation:nil];
            [weakSelf animateAvatar];
        }];
    }
    NSOperationQueue *operationQueue = [NSOperationQueue new];
    NSBlockOperation *setBorderOperation = [NSBlockOperation blockOperationWithBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.avatarIndicator stopAnimation:weakSelf];
            [weakSelf animateAvatar];
        });
    }];
    [setBorderOperation addDependency:getAvatarOperation];
    [operationQueue addOperation:getAvatarOperation];
    [operationQueue addOperation:setBorderOperation];
}

-(void)setUserAvatarRoundedBorder
{
    [self.userAvatar setWantsLayer: YES];
    self.userAvatar.frame = NSMakeRect(self.userAvatar.frame.origin.x+32.0, self.userAvatar.frame.origin.y+32.0, 0, 0);
    self.userAvatar.layer.cornerRadius = 0.0f;
    self.userAvatar.layer.borderColor = [[NSColor whiteColor] CGColor];
    self.userAvatar.layer.borderWidth = 0.0f;
}

-(void)animateAvatar
{
    POPSpringAnimation *avatarSpringAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPViewFrame];
    avatarSpringAnimation.toValue = [NSValue valueWithRect:NSMakeRect(94, 157, 64, 64)];
    avatarSpringAnimation.springBounciness = 12;
    
    POPSpringAnimation *avatarCornerRadiusSpringAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerCornerRadius];
    avatarCornerRadiusSpringAnimation.toValue = @(32);
    avatarCornerRadiusSpringAnimation.springBounciness = 12;
    
    
    POPSpringAnimation *avatarBorderSpringAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerBorderWidth];
    avatarBorderSpringAnimation.toValue = @(2);
    avatarBorderSpringAnimation.springBounciness = 12;

    [self.userAvatar pop_addAnimation:avatarSpringAnimation forKey:nil];
    [self.userAvatar.layer pop_addAnimation:avatarCornerRadiusSpringAnimation forKey:nil];
    [self.userAvatar.layer pop_addAnimation:avatarBorderSpringAnimation forKey:nil];
}

#pragma mark Reachability
-(void)reachabilityDidChange:(NSNotification *)note
{
    BOOL reachable = [FXReachability isReachable];
    if (!reachable && self.musicController.playerState == iTunesEPlSPlaying && self.settingsController.session) {
        [[UserNotificationsController sharedNotificationsController] displayNotificationThatInternetConnectionIsDown];
        self.reachability = NO;
    } else if (reachable && !self.reachability && self.musicScrobbler.currentTrack && self.offlineScrobbler.tracks.count && self.settingsController.session) {
        [[UserNotificationsController sharedNotificationsController] displayNotificationThatInternetConnectionIsBack];
        self.reachability = YES;
    }
}

#pragma mark - Getters
-(OfflineScrobbler *)offlineScrobbler
{
    if (!_offlineScrobbler) {
        _offlineScrobbler = [OfflineScrobbler sharedInstance];
    }
    return _offlineScrobbler;
}

-(MusicScrobbler *)musicScrobbler
{
    if (!_musicScrobbler) {
        _musicScrobbler = [MusicScrobbler sharedScrobbler];
        _musicScrobbler.delegate = self.offlineScrobbler;
    }
    return _musicScrobbler;
}


-(SettingsController *)settingsController
{
    if (!_settingsController) {
        _settingsController = [SettingsController sharedSettings];
    }
    return _settingsController;
}

-(MusicController *)musicController
{
    if (!_musicController) {
        _musicController = [MusicController sharedController];
    }
    return _musicController;
}

-(GetCover *)getCover
{
    if (!_getCover) {
        _getCover = [[GetCover alloc] init];
        _getCover.delegate = self;
    }
    return _getCover;
}

@end