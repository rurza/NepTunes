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
#import "HotkeyController.h"
#import "PreferencesCoverController.h"
#import <POP.h>

static NSString *const kAccountItemToolbarIdentifier = @"Account";


@interface PreferencesController () <NSTextFieldDelegate>
@property (nonatomic) IBOutlet NSTextField *loginField;
@property (nonatomic) IBOutlet NSSecureTextField *passwordField;
@property (nonatomic) IBOutlet NSButton *loginButton;
@property (nonatomic) IBOutlet NSButton *logoutButton;

@property (nonatomic) IBOutlet NSView *accountView;
@property (nonatomic) IBOutlet NSView *loggedInUserView;
@property (nonatomic) IBOutlet NSView *hotkeyView;
@property (nonatomic) IBOutlet NSView *generalView;
@property (nonatomic) IBOutlet NSView *albumCoverView;


@property (nonatomic) IBOutlet NSImageView *userAvatar;

@property (nonatomic) IBOutlet NSButton *createAccountButton;
@property (nonatomic) IBOutlet NSProgressIndicator *indicator;
@property (nonatomic) IBOutlet NSProgressIndicator *avatarIndicator;

@property (nonatomic) int currentViewTag;
@property (nonatomic) IBOutlet NSToolbarItem *accountToolbarItem;
@property (nonatomic) IBOutlet NSToolbarItem *hotkeysToolbarItem;
@property (nonatomic) IBOutlet NSToolbarItem *generalToolbarItem;
@property (nonatomic) IBOutlet NSToolbarItem *albumCoverToolbarItem;
@property (nonatomic) IBOutlet HotkeyController *hotkeyController;
@property (nonatomic) IBOutlet PreferencesCoverController *preferencesCoverController;

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



- (IBAction)loginClicked:(id)sender;
- (IBAction)logOut:(id)sender;
- (IBAction)createNewLastFmAccountInWebBrowser:(id)sender;



@end

@implementation PreferencesController

#pragma mark - Initialization


- (void)windowDidLoad
{
    [super windowDidLoad];
    [self setupReachability];
    self.passwordField.delegate = self;
    self.loginField.delegate = self;
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
        self.currentViewTag = 2;
        [[self window] setContentSize:[self.generalView frame].size];
        [[[self window] contentView ] addSubview:self.generalView];
        [self.settingsToolbar setSelectedItemIdentifier:@"General"];
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
             [[MenuController sharedController] updateMenu];
             
             
             [weakSelf.indicator stopAnimation:weakSelf];
             weakSelf.loginField.hidden = NO;
             weakSelf.passwordField.hidden = NO;
             [weakSelf.createAccountButton setHidden:NO];
             
             [weakSelf.loginButton setTitle:@"Sign In"];
             [weakSelf.logoutButton setTitle:[NSString stringWithFormat:@"Sign Out %@", weakSelf.settingsController.username]];
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
                 [weakSelf.loginButton setTitle:NSLocalizedString(@"Sign In", nil)];
                 [weakSelf.loginButton setEnabled:NO];
                 weakSelf.loginField.hidden = NO;
                 weakSelf.passwordField.hidden = NO;
                 [weakSelf.createAccountButton setHidden:NO];
                 NSAlert *alert = [[NSAlert alloc] init];
                 alert.alertStyle = NSCriticalAlertStyle;
                 if (error.code == kLastFmErrorCodeAuthenticationFailed) {
                     alert.informativeText = NSLocalizedString(@"It looks like you typed wrong username or/and password. 🤔\nYou can always change the password on the Last.fm website.", nil);
                 } else {
                     alert.informativeText = [error localizedDescription];
                 }
                 alert.messageText = NSLocalizedString(@"Try again 😤", nil);
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
    [[MenuController sharedController] updateMenu];
    
    self.accountToolbarItem.tag = 1;
    [self switchView:self.accountToolbarItem];
    
}

- (IBAction)createNewLastFmAccountInWebBrowser:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://secure.last.fm/join"]];
}


/*----------------------------------------------------------------------------------------------------------*/




#pragma mark - preferences


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
        case 5:
            view = self.albumCoverView;
            break;
        case 0:
            view = self.loggedInUserView;
            break;
        default:
            view = self.generalView;
            break;
    }
    if (viewtag == 5) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.preferencesCoverController animateCover];
        });
    }
    return view;
}


-(BOOL)validateToolbarItem:(NSToolbarItem *)item {
    if ([item tag] == self.currentViewTag) return NO;
    else return YES;
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
        case 5:
            identifier = @"Album Cover";
            break;
        default:
            identifier = @"General";
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

-(void)dealloc
{
    NSLog(@"Preferences deallocated");
}

@end