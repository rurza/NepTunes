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
    [[MASShortcutBinder sharedBinder]
     bindShortcutWithDefaultsKey:kloveSongShortcut
     toAction:^{
        [[MenuController sharedController] loveSong:nil];
     }];
    
    [[MASShortcutBinder sharedBinder]
     bindShortcutWithDefaultsKey:kshowYourProfileShortcut
     toAction:^{
         [[MenuController sharedController] showUserProfile:nil];
     }];
    
    [[MASShortcutBinder sharedBinder]
     bindShortcutWithDefaultsKey:kshowSimilarArtistsShortcut
     toAction:^{
         [[MenuController sharedController] showSimilarArtists:nil];
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


@end
