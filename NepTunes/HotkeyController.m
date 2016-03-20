//
//  HotkeyController.m
//  NepTunes
//
//  Created by rurza on 31/07/15.
//  Copyright (c) 2015 micropixels. All rights reserved.
//

#import "HotkeyController.h"
#import "PreferencesController.h"
#import <MASShortcut/Shortcut.h>
#import "HUDWindowController.h"
#import "MASShortcut+UserDefaults.h"
#import "MusicController.h"

static NSString *const kloveSongShortcut = @"loveSongShortcut";
static NSString *const kshowYourProfileShortcut = @"showYourProfileShortcut";
static NSString *const kshowSimilarArtistsShortcut = @"showSimilarArtistsShortcut";

static NSString *const kIncreaseVolumeShortcut = @"increaseVolumeShortcut";
static NSString *const kDecreaseVolumeShortcut = @"decreaseVolumeShortcut";
static NSString *const kMuteVolumeShortcut = @"muteVolumeShortcut";

static NSString *const kHUDXibName = @"HUDWindowController";


static void *MASObservingContext = &MASObservingContext;

@interface HotkeyController ()

@property (strong) IBOutlet MASShortcutView *loveSongView;
@property (strong) IBOutlet MASShortcutView *showYourProfileView;
@property (strong) IBOutlet MASShortcutView *showSimilarArtistsView;
@property (weak, nonatomic) IBOutlet MASShortcutView *increaseVolumeView;
@property (weak, nonatomic) IBOutlet MASShortcutView *decreaseVolumeView;
@property (weak, nonatomic) IBOutlet MASShortcutView *muteVolumeView;
@property (nonatomic) NSInteger oldVolume;


@property (nonatomic) HUDWindowController *hudWindowController;

@end

@implementation HotkeyController

-(void)awakeFromNib
{
    self.loveSongView.associatedUserDefaultsKey = kloveSongShortcut;
    self.showSimilarArtistsView.associatedUserDefaultsKey = kshowSimilarArtistsShortcut;
    self.showYourProfileView.associatedUserDefaultsKey = kshowYourProfileShortcut;
    
    self.increaseVolumeView.associatedUserDefaultsKey = kIncreaseVolumeShortcut;
    self.decreaseVolumeView.associatedUserDefaultsKey = kDecreaseVolumeShortcut;
    self.muteVolumeView.associatedUserDefaultsKey = kMuteVolumeShortcut;
    
    [self bindShortcutsToAction];
    [self setUpObservers];
}

-(instancetype)init
{
    self = [super init];
    if (self) {
        [self updateMenu];
        [self bindShortcutsToAction];
    }
    return self;
}


-(void)bindShortcutsToAction
{
    [[MASShortcutBinder sharedBinder]
     bindShortcutWithDefaultsKey:kloveSongShortcut
     toAction:^{
        [[MenuController sharedController] loveSong:nil];
         if (self.hudWindowController.isVisible) {
             [self.hudWindowController updateCurrentHUD];
             self.hudWindowController.bottomImageView.image = nil;
             self.hudWindowController.centerImageView.image = nil;
             self.hudWindowController.bottomVisualEffectView.hidden = YES;
         } else {
             self.hudWindowController = [[HUDWindowController alloc] initWithWindowNibName:kHUDXibName];
             [self.hudWindowController presentHUD];
             self.hudWindowController.bottomVisualEffectView.hidden = YES;
         }
         self.hudWindowController.visibilityTime = 3;
         self.hudWindowController.bottomVisualEffectView.hidden = YES;
         self.hudWindowController.centerImageView.image = [NSImage imageNamed:@"fullheart"];
         self.hudWindowController.centerImageView.image.template = YES;
         self.hudWindowController.bottomLabel.hidden = NO;
         self.hudWindowController.bottomLabel.stringValue = NSLocalizedString(@"Love", nil);
     }];
    //Profile
    [[MASShortcutBinder sharedBinder]
     bindShortcutWithDefaultsKey:kshowYourProfileShortcut
     toAction:^{
         [[MenuController sharedController] showUserProfile:nil];
         if (self.hudWindowController.isVisible) {
             [self.hudWindowController updateCurrentHUD];
         } else {
             self.hudWindowController = [[HUDWindowController alloc] initWithWindowNibName:kHUDXibName];
             [self.hudWindowController presentHUD];
         }
         self.hudWindowController.bottomVisualEffectView.hidden = YES;
         self.hudWindowController.visibilityTime = 3;
         self.hudWindowController.centerImageView.image = [NSImage imageNamed:@"profile"];
         self.hudWindowController.centerImageView.image.template = YES;
         self.hudWindowController.bottomLabel.hidden = NO;
         self.hudWindowController.bottomLabel.stringValue = NSLocalizedString(@"Profile", nil);
     }];
    
    //similar artists
    [[MASShortcutBinder sharedBinder]
     bindShortcutWithDefaultsKey:kshowSimilarArtistsShortcut
     toAction:^{
         [[MenuController sharedController] showSimilarArtists:nil];
         if (self.hudWindowController.isVisible) {
             [self.hudWindowController updateCurrentHUD];
         } else {
             self.hudWindowController = [[HUDWindowController alloc] initWithWindowNibName:kHUDXibName];
             [self.hudWindowController presentHUD];
         }
         self.hudWindowController.bottomVisualEffectView.hidden = YES;
         self.hudWindowController.visibilityTime = 3;
         self.hudWindowController.centerImageView.image = [NSImage imageNamed:@"similar"];
         self.hudWindowController.centerImageView.image.template = YES;
         self.hudWindowController.bottomLabel.hidden = NO;
         self.hudWindowController.bottomLabel.stringValue = NSLocalizedString(@"Similar Artists", nil);
     }];
    
    //increase
    [[MASShortcutBinder sharedBinder]
     bindShortcutWithDefaultsKey:kIncreaseVolumeShortcut
     toAction:^{
         
         if (self.hudWindowController.isVisible) {
             [self.hudWindowController updateCurrentHUD];
             self.hudWindowController.bottomVisualEffectView.hidden = NO;
         } else {
             self.hudWindowController = [[HUDWindowController alloc] initWithWindowNibName:kHUDXibName];
             [self.hudWindowController presentHUD];
         }
         self.hudWindowController.visibilityTime = 1;

         MusicController *musicController = [MusicController sharedController];
         NSInteger volume = musicController.iTunes.soundVolume;
         if (volume >= 90 && volume <= 100) {
             self.hudWindowController.bottomImageView.image = [NSImage imageNamed:@"volume-10"];
             self.hudWindowController.centerImageView.image = [NSImage imageNamed:@"volume-max"];
             musicController.iTunes.soundVolume = 100;
         } else if (volume >= 80) {
             self.hudWindowController.bottomImageView.image = [NSImage imageNamed:@"volume-9"];
             self.hudWindowController.centerImageView.image = [NSImage imageNamed:@"volume-max"];
             musicController.iTunes.soundVolume = 90;
         } else if (volume >= 70) {
             self.hudWindowController.bottomImageView.image = [NSImage imageNamed:@"volume-8"];
             self.hudWindowController.centerImageView.image = [NSImage imageNamed:@"volume-max"];
             musicController.iTunes.soundVolume = 80;
         } else if (volume >= 60) {
             self.hudWindowController.bottomImageView.image = [NSImage imageNamed:@"volume-7"];
             self.hudWindowController.centerImageView.image = [NSImage imageNamed:@"volume-max"];
             musicController.iTunes.soundVolume = 70;
         } else if (volume >= 50) {
             self.hudWindowController.bottomImageView.image = [NSImage imageNamed:@"volume-6"];
             self.hudWindowController.centerImageView.image = [NSImage imageNamed:@"volume-mid"];
             musicController.iTunes.soundVolume = 60;
         } else if (volume >= 40) {
             self.hudWindowController.bottomImageView.image = [NSImage imageNamed:@"volume-5"];
             self.hudWindowController.centerImageView.image = [NSImage imageNamed:@"volume-mid"];
             musicController.iTunes.soundVolume = 50;
         } else if (volume >= 30) {
             self.hudWindowController.bottomImageView.image = [NSImage imageNamed:@"volume-4"];
             self.hudWindowController.centerImageView.image = [NSImage imageNamed:@"volume-mid"];
             musicController.iTunes.soundVolume = 40;
         } else if (volume >= 20) {
             self.hudWindowController.bottomImageView.image = [NSImage imageNamed:@"volume-3"];
             self.hudWindowController.centerImageView.image = [NSImage imageNamed:@"volume-min"];
             musicController.iTunes.soundVolume = 30;
         } else if (volume >= 10) {
             self.hudWindowController.bottomImageView.image = [NSImage imageNamed:@"volume-2"];
             self.hudWindowController.centerImageView.image = [NSImage imageNamed:@"volume-min"];
             musicController.iTunes.soundVolume = 20;
         } else if (volume > 0) {
             self.hudWindowController.bottomImageView.image = [NSImage imageNamed:@"volume-1"];
             self.hudWindowController.centerImageView.image = [NSImage imageNamed:@"volume-min"];
             musicController.iTunes.soundVolume = 10;
         } else {
             self.hudWindowController.bottomImageView.image = [NSImage imageNamed:@"volume-1"];
             self.hudWindowController.centerImageView.image = [NSImage imageNamed:@"volume-min"];
             musicController.iTunes.soundVolume = 10;
         }
         self.hudWindowController.bottomImageView.image.template = YES;
         self.hudWindowController.centerImageView.image.template = YES;
     }];
    
    //Decrease
    [[MASShortcutBinder sharedBinder]
     bindShortcutWithDefaultsKey:kDecreaseVolumeShortcut
     toAction:^{
         if (self.hudWindowController.isVisible) {
             [self.hudWindowController updateCurrentHUD];
             self.hudWindowController.bottomVisualEffectView.hidden = NO;
         } else {
             self.hudWindowController = [[HUDWindowController alloc] initWithWindowNibName:kHUDXibName];
             [self.hudWindowController presentHUD];
         }
         self.hudWindowController.visibilityTime = 1;
         MusicController *musicController = [MusicController sharedController];
         NSInteger volume = musicController.iTunes.soundVolume;
         if (volume > 90 && volume <= 100) {
             self.hudWindowController.bottomImageView.image = [NSImage imageNamed:@"volume-9"];
             self.hudWindowController.centerImageView.image = [NSImage imageNamed:@"volume-max"];
             musicController.iTunes.soundVolume = 90;
         } else if (volume > 80) {
             self.hudWindowController.bottomImageView.image = [NSImage imageNamed:@"volume-8"];
             self.hudWindowController.centerImageView.image = [NSImage imageNamed:@"volume-max"];
             musicController.iTunes.soundVolume = 80;
         } else if (volume > 70) {
             self.hudWindowController.bottomImageView.image = [NSImage imageNamed:@"volume-7"];
             self.hudWindowController.centerImageView.image = [NSImage imageNamed:@"volume-max"];
             musicController.iTunes.soundVolume = 70;
         } else if (volume > 60) {
             self.hudWindowController.bottomImageView.image = [NSImage imageNamed:@"volume-6"];
             self.hudWindowController.centerImageView.image = [NSImage imageNamed:@"volume-mid"];
             musicController.iTunes.soundVolume = 60;
         } else if (volume > 50) {
             self.hudWindowController.bottomImageView.image = [NSImage imageNamed:@"volume-5"];
             self.hudWindowController.centerImageView.image = [NSImage imageNamed:@"volume-mid"];
             musicController.iTunes.soundVolume = 50;
         } else if (volume > 40) {
             self.hudWindowController.bottomImageView.image = [NSImage imageNamed:@"volume-4"];
             self.hudWindowController.centerImageView.image = [NSImage imageNamed:@"volume-mid"];
             musicController.iTunes.soundVolume = 40;
         } else if (volume > 30) {
             self.hudWindowController.bottomImageView.image = [NSImage imageNamed:@"volume-3"];
             self.hudWindowController.centerImageView.image = [NSImage imageNamed:@"volume-min"];
             musicController.iTunes.soundVolume = 30;
         } else if (volume > 20) {
             self.hudWindowController.bottomImageView.image = [NSImage imageNamed:@"volume-2"];
             self.hudWindowController.centerImageView.image = [NSImage imageNamed:@"volume-min"];
             musicController.iTunes.soundVolume = 20;
         } else if (volume > 10) {
             self.hudWindowController.bottomImageView.image = [NSImage imageNamed:@"volume-1"];
             self.hudWindowController.centerImageView.image = [NSImage imageNamed:@"volume-min"];
             musicController.iTunes.soundVolume = 10;
         } else if (volume > 0) {
             self.hudWindowController.bottomImageView.image = [NSImage imageNamed:@"volume-bar-mute"];
             self.hudWindowController.centerImageView.image = [NSImage imageNamed:@"volume-mute"];
             musicController.iTunes.soundVolume = 0;
         } else {
             self.hudWindowController.bottomImageView.image = [NSImage imageNamed:@"volume-bar-mute"];
             self.hudWindowController.centerImageView.image = [NSImage imageNamed:@"volume-mute"];
             musicController.iTunes.soundVolume = 0;
         }
         self.hudWindowController.bottomImageView.image.template = YES;
         self.hudWindowController.centerImageView.image.template = YES;
     }];
    
    //Mute
    [[MASShortcutBinder sharedBinder]
     bindShortcutWithDefaultsKey:kMuteVolumeShortcut
     toAction:^{
         if (self.hudWindowController.isVisible) {
             [self.hudWindowController updateCurrentHUD];
             self.hudWindowController.bottomVisualEffectView.hidden = NO;
         } else {
             self.hudWindowController = [[HUDWindowController alloc] initWithWindowNibName:kHUDXibName];
             [self.hudWindowController presentHUD];
         }
         self.hudWindowController.visibilityTime = 1;
         MusicController *musicController = [MusicController sharedController];
         NSInteger volume = musicController.iTunes.soundVolume;
         if (volume > 0) {
             self.oldVolume = volume;
             self.hudWindowController.bottomImageView.image = [NSImage imageNamed:@"volume-bar-mute"];
             self.hudWindowController.centerImageView.image = [NSImage imageNamed:@"volume-mute"];
             musicController.iTunes.soundVolume = 0;
         } else {
             NSInteger volume = self.oldVolume;
             if (volume >= 90 && volume <= 100) {
                 self.hudWindowController.bottomImageView.image = [NSImage imageNamed:@"volume-10"];
                 self.hudWindowController.centerImageView.image = [NSImage imageNamed:@"volume-max"];
             } else if (volume >= 80) {
                 self.hudWindowController.bottomImageView.image = [NSImage imageNamed:@"volume-9"];
                 self.hudWindowController.centerImageView.image = [NSImage imageNamed:@"volume-max"];
             } else if (volume >= 70) {
                 self.hudWindowController.bottomImageView.image = [NSImage imageNamed:@"volume-8"];
                 self.hudWindowController.centerImageView.image = [NSImage imageNamed:@"volume-max"];
             } else if (volume >= 60) {
                 self.hudWindowController.bottomImageView.image = [NSImage imageNamed:@"volume-7"];
                 self.hudWindowController.centerImageView.image = [NSImage imageNamed:@"volume-max"];
             } else if (volume >= 50) {
                 self.hudWindowController.bottomImageView.image = [NSImage imageNamed:@"volume-6"];
                 self.hudWindowController.centerImageView.image = [NSImage imageNamed:@"volume-mid"];
             } else if (volume >= 40) {
                 self.hudWindowController.bottomImageView.image = [NSImage imageNamed:@"volume-5"];
                 self.hudWindowController.centerImageView.image = [NSImage imageNamed:@"volume-mid"];
             } else if (volume >= 30) {
                 self.hudWindowController.bottomImageView.image = [NSImage imageNamed:@"volume-4"];
                 self.hudWindowController.centerImageView.image = [NSImage imageNamed:@"volume-mid"];
             } else if (volume >= 20) {
                 self.hudWindowController.bottomImageView.image = [NSImage imageNamed:@"volume-3"];
                 self.hudWindowController.centerImageView.image = [NSImage imageNamed:@"volume-min"];
             } else if (volume >= 10) {
                 self.hudWindowController.bottomImageView.image = [NSImage imageNamed:@"volume-2"];
                 self.hudWindowController.centerImageView.image = [NSImage imageNamed:@"volume-min"];
             } else if (volume > 0) {
                 self.hudWindowController.bottomImageView.image = [NSImage imageNamed:@"volume-1"];
                 self.hudWindowController.centerImageView.image = [NSImage imageNamed:@"volume-min"];
             } else {
                 self.hudWindowController.bottomImageView.image = [NSImage imageNamed:@"volume-1"];
                 self.hudWindowController.centerImageView.image = [NSImage imageNamed:@"volume-min"];
             }
             musicController.iTunes.soundVolume = self.oldVolume;
         }
 
         self.hudWindowController.bottomImageView.image.template = YES;
         self.hudWindowController.centerImageView.image.template = YES;
     }];

}

-(void)updateMenu
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    MASShortcut *loveTrackShortcut = [MASShortcut shortcutWithData:[defaults objectForKey:kloveSongShortcut]];
    MASShortcut *showSimilarArtistsShortcut = [MASShortcut shortcutWithData:[defaults objectForKey:kshowSimilarArtistsShortcut]];
    MASShortcut *userProfileShortcut = [MASShortcut shortcutWithData:[defaults objectForKey:kshowYourProfileShortcut]];
    
    
    if (userProfileShortcut.modifierFlags) {
        [MenuController sharedController].profileMenuTitle.keyEquivalent = [userProfileShortcut.keyCodeString lowercaseString];
        [MenuController sharedController].profileMenuTitle.keyEquivalentModifierMask = userProfileShortcut.modifierFlags;
    }
    else {
        [MenuController sharedController].profileMenuTitle.keyEquivalent = @"";
    }
    
    if (loveTrackShortcut.modifierFlags) {
        [MenuController sharedController].loveSongMenuTitle.keyEquivalent = [loveTrackShortcut.keyCodeString lowercaseString];
        [MenuController sharedController].loveSongMenuTitle.keyEquivalentModifierMask = loveTrackShortcut.modifierFlags;
    }
    else {
        [MenuController sharedController].loveSongMenuTitle.keyEquivalent = @"";
    }
    
    if (showSimilarArtistsShortcut.modifierFlags) {
        [MenuController sharedController].similarArtistMenuTtitle.keyEquivalent = [showSimilarArtistsShortcut.keyCodeString lowercaseString];
        [MenuController sharedController].similarArtistMenuTtitle.keyEquivalentModifierMask = showSimilarArtistsShortcut.modifierFlags;
    }
    else {
        [MenuController sharedController].similarArtistMenuTtitle.keyEquivalent = @"";
    }
}

-(void)setUpObservers
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    //Last.fm
    [defaults addObserver:self forKeyPath:kloveSongShortcut
                  options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew
                  context:MASObservingContext];
    [defaults addObserver:self forKeyPath:kshowSimilarArtistsShortcut
                  options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew
                  context:MASObservingContext];
    [defaults addObserver:self forKeyPath:kshowYourProfileShortcut
                  options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew
                  context:MASObservingContext];
    
    //Volume
    [defaults addObserver:self forKeyPath:kIncreaseVolumeShortcut
                  options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew
                  context:MASObservingContext];
    [defaults addObserver:self forKeyPath:kDecreaseVolumeShortcut
                  options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew
                  context:MASObservingContext];
    [defaults addObserver:self forKeyPath:kMuteVolumeShortcut
                  options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew
                  context:MASObservingContext];
}

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
    if ([change objectForKey:NSKeyValueChangeNewKey]) {
        
    }
    if (context != MASObservingContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
    else {
        
        if ([keyPath isEqualToString:kloveSongShortcut]) {
            if (self.loveSongView.shortcutValue.modifierFlags) {
                [MenuController sharedController].loveSongMenuTitle.keyEquivalent = [self.loveSongView.shortcutValue.keyCodeString lowercaseString];
                [MenuController sharedController].loveSongMenuTitle.keyEquivalentModifierMask = self.loveSongView.shortcutValue.modifierFlags;
            }
            else {
                [MenuController sharedController].loveSongMenuTitle.keyEquivalent = @"";
            }
        }
        
        else if ([keyPath isEqualToString:kshowSimilarArtistsShortcut]) {
            if (self.showSimilarArtistsView.shortcutValue.modifierFlags) {
                [MenuController sharedController].similarArtistMenuTtitle.keyEquivalent = [self.showSimilarArtistsView.shortcutValue.keyCodeString lowercaseString];
                [MenuController sharedController].similarArtistMenuTtitle.keyEquivalentModifierMask = self.showSimilarArtistsView.shortcutValue.modifierFlags;
            }
            else {
                [MenuController sharedController].similarArtistMenuTtitle.keyEquivalent = @"";
            }
        }
        
        else if ([keyPath isEqualToString:kshowYourProfileShortcut]) {
            if (self.showYourProfileView.shortcutValue.modifierFlags) {
                [MenuController sharedController].profileMenuTitle.keyEquivalent = [self.showYourProfileView.shortcutValue.keyCodeString lowercaseString];
                [MenuController sharedController].profileMenuTitle.keyEquivalentModifierMask = self.showYourProfileView.shortcutValue.modifierFlags;
            }
            else {
                [MenuController sharedController].profileMenuTitle.keyEquivalent = @"";
            }
        }
    }
}

-(void)dealloc
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    @try {
        [defaults removeObserver:self forKeyPath:kloveSongShortcut];
        [defaults removeObserver:self forKeyPath:kshowSimilarArtistsShortcut];
        [defaults removeObserver:self forKeyPath:kshowYourProfileShortcut];
        [defaults removeObserver:self forKeyPath:kIncreaseVolumeShortcut];
        [defaults removeObserver:self forKeyPath:kDecreaseVolumeShortcut];
        [defaults removeObserver:self forKeyPath:kMuteVolumeShortcut];
    }
    @catch (NSException * __unused exception) {}
}

@end