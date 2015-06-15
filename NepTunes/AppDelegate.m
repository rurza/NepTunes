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
#import "LastFmCache.h"
#import "DDHotKeyCenter.h"

@interface AppDelegate ()

@property (strong, nonatomic) LastFmCache *lastFmCache;
@property (strong) NSStatusItem *statusItem;
@property (strong) iTunesApplication* iTunes;
@property (strong) NSTimer* callTimer;
@property (strong) NSDistributedNotificationCenter* dnc;
@property (strong) NSUserNotificationCenter *center;


@property (strong) IBOutlet NSMenu *statusMenu;
@property (weak) IBOutlet NSMenuItem *loveSongMenuTitle;
@property (weak) IBOutlet NSMenuItem *profileMenuTitle;
@property (weak) IBOutlet NSMenuItem *similarArtistMenuTtitle;
@property (weak) IBOutlet NSTextField *loginField;
@property (weak) IBOutlet NSSecureTextField *passwordField;
@property (weak) IBOutlet NSButton *loginButton;
@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSView *accountView;
@property (weak) IBOutlet NSProgressIndicator *indicator;




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
    
    
    self.lastFmCache = [[LastFmCache alloc] init];
    [LastFm sharedInstance].apiKey = @"3a26162db61a3c47204396401baf2bf7";
    [LastFm sharedInstance].apiSecret = @"679d4509ae07a46400dd27a05c7e9885";
    [LastFm sharedInstance].session = [[NSUserDefaults standardUserDefaults] stringForKey:SESSION_KEY];
    [LastFm sharedInstance].username = [[NSUserDefaults standardUserDefaults] stringForKey:USERNAME_KEY];
    [LastFm sharedInstance].cacheDelegate = self.lastFmCache;
    
    if ([[NSUserDefaults standardUserDefaults] stringForKey:@"firstLaunch"] == nil) {
        NSLog(@"NepTunes first launch. %@", [[NSUserDefaults standardUserDefaults] stringForKey:@"firstLaunch"]);
        [self openPreferences:self];
        [[NSUserDefaults standardUserDefaults] setObject:@"Launched" forKey:@"firstLaunch"];
    }
    

    self.iTunes = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
    self.dnc = [NSDistributedNotificationCenter defaultCenter];
    
 [self.dnc addObserver:self
            selector:@selector(updateTrackInfo)
                name:@"com.apple.iTunes.playerInfo"
              object:nil];
    [self changeState];
    if ([self.iTunes isRunning]) {
        [self performSelector:@selector(updateTrackInfo) withObject:nil afterDelay:5];
    }
    
}

- (void)updateTrackInfo {
    [self performSelector:@selector(updateTrackInfoFromITunes) withObject:nil afterDelay:5];
    [self changeState];

}


- (void)updateTrackInfoFromITunes {
    if ([self.iTunes isRunning]) {
        //    DEBUG
//        NSLog(@"DEBUG. iTunes is running. Method updateTrackInfoFromITunes called.");
        
        [self nowPlaying];
        self.scrobbleTime = (int)self.iTunes.currentTrack.duration / 2;
        
        if (self.callTimer) {
            [self.callTimer invalidate];
            self.callTimer = nil;
        }
        if (self.scrobbleTime >= 15) {
            self.callTimer = [NSTimer scheduledTimerWithTimeInterval:self.scrobbleTime
                                                              target:self
                                                            selector:@selector(scrobbleTrack)
                                                            userInfo:nil
                                                             repeats:NO];
            
        }
    }
    
}


#pragma mark - Last.fm related

-(void)nowPlaying {
    if ([LastFm sharedInstance].session != nil) {
        [[LastFm sharedInstance] sendNowPlayingTrack:self.iTunes.currentTrack.name byArtist:self.iTunes.currentTrack.artist onAlbum:self.iTunes.currentTrack.album withDuration:(self.iTunes.currentTrack.duration / 2) successHandler:^(NSDictionary *result) {
//            NSLog(@"DEBUG. sendNowPlayingTrack works.");
        } failureHandler:^(NSError *error) {
//            NSLog(@"LastFm error! %@", [error userInfo]);
            if (error.code == -1001) {
//                NSLog(@"Trying again...");
                [self nowPlaying];
            }
        }];
    }
}

- (void)scrobbleTrack {
    if ([self.iTunes isRunning]) {
        if (self.iTunes.playerState == iTunesEPlSPlaying && [LastFm sharedInstance].session != nil) {
    //        DEBUG
//            NSLog(@"DEBUG. Track scrobbled. :)");
            [[LastFm sharedInstance] sendScrobbledTrack:self.iTunes.currentTrack.name byArtist:self.iTunes.currentTrack.artist onAlbum:self.iTunes.currentTrack.album withDuration:self.iTunes.currentTrack.duration atTimestamp:(int)[[NSDate date] timeIntervalSince1970]
            successHandler:^(NSDictionary *result) {
                }
            failureHandler:^(NSError *error) {
//                NSLog(@"LastFm error! %@", [error userInfo]);
                if (error.code == -1001) {
//                    NSLog(@"Trying again...");
                    [self scrobbleTrack];
                }
            }];
        }
        else {
    //        DEBUG
//            NSLog(@"DEBUG. Track not scrobbled. iTunes paused or/and user not logged in.");
        }
    }
}

-(IBAction)loveSong:(id)sender {
//    if (!self.iTunes) {
//        self.iTunes = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
//    }
    if (!self.center) {
        self.center = [NSUserNotificationCenter defaultUserNotificationCenter];
    }
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    [[LastFm sharedInstance] loveTrack:self.iTunes.currentTrack.name artist:self.iTunes.currentTrack.artist successHandler:^(NSDictionary *result)
     {
         [notification setTitle:[NSString stringWithFormat:@"%@", self.iTunes.currentTrack.artist]];
         [notification setInformativeText:[NSString stringWithFormat:@"%@ ❤️ at Last.fm", self.iTunes.currentTrack.name]];
         [notification setDeliveryDate:[NSDate dateWithTimeInterval:1 sinceDate:[NSDate date]]];
         
         [self.center scheduleNotification:notification];
         
     } failureHandler:^(NSError *error) {
//         NSLog(@"LastFm error! %@", [error userInfo]);
         if (error.code == -1001) {
//             NSLog(@"Trying again...");
             [self loveSong:nil];
         }
     }];
    
}

- (IBAction)loginClicked:(id)sender {
    if (!([self.passwordField.stringValue isEqualTo: @""] || [self.loginField.stringValue isEqualTo: @""])) {
        [self.indicator startAnimation:self];
        self.loginField.hidden = YES;
        self.passwordField.hidden = YES;
        [self.loginButton setTitle:@"Logging in..."];
        [self.loginButton setEnabled:NO];
        [[LastFm sharedInstance] getSessionForUser:self.loginField.stringValue password:self.passwordField.stringValue successHandler:^(NSDictionary *result) {
            // Save the session into NSUserDefaults. It is loaded on app start up in AppDelegate.
            [[NSUserDefaults standardUserDefaults] setObject:result[@"key"] forKey:SESSION_KEY];
            [[NSUserDefaults standardUserDefaults] setObject:result[@"name"] forKey:USERNAME_KEY];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            // Also set the session of the LastFm object
            [LastFm sharedInstance].session = result[@"key"];
            [LastFm sharedInstance].username = result[@"name"];
            
            
            // Show the logout button
            [self.loginButton setTitle:[NSString stringWithFormat:@"Log out %@", result[@"name"]]];
            // hide login info
            self.loginField.stringValue = @"";
            self.loginField.hidden = YES;
            self.passwordField.stringValue = @"";
            self.passwordField.hidden = YES;
            
            [self.loginButton setEnabled:YES];
            [self changeState];
            [self.loginButton setAction:@selector(logout)];
            [self.indicator stopAnimation:self];
//            NSLog(@"User logged in!:)");
        } failureHandler:^(NSError *error) {
//            NSLog(@"Failure: %@", [error userInfo]);
            if (error.code == -1001) {
//                NSLog(@"Trying again...");
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
//        NSLog(@"Empty user or password");
    }
}



- (void)logout {
    [self.loginButton setTitle:@"Log in"];
    [[LastFm sharedInstance] logout];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:SESSION_KEY];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:USERNAME_KEY];
    self.loginField.hidden = NO;
    self.passwordField.hidden = NO;
    [self changeState];
    [self.loginButton setAction:@selector(loginClicked:)];
    
}


#pragma mark - Menu Bar Items

- (IBAction)showUserProfile:(id)sender {
    if ([LastFm sharedInstance].session != nil) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.last.fm/user/%@", [LastFm sharedInstance].username]]];
    }
}



-(IBAction)showSimilarArtists:(id)sender {
    NSString *str = self.iTunes.currentTrack.artist;
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


#pragma mark Update menu

-(void)changeState {
    if ([LastFm sharedInstance].session != nil) {
        [self.profileMenuTitle setEnabled:YES];
        self.profileMenuTitle.title = [NSString stringWithFormat:@"%@'s profile...", [LastFm sharedInstance].username];
        if ([self.iTunes isRunning]) {
            if (self.iTunes.currentTrack.name != nil) {
                [self.loveSongMenuTitle setEnabled:YES];
                [self.similarArtistMenuTtitle setEnabled:YES];
                self.similarArtistMenuTtitle.title = [NSString stringWithFormat:@"Similar artists to %@...", self.iTunes.currentTrack.artist];
                self.loveSongMenuTitle.title = [NSString stringWithFormat:@"Love %@ on Last.fm", self.iTunes.currentTrack.name];
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
        if ([self.iTunes isRunning]) {
            if (self.iTunes.currentTrack.name != nil) {
                self.loveSongMenuTitle.title = [NSString stringWithFormat:@"Love on Last.fm (Log in)"];
                self.similarArtistMenuTtitle.title = [NSString stringWithFormat:@"Similar artists to %@...", self.iTunes.currentTrack.artist];
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
    
    [LastFm sharedInstance].session = [[NSUserDefaults standardUserDefaults] stringForKey:SESSION_KEY];
    [LastFm sharedInstance].username = [[NSUserDefaults standardUserDefaults] stringForKey:USERNAME_KEY];
    if ([LastFm sharedInstance].session != nil) {
        self.loginField.hidden = YES;
        self.passwordField.hidden = YES;
        [self.loginButton setTitle:[NSString stringWithFormat:@"Log out %@", [LastFm sharedInstance].username]];
        [self.loginButton setAction:@selector(logout)];
        
    }
    [[self window] setContentSize:[self.accountView frame].size];
    [[[self window] contentView ] addSubview:self.accountView];
    [[[self window] contentView] setWantsLayer:YES];
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
