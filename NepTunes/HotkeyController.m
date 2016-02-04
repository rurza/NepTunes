//
//  HotkeyController.m
//  NepTunes
//
//  Created by rurza on 31/07/15.
//  Copyright (c) 2015 micropixels. All rights reserved.
//

#import "HotkeyController.h"
#import "AppDelegate.h"
#import <MASShortcut/Shortcut.h>

static NSString *const kloveSongShortcut = @"loveSongShortcut";
static NSString *const kshowYourProfileShortcut = @"showYourProfileShortcut";
static NSString *const kshowSimilarArtistsShortcut = @"showSimilarArtistsShortcut";

static void *MASObservingContext = &MASObservingContext;

@interface HotkeyController ()

@property (strong) IBOutlet MASShortcutView *loveSongView;
@property (strong) IBOutlet MASShortcutView *showYourProfileView;
@property (strong) IBOutlet MASShortcutView *showSimilarArtistsView;


@end

@implementation HotkeyController

-(void)awakeFromNib
{
    self.loveSongView.associatedUserDefaultsKey = kloveSongShortcut;
    self.showSimilarArtistsView.associatedUserDefaultsKey = kshowSimilarArtistsShortcut;
    self.showYourProfileView.associatedUserDefaultsKey = kshowYourProfileShortcut;
    [self bindShortcutsToAction];
    [self setUpObservers];
}

-(void)bindShortcutsToAction
{
    AppDelegate *delegate = [NSApplication sharedApplication].delegate;
    [[MASShortcutBinder sharedBinder]
     bindShortcutWithDefaultsKey:kloveSongShortcut
     toAction:^{
        [delegate.menuController loveSong:nil];
     }];
    
    [[MASShortcutBinder sharedBinder]
     bindShortcutWithDefaultsKey:kshowYourProfileShortcut
     toAction:^{
         [delegate.menuController showUserProfile:nil];
     }];
    
    [[MASShortcutBinder sharedBinder]
     bindShortcutWithDefaultsKey:kshowSimilarArtistsShortcut
     toAction:^{
         [delegate.menuController showSimilarArtists:nil];
     }];
}

-(void)setUpObservers
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults addObserver:self forKeyPath:kloveSongShortcut
                  options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew
                  context:MASObservingContext];
    
    
    
    [defaults addObserver:self forKeyPath:kshowSimilarArtistsShortcut
                  options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew
                  context:MASObservingContext];
    
    
    
    [defaults addObserver:self forKeyPath:kshowYourProfileShortcut
                   options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew
                   context:MASObservingContext];
    
}

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
    if (context != MASObservingContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
    else {
        AppDelegate *delegate = [NSApplication sharedApplication].delegate;

        if ([keyPath isEqualToString:kloveSongShortcut]) {
            if (self.loveSongView.shortcutValue.modifierFlags) {
                delegate.menuController.loveSongMenuTitle.keyEquivalent = [self.loveSongView.shortcutValue.keyCodeString lowercaseString];
                delegate.menuController.loveSongMenuTitle.keyEquivalentModifierMask = self.loveSongView.shortcutValue.modifierFlags;
            }
            else {
                delegate.menuController.loveSongMenuTitle.keyEquivalent = @"";
            }
        }
        
        else if ([keyPath isEqualToString:kshowSimilarArtistsShortcut]) {
            if (self.showSimilarArtistsView.shortcutValue.modifierFlags) {
                delegate.menuController.similarArtistMenuTtitle.keyEquivalent = [self.showSimilarArtistsView.shortcutValue.keyCodeString lowercaseString];
                delegate.menuController.similarArtistMenuTtitle.keyEquivalentModifierMask = self.showSimilarArtistsView.shortcutValue.modifierFlags;
            }
            else {
                delegate.menuController.similarArtistMenuTtitle.keyEquivalent = @"";
            }
        }
        
        else if ([keyPath isEqualToString:kshowYourProfileShortcut]) {
            if (self.showYourProfileView.shortcutValue.modifierFlags) {
                delegate.menuController.profileMenuTitle.keyEquivalent = [self.showYourProfileView.shortcutValue.keyCodeString lowercaseString];
                delegate.menuController.profileMenuTitle.keyEquivalentModifierMask = self.showYourProfileView.shortcutValue.modifierFlags;
            }
            else {
                delegate.menuController.profileMenuTitle.keyEquivalent = @"";
            }
        }
    }
}


@end
