//
//  AppDelegate.m
//  NepTunes
//
//  Created by rurza on 19.11.2014.
//  Copyright (c) 2014 micropixels. All rights reserved.
//

#define SESSION_KEY @"is.rurzynski.lastfm.tunesfm.session"
#define USERNAME_KEY @"is.rurzynski.lastfm.tunesfm.username"

#import "AppDelegate.h"
#import "iTunes.h"
#import "DDHotKeyCenter.h"
#import "MusicScrobbler.h"

@interface AppDelegate ()

//@property (strong, nonatomic) LastFmCache *lastFmCache;
@property (strong, nonatomic) NSStatusItem *statusItem;
//@property (strong) iTunesApplication* iTunes;
@property (weak, nonatomic) NSTimer* callTimer;
//@property (strong) NSDistributedNotificationCenter* dnc;
//@property (strong) NSUserNotificationCenter *center;

@property (strong, nonatomic) MusicScrobbler *musicScrobbler;
@property (strong) IBOutlet NSMenu *statusMenu;
@property (weak, nonatomic) IBOutlet NSMenuItem *loveSongMenuTitle;
@property (weak, nonatomic) IBOutlet NSMenuItem *profileMenuTitle;
@property (weak, nonatomic) IBOutlet NSMenuItem *similarArtistMenuTtitle;
@property (weak, nonatomic) IBOutlet NSTextField *loginField;
@property (weak, nonatomic) IBOutlet NSSecureTextField *passwordField;
@property (weak, nonatomic) IBOutlet NSButton *loginButton;
@property (weak, nonatomic) IBOutlet NSWindow *window;
@property (weak, nonatomic) IBOutlet NSView *accountView;
@property (weak, nonatomic) IBOutlet NSProgressIndicator *indicator;




@property NSTimeInterval scrobbleTime;
@property int currentViewTag;
@property BOOL menuItemState;


- (IBAction)switchView:(id)sender;
- (IBAction)loginClicked:(id)sender;



@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    DDHotKeyCenter *loveSongHotKey = [DDHotKeyCenter sharedHotKeyCenter];
    [loveSongHotKey registerHotKeyWithKeyCode:0x25 modifierFlags:NSControlKeyMask|NSCommandKeyMask target:self action:@selector(loveSong:) object:nil];
    
    //System status bar icon
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    NSImage *icon = [NSImage imageNamed:@"statusIcon"];
    [icon setTemplate:YES];
    self.statusItem.image = icon;
    self.statusItem.menu = self.statusMenu;
    
    if (![[NSUserDefaults standardUserDefaults] stringForKey:@"firstLaunch"]) {
        NSLog(@"NepTunes first launch. %@", [[NSUserDefaults standardUserDefaults] stringForKey:@"firstLaunch"]);
        [self openPreferences:self];
        [[NSUserDefaults standardUserDefaults] setObject:@"Launched" forKey:@"firstLaunch"];
    }
    
    
    
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                        selector:@selector(updateTrackInfo)
                                                            name:@"com.apple.iTunes.playerInfo"
                                                          object:nil];
    
    
    [self changeState];
    if ([self.musicScrobbler.iTunes isRunning]) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self updateTrackInfo];
            
        });
    }
}

- (void)updateTrackInfo {
    [self changeState];
    if ([self.musicScrobbler.iTunes isRunning]) {
        NSLog(@"uruchamiam itunes?!");
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            int scrobbleTime = [self.musicScrobbler.iTunes.currentTrack duration] / 2;
            
            if (scrobbleTime > 15) {
                [self nowPlaying];
            }
            
            if (self.callTimer) {
                [self.callTimer invalidate];
                self.callTimer = nil;
            }
            
            if (scrobbleTime > 15) {
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
    if (!([self.passwordField.stringValue isEqualTo: @""] || [self.loginField.stringValue isEqualTo: @""])) {
        [self.indicator startAnimation:self];
        self.loginField.hidden = YES;
        self.passwordField.hidden = YES;
        [self.loginButton setTitle:@"Logging in..."];
        [self.loginButton setEnabled:NO];
        [self.musicScrobbler.scrobbler getSessionForUser:self.loginField.stringValue password:self.passwordField.stringValue successHandler:^(NSDictionary *result) {
            
            [self.musicScrobbler logInWithCredentials:result];
            
            [self.loginButton setTitle:[NSString stringWithFormat:@"Log out %@", result[@"name"]]];
            self.loginField.stringValue = @"";
            self.loginField.hidden = YES;
            self.passwordField.stringValue = @"";
            self.passwordField.hidden = YES;
            
            [self.loginButton setEnabled:YES];
            [self changeState];
            [self.loginButton setAction:@selector(logout)];
            [self.indicator stopAnimation:self];
        } failureHandler:^(NSError *error) {
            if (error.code == -1001) {
                [self loginClicked:self];
            }
            else {
                [self.indicator stopAnimation:self];
                self.passwordField.hidden = NO;
                self.loginField.hidden = NO;
                self.passwordField.stringValue = @"";
                [self.loginButton setTitle:@"Log in"];
                [self.loginButton setEnabled:YES];
                NSAlert *alert = [[NSAlert alloc] init];
                alert.alertStyle = NSCriticalAlertStyle;
                alert.informativeText = [error localizedDescription];
                alert.messageText = @"Try again...";
                [alert runModal];
                
            }
        }];
    }
    else {
    }
}



- (void)logout {
    [self.loginButton setTitle:@"Log in"];
    [self.musicScrobbler logOut];
    self.loginField.hidden = NO;
    self.passwordField.hidden = NO;
    [self changeState];
    [self.loginButton setAction:@selector(loginClicked:)];
    
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



-(void)awakeFromNib {
    self.musicScrobbler = [MusicScrobbler sharedScrobbler];
    if (self.musicScrobbler.scrobbler.session) {
        self.loginField.hidden = YES;
        self.passwordField.hidden = YES;
        [self.loginButton setTitle:[NSString stringWithFormat:@"Log out %@", self.musicScrobbler.scrobbler.username]];
        [self.loginButton setAction:@selector(logout)];
    }
    [[self window] setContentSize:[self.accountView frame].size];
    [[[self window] contentView ] addSubview:self.accountView];
    [[[self window] contentView] setWantsLayer:YES];
}

/*----------------------------------------------------------------------------------------------------------*/


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

-(NSView *)viewForTag:(int)tag {
    NSView *view = nil;
    switch (tag) {
        case 1:
            view = self.accountView;
            break;
        default:
            view = self.accountView;
            break;
    }
    return view;
}


-(BOOL)validateToolbarItem:(NSToolbarItem *)item {
    if ([item tag] == self.currentViewTag) return NO;
    else return YES;
}



-(IBAction)switchView:(id)sender {
    int tag = (int)[sender tag];
    NSView *view = [self viewForTag:tag];
    NSView *previousView = [self viewForTag:self.currentViewTag];
    self.currentViewTag = tag;
    
    NSRect newFrame = [self newFrameForNewContentView:view];
    [NSAnimationContext beginGrouping];
    
    if ([[NSApp currentEvent] modifierFlags] & NSShiftKeyMask) {
        [[NSAnimationContext currentContext] setDuration:1.0];
    }
    [[[[self window] contentView] animator] replaceSubview:previousView with:view];
    [[[self window] animator] setFrame:newFrame display:YES];
    
    [NSAnimationContext endGrouping];
}




@end
