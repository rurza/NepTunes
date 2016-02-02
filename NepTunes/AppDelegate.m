//
//  AppDelegate.m
//  NepTunes
//
//  Created by rurza on 19.11.2014.
//  Copyright (c) 2014 micropixels. All rights reserved.
//

#import "AppDelegate.h"
#import "MusicScrobbler.h"
#import "Track.h"
#import "FXReachability.h"
#import "OfflineScrobbler.h"
#import "SettingsController.h"
#import "LastFm.h"
#import "UserNotificationsController.h"
#import "MusicController.h"

static NSString *const kAccountItemToolbarIdentifier = @"Account";

@interface AppDelegate () <NSTextFieldDelegate>
@property (weak, nonatomic) IBOutlet NSTextField *loginField;
@property (weak, nonatomic) IBOutlet NSSecureTextField *passwordField;
@property (weak, nonatomic) IBOutlet NSButton *loginButton;
@property (weak, nonatomic) IBOutlet NSButton *logoutButton;

@property (weak, nonatomic) IBOutlet NSView *accountView;
@property (weak, nonatomic) IBOutlet NSView *loggedInUserView;
@property (weak, nonatomic) IBOutlet NSView *hotkeyView;
@property (weak, nonatomic) IBOutlet NSView *generalView;

@property (weak, nonatomic) IBOutlet NSImageView *userAvatar;

@property (weak, nonatomic) IBOutlet NSButton *createAccountButton;
@property (weak, nonatomic) IBOutlet NSProgressIndicator *indicator;
@property (weak, nonatomic) IBOutlet NSProgressIndicator *avatarIndicator;

@property (nonatomic) int currentViewTag;
@property (weak, nonatomic) IBOutlet NSToolbarItem *accountToolbarItem;
@property (weak, nonatomic) IBOutlet NSToolbarItem *hotkeysToolbarItem;
@property (weak, nonatomic) IBOutlet NSToolbarItem *generalToolbarItem;

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



@implementation AppDelegate

-(void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
//    [self setupNotifications];
    [self setupReachability];
    self.passwordField.delegate = self;
    self.loginField.delegate = self;
}

-(void)applicationDidBecomeActive:(NSNotification *)notification
{
    if (self.settingsController.hideStatusBarIcon) {
        [self.menuController openPreferences:nil];
    }
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

             dispatch_async(dispatch_get_main_queue(), ^{
                 [weakSelf.avatarIndicator startAnimation:weakSelf];
             });
             [weakSelf.musicScrobbler.scrobbler getInfoForUserOrNil:self.loginField.stringValue successHandler:^(NSDictionary *result) {
                 [weakSelf setAvatarForUserWithInfo:result];
             } failureHandler:^(NSError *error) {
                 dispatch_async(dispatch_get_main_queue(), ^{
                     [weakSelf.avatarIndicator stopAnimation:weakSelf];
                 });
             }];
             weakSelf.accountToolbarItem.tag = 0;
             [weakSelf switchView:weakSelf.accountToolbarItem];
             [weakSelf.menuController changeState];
             
             
             [weakSelf.indicator stopAnimation:weakSelf];
             weakSelf.loginField.hidden = NO;
             weakSelf.passwordField.hidden = NO;
             [weakSelf.createAccountButton setHidden:NO];
             
             [weakSelf.loginButton setTitle:@"Log in"];
             [weakSelf.logoutButton setTitle:[NSString stringWithFormat:@"Log out %@", weakSelf.musicScrobbler.username]];
             weakSelf.passwordField.stringValue = @"";
             
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
                     alert.informativeText = [NSString stringWithFormat:NSLocalizedString(@"%@.\n%@", nil), [error localizedDescription], @"Check your username and password.", nil];
                 } else {
                     alert.informativeText = [error localizedDescription];
                 }
                 alert.messageText = NSLocalizedString(@"Try again...", nil);
                 [alert beginSheetModalForWindow:weakSelf.window completionHandler:^(NSModalResponse returnCode) {
                     [alert.window close];
                 }];
             }
         }];
    }
}

- (IBAction)logOut:(id)sender
{
    [self.loginButton setEnabled:NO];
    [self.musicScrobbler logOut];
    self.offlineScrobbler.userWasLoggedOut = YES;
    self.userAvatar.image = nil;
    self.settingsController.userAvatar = nil;
    [self.menuController changeState];
    
    self.accountToolbarItem.tag = 1;
    [self switchView:self.accountToolbarItem];
}


- (IBAction)createNewLastFmAccountInWebBrowser:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://secure.last.fm/join"]];
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
    
    if ([[NSApp currentEvent] modifierFlags] & NSShiftKeyMask) {
        [[NSAnimationContext currentContext] setDuration:0.4];
    }
    [[[self window] animator] setFrame:newFrame display:YES];
    [[[[self window] contentView] animator] replaceSubview:previousView with:view];
    [NSAnimationContext endGrouping];
    [self.window recalculateKeyViewLoop];
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
    __block NSImage *image;
    __weak typeof(self) weakSelf = self;
    if ([userInfo objectForKey:@"image"]) {
        NSData *imageData = [NSData dataWithContentsOfURL:[userInfo objectForKey:@"image"]];
        NSImage *avatar = [[NSImage alloc] initWithData:imageData];
        image = avatar;
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.settingsController.userAvatar = avatar;
            [weakSelf.avatarIndicator stopAnimation:weakSelf];
            weakSelf.userAvatar.image = avatar;
        });
    }
    else if (self.settingsController.userAvatar) {
        image = self.settingsController.userAvatar;
        self.userAvatar.image = image;
        [self.avatarIndicator stopAnimation:self];

    }
    else {
        [weakSelf.avatarIndicator startAnimation:weakSelf];
        [self.musicScrobbler.scrobbler getInfoForUserOrNil:self.musicScrobbler.scrobbler.username successHandler:^(NSDictionary *result) {
            if ([result objectForKey:@"image"]) {
                NSData *imageData = [NSData dataWithContentsOfURL:[userInfo objectForKey:@"image"]];
                image = [[NSImage alloc] initWithData:imageData];
                weakSelf.settingsController.userAvatar = image;
                dispatch_async(dispatch_get_main_queue(), ^{
                    weakSelf.userAvatar.image = image;
                });
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf.avatarIndicator stopAnimation:weakSelf];
                    //tu ma być self
                    weakSelf.userAvatar.image = weakSelf.settingsController.userAvatar;
                });
            }
        } failureHandler:^(NSError *error) {
            [weakSelf.avatarIndicator stopAnimation:weakSelf];
        }];
    }
    if (image) {
        [self.userAvatar setWantsLayer: YES];
        self.userAvatar.layer.cornerRadius = 32.0f;
        self.userAvatar.layer.borderColor = [[NSColor whiteColor] CGColor];
        self.userAvatar.layer.borderWidth = 2.0f;
    }
}

#pragma mark Reachability

-(void)reachabilityDidChange:(NSNotification *)note
{
    BOOL reachable = [FXReachability isReachable];
    if (!reachable && self.musicController.playerState == iTunesEPlSPlaying && self.settingsController.session) {
        [[UserNotificationsController sharedNotificationsController] displayNotificationThatInternetConnectionIsDown];
        self.reachability = NO;
    } else if (reachable && !self.reachability && self.musicController.playerState == iTunesEPlSPlaying && self.offlineScrobbler.songs.count && self.settingsController.session) {
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
@end
