//
//  AppDelegate.m
//  NepTunes
//
//  Created by rurza on 19.11.2014.
//  Copyright (c) 2014 micropixels. All rights reserved.
//

#import "AppDelegate.h"
#import "MusicScrobbler.h"
#import "HotkeyController.h"
#import <EGOCache.h>
#import "Song.h"
#import <ServiceManagement/ServiceManagement.h>

static NSString *const kUserAvatar = @"userAvatar";
static NSString *const kLaunchAtLogin = @"launchAtLogin";
static NSString *const kHelperAppBundle = @"pl.micropixels.NepTunesHelperApp";

@interface AppDelegate () <NSTextFieldDelegate>


@property (weak, nonatomic) NSTimer* scrobbleTimer;
@property (weak, nonatomic) NSTimer* nowPlayingTimer;


@property (strong, nonatomic) MusicScrobbler *musicScrobbler;

@property (weak, nonatomic) IBOutlet NSTextField *loginField;
@property (weak, nonatomic) IBOutlet NSSecureTextField *passwordField;
@property (weak, nonatomic) IBOutlet NSButton *loginButton;
@property (weak, nonatomic) IBOutlet NSButton *logoutButton;

@property (weak, nonatomic) IBOutlet NSView *accountView;
@property (weak) IBOutlet NSView *loggedInUserView;
@property (weak) IBOutlet NSView *hotkeyView;

@property (weak, nonatomic) IBOutlet NSImageView *userAvatar;

@property (weak, nonatomic) IBOutlet NSButton *createAccountButton;
@property (weak, nonatomic) IBOutlet NSProgressIndicator *indicator;
@property (weak) IBOutlet NSButton *launchAtLoginCheckbox;
@property (weak) IBOutlet NSButton *showStatusBarIcon;

@property NSTimeInterval scrobbleTime;
@property int currentViewTag;
@property (weak) IBOutlet NSToolbarItem *accountToolbarItem;
@property (weak) IBOutlet NSToolbarItem *hotkeysToolbarItem;

- (IBAction)loginClicked:(id)sender;
- (IBAction)logOut:(id)sender;
- (IBAction)createNewLastFmAccountInWebBrowser:(id)sender;


@end

@implementation AppDelegate

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    [self.menuController openPreferences:nil];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                        selector:@selector(updateTrackInfo:)
                                                            name:@"com.apple.iTunes.playerInfo"
                                                          object:nil];
    
    
    self.passwordField.delegate = self;
    self.loginField.delegate = self;
    [self updatePreferencesUI];
    [self terminateHelperApp];
    [self updateTrackInfo:nil];
    
}

-(void)updatePreferencesUI
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.launchAtLoginCheckbox.state = [defaults boolForKey:kLaunchAtLogin];
    self.showStatusBarIcon.state = [defaults boolForKey:kShowStatusBarIcon];
}

-(void)terminateHelperApp
{
    BOOL startedAtLogin = NO;
    
    NSArray *apps = [[NSWorkspace sharedWorkspace] runningApplications];
    for (NSRunningApplication *app in apps) {
        if ([app.bundleIdentifier isEqualToString:kHelperAppBundle]) startedAtLogin = YES;
    }
    
    if (startedAtLogin) {
        [[NSDistributedNotificationCenter defaultCenter] postNotificationName:kHelperAppBundle
                                                                       object:[[NSBundle mainBundle] bundleIdentifier]];
        if (![[[NSUserDefaults standardUserDefaults] objectForKey:kLaunchAtLogin] boolValue]) {
            
            [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:kLaunchAtLogin];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
}

-(void)awakeFromNib {
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{kShowStatusBarIcon: @YES}];

    self.musicScrobbler = [MusicScrobbler sharedScrobbler];
    if (self.musicScrobbler.scrobbler.session) {
        self.accountToolbarItem.tag = 0;
        [[self window] setContentSize:[self.loggedInUserView frame].size];
        [[[self window] contentView ] addSubview:self.loggedInUserView];
        [self.logoutButton setTitle:[NSString stringWithFormat:@"Log out %@", self.musicScrobbler.scrobbler.username]];
        [self setAvatarForUserWithInfo:nil];
    }
    else {
        [[self window] setContentSize:[self.accountView frame].size];
        [[[self window] contentView ] addSubview:self.accountView];
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

#pragma mark - Responding to notifications

- (void)updateTrackInfo:(NSNotification *)note {
    [self invalidateTimers];
    [self getInfoAboutTrackFromNotificationOrFromiTunes:note.userInfo];
    [self updateMenu];
    
    if ([self.musicScrobbler.iTunes isRunning]) {
        if (self.musicScrobbler.iTunes.playerState == iTunesEPlSPlaying) {
            //NSLog(@"%@ by %@ with length = %f after 2 sec.", self.musicScrobbler.trackName, self.musicScrobbler.artist, self.musicScrobbler.duration);
            NSTimeInterval trackLength;
            
            
            if (self.musicScrobbler.iTunes.currentTrack.artist) {
                trackLength = (NSTimeInterval)self.musicScrobbler.iTunes.currentTrack.duration;
            }
            else {
                trackLength = (NSTimeInterval)self.musicScrobbler.currentTrack.duration;
            }
            NSTimeInterval scrobbleTime = trackLength / 2.0f - 2.0f;
            
            if (trackLength > 31.0f) {
                self.nowPlayingTimer = [NSTimer scheduledTimerWithTimeInterval:5
                                                                        target:self
                                                                      selector:@selector(nowPlaying)
                                                                      userInfo:nil
                                                                       repeats:NO];
            }
            if (trackLength > 31.0f) {
                NSDictionary *userInfo = [note.userInfo copy];
                self.scrobbleTimer = [NSTimer scheduledTimerWithTimeInterval:scrobbleTime
                                                                      target:self
                                                                    selector:@selector(scrobble:)
                                                                    userInfo:userInfo
                                                                     repeats:NO];
            }
        }
    }
    //    });
}

-(void)invalidateTimers
{
    if (self.scrobbleTimer) {
        [self.scrobbleTimer invalidate];
        self.scrobbleTimer = nil;
    }
    if (self.nowPlayingTimer) {
        [self.nowPlayingTimer invalidate];
        self.nowPlayingTimer = nil;
    }
}

-(void)getInfoAboutTrackFromNotificationOrFromiTunes:(NSDictionary *)userInfo
{
    self.musicScrobbler.infoAboutCurrentTrack = userInfo;
    
    //2s są po to by Itunes sie ponownie nie wlaczal
    //    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    if (self.musicScrobbler.iTunes.isRunning) {
        if (self.musicScrobbler.currentTrack.trackName && self.musicScrobbler.currentTrack.artist && self.musicScrobbler.currentTrack.duration == 0) {
            self.musicScrobbler.currentTrack.duration = self.musicScrobbler.iTunes.currentTrack.duration;
        }
        else if (self.musicScrobbler.iTunes.currentTrack.name && self.musicScrobbler.iTunes.currentTrack.album) {
            self.musicScrobbler.currentTrack.trackName = self.musicScrobbler.iTunes.currentTrack.name;
            self.musicScrobbler.currentTrack.album = self.musicScrobbler.iTunes.currentTrack.album;
            self.musicScrobbler.currentTrack.artist = self.musicScrobbler.iTunes.currentTrack.artist;
            self.musicScrobbler.currentTrack.duration = self.musicScrobbler.iTunes.currentTrack.duration;
            [self.menuController changeState];
        }
    }
}

-(void)updateMenu
{
    if (self.musicScrobbler.iTunes.isRunning) {
        [self.menuController changeState];
    }
}

-(void)scrobble:(NSTimer *)timer
{
    [self.musicScrobbler scrobbleCurrentTrack];
}

-(void)nowPlaying
{
    [self.musicScrobbler nowPlayingCurrentTrack];
}



/*----------------------------------------------------------------------------------------------------------*/
#pragma mark - Managing account

- (IBAction)loginClicked:(id)sender {
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
             [[NSUserDefaults standardUserDefaults] setObject:weakSelf.musicScrobbler.username forKey:kUsernameKey];
             [[NSUserDefaults standardUserDefaults] synchronize];
             
             [weakSelf.musicScrobbler.scrobbler getInfoForUserOrNil:self.loginField.stringValue successHandler:^(NSDictionary *result) {
                 [weakSelf setAvatarForUserWithInfo:result];
             } failureHandler:^(NSError *error) {
                 //NSLog(@"Error info about user. %@", [error localizedDescription]);
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
                 [weakSelf loginClicked:weakSelf];
             }
             else {
                 [weakSelf.indicator stopAnimation:weakSelf];
                 
                 weakSelf.passwordField.stringValue = @"";
                 [weakSelf.loginButton setTitle:@"Log in"];
                 [weakSelf.loginButton setEnabled:YES];
                 weakSelf.loginField.hidden = NO;
                 weakSelf.passwordField.hidden = NO;
                 [weakSelf.createAccountButton setHidden:NO];
                 NSAlert *alert = [[NSAlert alloc] init];
                 alert.alertStyle = NSCriticalAlertStyle;
                 alert.informativeText = [error localizedDescription];
                 alert.messageText = @"Try again...";
                 [alert runModal];
             }
         }];
    }
}

- (IBAction)logOut:(id)sender
{
    [self.loginButton setEnabled:NO];
    [self.musicScrobbler logOut];
    self.userAvatar.image = nil;
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kUserAvatar];
    [self.menuController changeState];
    
    self.accountToolbarItem.tag = 1;
    [self switchView:self.accountToolbarItem];
    
}


- (IBAction)createNewLastFmAccountInWebBrowser:(id)sender {
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
        [[NSAnimationContext currentContext] setDuration:1.0];
    }
    [[[self window] animator] setFrame:newFrame display:YES];
    [[[[self window] contentView] animator] replaceSubview:previousView with:view];
    [NSAnimationContext endGrouping];
    [self.window recalculateKeyViewLoop];
}

-(IBAction)toggleLaunchAtLogin:(NSButton *)sender
{
    if (sender.state) { // ON
        // Turn on launch at login
        if (!SMLoginItemSetEnabled ((__bridge CFStringRef)kHelperAppBundle, YES)) {
            sender.state = NSOffState;
            NSAlert *alert = [NSAlert alertWithMessageText:@"An error ocurred"
                                             defaultButton:@"OK"
                                           alternateButton:nil
                                               otherButton:nil
                                 informativeTextWithFormat:@"Couldn't add Helper App to launch at login item list."];
            [alert runModal];
        } else {
            [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:kLaunchAtLogin];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
    if (!sender.state) { // OFF
        // Turn off launch at login
        if (!SMLoginItemSetEnabled ((__bridge CFStringRef)kHelperAppBundle, NO)) {
            sender.state = NSOnState;
            NSAlert *alert = [NSAlert alertWithMessageText:@"An error ocurred"
                                             defaultButton:@"OK"
                                           alternateButton:nil
                                               otherButton:nil
                                 informativeTextWithFormat:@"Couldn't remove Helper App from launch at login item list."];
            [alert runModal];
        } else {
            [[NSUserDefaults standardUserDefaults] setObject:@NO forKey:kLaunchAtLogin];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
}

-(IBAction)toggleShowStatusBarIcon:(NSButton *)sender
{
    if (sender.state) {
        [self.menuController installStatusBarItem];
    }
    else {
        [self.menuController removeStatusBarItem];
    }

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@(sender.state) forKey:kShowStatusBarIcon];
    [defaults synchronize];
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

#pragma User Avatar Method

-(void)setAvatarForUserWithInfo:(NSDictionary *)userInfo
{
    __block NSImage *image;
    if ([userInfo objectForKey:@"image"]) {
        NSData *imageData = [NSData dataWithContentsOfURL:[userInfo objectForKey:@"image"]];
        NSImage *avatar = [[NSImage alloc] initWithData:imageData];
        image = avatar;
        [[NSUserDefaults standardUserDefaults] setObject:imageData forKey:kUserAvatar];
        self.userAvatar.image = avatar;
    }
    else if ([[NSUserDefaults standardUserDefaults] dataForKey:kUserAvatar]) {
        image = [[NSImage alloc] initWithData:[[NSUserDefaults standardUserDefaults] dataForKey:kUserAvatar]];
        self.userAvatar.image = image;
    }
    else {
        [self.musicScrobbler.scrobbler getInfoForUserOrNil:self.musicScrobbler.scrobbler.username successHandler:^(NSDictionary *result) {
            if ([result objectForKey:@"image"]) {
                NSData *imageData = [NSData dataWithContentsOfURL:[userInfo objectForKey:@"image"]];
                image = [[NSImage alloc] initWithData:imageData];
                [[NSUserDefaults standardUserDefaults] setObject:imageData forKey:kUserAvatar];
                self.userAvatar.image = image;
            } else {
                NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:@"http://cdn.last.fm/flatness/responsive/2/noimage/default_user_140_g2.png"]];
                image = [[NSImage alloc] initWithData:imageData];
                self.userAvatar.image = image;
                [[NSUserDefaults standardUserDefaults] setObject:imageData forKey:kUserAvatar];
            }
        } failureHandler:^(NSError *error) {
            
        }];
    }
    if (image) {
        [self.userAvatar setWantsLayer: YES];
        self.userAvatar.layer.cornerRadius = 32.0f;
        self.userAvatar.layer.borderColor = [[NSColor whiteColor] CGColor];
        self.userAvatar.layer.borderWidth = 2.0f;
    }
}



@end
