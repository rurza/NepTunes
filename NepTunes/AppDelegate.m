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

static NSString *const kUserAvatar = @"userAvatar";

@interface AppDelegate () <NSTextFieldDelegate>

@property (strong, nonatomic) NSStatusItem *statusItem;

@property (weak, nonatomic) NSTimer* callTimer;

@property (strong, nonatomic) MusicScrobbler *musicScrobbler;
@property (strong, nonatomic) IBOutlet NSMenu *statusMenu;

@property (weak, nonatomic) IBOutlet NSTextField *loginField;
@property (weak, nonatomic) IBOutlet NSSecureTextField *passwordField;
@property (weak, nonatomic) IBOutlet NSButton *loginButton;
@property (weak, nonatomic) IBOutlet NSButton *logoutButton;

@property (weak, nonatomic) IBOutlet NSWindow *window;
@property (weak, nonatomic) IBOutlet NSView *accountView;
@property (weak) IBOutlet NSView *loggedInUserView;
@property (weak) IBOutlet NSView *hotkeyView;

@property (weak, nonatomic) IBOutlet NSImageView *userAvatar;

@property (weak, nonatomic) IBOutlet NSButton *createAccountButton;
@property (weak, nonatomic) IBOutlet NSProgressIndicator *indicator;

@property NSTimeInterval scrobbleTime;
@property int currentViewTag;
@property (weak) IBOutlet NSToolbarItem *accountToolbarItem;
@property (weak) IBOutlet NSToolbarItem *hotkeysToolbarItem;

- (IBAction)loginClicked:(id)sender;
- (IBAction)logOut:(id)sender;
- (IBAction)createNewLastFmAccountInWebBrowser:(id)sender;


@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
    
    //System status bar icon
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    NSImage *icon = [NSImage imageNamed:@"statusIcon"];
    [icon setTemplate:YES];
    self.statusItem.image = icon;
    self.statusItem.menu = self.statusMenu;
    
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                        selector:@selector(updateTrackInfo)
                                                            name:@"com.apple.iTunes.playerInfo"
                                                          object:nil];
    
    
    //first launch
    if (!self.musicScrobbler.scrobbler.session) {
        [self openPreferences:self];
    }
   
    self.passwordField.delegate = self;
    self.loginField.delegate = self;
    
    [self changeState];
    if ([self.musicScrobbler.iTunes isRunning]) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self updateTrackInfo];
            
        });
    }

}



-(void)awakeFromNib {
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
//    [[[self window] contentView] setWantsLayer:YES];
    [self.window recalculateKeyViewLoop];
    
    NSColor *color = [NSColor colorWithSRGBRed:0.2896 green:0.5448 blue:0.9193 alpha:1.0];
    NSMutableAttributedString *colorTitle = [[NSMutableAttributedString alloc] initWithAttributedString:[self.createAccountButton attributedTitle]];
    NSRange titleRange = NSMakeRange(0, [colorTitle length]);
    [colorTitle addAttribute:NSForegroundColorAttributeName value:color range:titleRange];
    [self.createAccountButton setAttributedTitle:colorTitle];

//    self.hotkeyController = [[HotkeyController alloc] init];

}


- (void)updateTrackInfo {
    [self changeState];
    if ([self.musicScrobbler.iTunes isRunning]) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSTimeInterval trackLength = (NSTimeInterval)[self.musicScrobbler.iTunes.currentTrack duration];
            NSTimeInterval scrobbleTime = trackLength / 2;
            
            if (trackLength > 31) {
                [self nowPlaying];
            }
            
            if (self.callTimer) {
                [self.callTimer invalidate];
                self.callTimer = nil;
            }
            
            if (trackLength > 31) {
                self.callTimer = [NSTimer scheduledTimerWithTimeInterval:scrobbleTime
                                                                  target:self
                                                                selector:@selector(scrobble)
                                                                userInfo:nil
                                                                 repeats:NO];
            }
        });
    }
}


-(void)scrobble
{
    [self.musicScrobbler scrobbleCurrentTrack];
}

-(void)nowPlaying
{
    [self.musicScrobbler nowPlayingCurrentTrack];
}




#pragma mark - Last.fm related


-(IBAction)loveSong:(id)sender {
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    [self.musicScrobbler loveCurrentTrackWithCompletionHandler:^{
        [notification setTitle:[NSString stringWithFormat:@"%@", self.musicScrobbler.iTunes.currentTrack.artist]];
        [notification setInformativeText:[NSString stringWithFormat:@"%@ ❤️ at Last.fm", self.musicScrobbler.iTunes.currentTrack.name]];
        [notification setDeliveryDate:[NSDate dateWithTimeInterval:1 sinceDate:[NSDate date]]];
        
        [[NSUserNotificationCenter defaultUserNotificationCenter] scheduleNotification:notification];
    }];
}

/*----------------------------------------------------------------------------------------------------------*/


- (IBAction)loginClicked:(id)sender {
    if (!([self.passwordField.stringValue isEqualTo: @""] || [self.loginField.stringValue isEqualTo: @""]))
    {
        [self.indicator startAnimation:self];

        self.loginField.hidden = YES;
        self.passwordField.hidden = YES;
        [self.createAccountButton setHidden:YES];


        [self.loginButton setTitle:@"Logging in..."];
        [self.loginButton setEnabled:NO];
        [self.musicScrobbler.scrobbler getSessionForUser:self.loginField.stringValue
                                                password:self.passwordField.stringValue
                                          successHandler:^(NSDictionary *result)
        {
            //login success handler
            [self.musicScrobbler logInWithCredentials:result];
            
            [self.musicScrobbler.scrobbler getInfoForUserOrNil:self.loginField.stringValue successHandler:^(NSDictionary *result) {
                [self setAvatarForUserWithInfo:result];
                } failureHandler:^(NSError *error) {
                NSLog(@"Error info about user. %@", [error localizedDescription]);
            }];
            self.accountToolbarItem.tag = 0;
            [self switchView:self.accountToolbarItem];
            [self changeState];
            
            [self.indicator stopAnimation:self];
            self.loginField.hidden = NO;
            self.passwordField.hidden = NO;
            [self.createAccountButton setHidden:NO];

            [self.loginButton setTitle:@"Log in"];
            [self.logoutButton setTitle:[NSString stringWithFormat:@"Log out %@", result[@"name"]]];
            self.passwordField.stringValue = @"";
            
        } failureHandler:^(NSError *error) {
            if (error.code == -1001) {
                [self loginClicked:self];
            }
            else {
                [self.indicator stopAnimation:self];

                self.passwordField.stringValue = @"";
                [self.loginButton setTitle:@"Log in"];
                [self.loginButton setEnabled:YES];
                self.loginField.hidden = NO;
                self.passwordField.hidden = NO;
                [self.createAccountButton setHidden:NO];
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
    if ([[EGOCache globalCache] hasCacheForKey:kUserAvatar]) {
        [[EGOCache globalCache] removeCacheForKey:kUserAvatar];
        self.userAvatar.image = nil;
    }
    [self changeState];
    self.accountToolbarItem.tag = 1;
    [self switchView:self.accountToolbarItem];

}


- (IBAction)createNewLastFmAccountInWebBrowser:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://secure.last.fm/join"]];

}


#pragma mark - Menu Bar Items

- (IBAction)showUserProfile:(id)sender {
    if (self.musicScrobbler.scrobbler.session) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.last.fm/user/%@", self.musicScrobbler.scrobbler.username]]];
    }
}



-(IBAction)showSimilarArtists:(id)sender {
    NSString *str = self.musicScrobbler.iTunes.currentTrack.artist;
    NSString *url = [str stringByReplacingOccurrencesOfString:@" " withString:@"+"];
    NSData *decode = [url dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *ansi = [[NSString alloc] initWithData:decode encoding:NSASCIIStringEncoding];
    
    if (ansi.length > 0) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.last.fm/music/%@/+similar", ansi]]];
    }
}


-(IBAction)quit:(id)sender {
    [[NSApplication sharedApplication] terminate:self];
}

-(IBAction)openPreferences:(id)sender {
    [NSApp activateIgnoringOtherApps:YES];
    [self.window makeKeyAndOrderFront:self];
}

/*----------------------------------------------------------------------------------------------------------*/


#pragma mark Update menu

-(void)changeState {
    if (self.musicScrobbler.scrobbler.session) {
        [self.profileMenuTitle setEnabled:YES];
        self.profileMenuTitle.title = [NSString stringWithFormat:@"%@'s profile...", self.musicScrobbler.scrobbler.username];
        if ([self.musicScrobbler.iTunes isRunning]) {
            if (self.musicScrobbler.iTunes.currentTrack.name) {
                [self.loveSongMenuTitle setEnabled:YES];
                [self.similarArtistMenuTtitle setEnabled:YES];
                self.similarArtistMenuTtitle.title = [NSString stringWithFormat:@"Similar artists to %@...", self.musicScrobbler.iTunes.currentTrack.artist];
                self.loveSongMenuTitle.title = [NSString stringWithFormat:@"Love %@ on Last.fm", self.musicScrobbler.iTunes.currentTrack.name];
            }
            else {
                [self.loveSongMenuTitle setEnabled:NO];
                [self.similarArtistMenuTtitle setEnabled:NO];
                self.similarArtistMenuTtitle.title = [NSString stringWithFormat:@"Similar artists..."];
                self.loveSongMenuTitle.title = [NSString stringWithFormat:@"Love song on Last.fm"];
            }
        }
        else {
            [self.loveSongMenuTitle setEnabled:NO];
            [self.similarArtistMenuTtitle setEnabled:NO];
            self.loveSongMenuTitle.title = [NSString stringWithFormat:@"Love song on Last.fm"];
            self.similarArtistMenuTtitle.title = [NSString stringWithFormat:@"Similar artists..."];
        }
    }
    else {
        [self.loveSongMenuTitle setEnabled:NO];
        [self.profileMenuTitle setEnabled:NO];
        self.profileMenuTitle.title = [NSString stringWithFormat:@"Profile... (Log in)"];
        if ([self.musicScrobbler.iTunes isRunning]) {
            if (self.musicScrobbler.iTunes.currentTrack.name) {
                self.loveSongMenuTitle.title = [NSString stringWithFormat:@"Love on Last.fm (Log in)"];
                self.similarArtistMenuTtitle.title = [NSString stringWithFormat:@"Similar artists to %@...", self.musicScrobbler.iTunes.currentTrack.artist];
                [self.similarArtistMenuTtitle setEnabled:YES];
            }
            else {
                self.loveSongMenuTitle.title = [NSString stringWithFormat:@"Love on Last.fm (Log in)"];
                self.similarArtistMenuTtitle.title = [NSString stringWithFormat:@"Similar artists..."];
                [self.similarArtistMenuTtitle setEnabled:NO];
            }
        }
        else {
            [self.similarArtistMenuTtitle setEnabled:NO];
            self.loveSongMenuTitle.title = [NSString stringWithFormat:@"Love song on Last.fm (Log in)"];
            self.similarArtistMenuTtitle.title = [NSString stringWithFormat:@"Similar artists..."];
        }
    }
}



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
        [[NSAnimationContext currentContext] setDuration:0.5];
    }
    [[[[self window] contentView] animator] replaceSubview:previousView with:view];
    [[[self window] animator] setFrame:newFrame display:YES];

    [NSAnimationContext endGrouping];
    [self.window recalculateKeyViewLoop];
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
    NSImage *image;
    if ([userInfo objectForKey:@"image"]) {
        NSData *imageData = [NSData dataWithContentsOfURL:[userInfo objectForKey:@"image"]];
        NSImage *avatar = [[NSImage alloc] initWithData:imageData];
        image = avatar;
        [[EGOCache globalCache] setImage:avatar forKey:kUserAvatar];
        self.userAvatar.image = avatar;
    }
    else if ([[EGOCache globalCache] hasCacheForKey:kUserAvatar]) {
        image = [[EGOCache globalCache] imageForKey:kUserAvatar];
        self.userAvatar.image = image;
    }
    else {
        image = [[NSImage alloc] initWithContentsOfURL:[NSURL URLWithString:@"http://cdn.last.fm/flatness/responsive/2/noimage/default_user_140_g2.png"]];
        self.userAvatar.image = image;
         [[EGOCache globalCache] setImage:image forKey:kUserAvatar];
    }
    if (image) {
        [self.userAvatar setWantsLayer: YES];
        self.userAvatar.layer.cornerRadius = 32.0f;
        self.userAvatar.layer.borderColor = [[NSColor whiteColor] CGColor];
        self.userAvatar.layer.borderWidth = 2.0f;
    }
}



@end
