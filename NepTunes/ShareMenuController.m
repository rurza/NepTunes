//
//  ShareMenuControoler.m
//  NepTunes
//
//  Created by rurza on 26/03/16.
//  Copyright © 2016 micropixels. All rights reserved.
//

@import Social;
#import "ShareMenuController.h"
#import "MusicController.h"
#import "Track.h"
#import "MusicScrobbler.h"
#import "FXReachability.h"
#import "MenuController.h"
#import "ItunesSearch.h"
#import "HUDWindowController.h"
#import "SocialMessage.h"

static NSString *const kHUDXibName = @"HUDWindowController";

@interface ShareMenuController () <NSSharingServiceDelegate>
@property (nonatomic) HUDWindowController *hudWindowController;
@end

@implementation ShareMenuController

-(IBAction)shareOnTwitter:(NSMenuItem *)sender
{
    NSSharingService *service = [NSSharingService sharingServiceNamed:NSSharingServiceNamePostOnTwitter];
    service.delegate = self;
    [self postInfoToService:service];
   
}

-(IBAction)shareOnFacebook:(NSMenuItem *)sender
{
    NSSharingService *service = [NSSharingService sharingServiceNamed:NSSharingServiceNamePostOnFacebook];
    service.delegate = self;
    [self postInfoToService:service];
}

-(IBAction)copyTrackLink:(NSMenuItem *)sender
{
    Track *currentTrack = [MusicScrobbler sharedScrobbler].currentTrack;
    [[MenuController sharedController].iTunesSearch getTrackWithName:currentTrack.trackName artist:currentTrack.artist album:currentTrack.album limitOrNil:nil successHandler:^(NSArray *result) {
        if (result.count) {
            NSDictionary *firstResult = result.firstObject;
            NSPasteboard *clipboard = [NSPasteboard generalPasteboard];
            [clipboard clearContents];
            NSArray *copiedObjects = @[[firstResult objectForKey:@"collectionViewUrl"]];
            [clipboard writeObjects:copiedObjects];
            if (self.hudWindowController.isVisible) {
                [self.hudWindowController updateCurrentHUD];
            } else {
                self.hudWindowController = [[HUDWindowController alloc] initWithWindowNibName:kHUDXibName];
                [self.hudWindowController presentHUD];
            }
            self.hudWindowController.bottomVisualEffectView.hidden = YES;
            self.hudWindowController.centerImageView.image = [NSImage imageNamed:@"copied link"];
            self.hudWindowController.centerImageView.image.template = YES;
            self.hudWindowController.bottomLabel.hidden = NO;
            self.hudWindowController.bottomLabel.stringValue = NSLocalizedString(@"Link copied", nil);
        } else {
            [self displayInfoThatLinkCannotBeCopied];
        }
    } failureHandler:^(NSError *error) {
        [self displayInfoThatLinkCannotBeCopied];
    }];
}

-(void)displayInfoThatLinkCannotBeCopied
{
    if (self.hudWindowController.isVisible) {
        [self.hudWindowController updateCurrentHUD];
    } else {
        self.hudWindowController = [[HUDWindowController alloc] initWithWindowNibName:kHUDXibName];
        [self.hudWindowController presentHUD];
    }
    self.hudWindowController.bottomVisualEffectView.hidden = YES;
    self.hudWindowController.centerImageView.image = [NSImage imageNamed:@"error"];
    self.hudWindowController.centerImageView.image.template = YES;
    self.hudWindowController.bottomLabel.hidden = NO;
    self.hudWindowController.bottomLabel.stringValue = NSLocalizedString(@"Can't obtain a link", nil);
}


-(IBAction)copyTrackInfo:(NSMenuItem *)sender
{
    Track *currentTrack = [MusicScrobbler sharedScrobbler].currentTrack;
    if (currentTrack.trackName) {
        NSPasteboard *clipboard = [NSPasteboard generalPasteboard];
        [clipboard clearContents];
        NSArray *copiedObjects = @[[NSString stringWithFormat:@"%@ - %@", currentTrack.artist, currentTrack.trackName]];
        [clipboard writeObjects:copiedObjects];
        if (self.hudWindowController.isVisible) {
            [self.hudWindowController updateCurrentHUD];
        } else {
            self.hudWindowController = [[HUDWindowController alloc] initWithWindowNibName:kHUDXibName];
            [self.hudWindowController presentHUD];
        }
        self.hudWindowController.bottomVisualEffectView.hidden = YES;
        self.hudWindowController.centerImageView.image = [NSImage imageNamed:@"copied"];
        self.hudWindowController.centerImageView.image.template = YES;
        self.hudWindowController.bottomLabel.hidden = NO;
        self.hudWindowController.bottomLabel.stringValue = NSLocalizedString(@"Info copied", nil);
    }
}

- (IBAction)searchForLyrics:(NSMenuItem *)sender
{
    Track *currentTrack = [MusicScrobbler sharedScrobbler].currentTrack;
    NSString *urlString = [NSString stringWithFormat:@"%@+%@+lyrics", currentTrack.artist, currentTrack.trackName];
    urlString = [urlString stringByReplacingOccurrencesOfString:@"/" withString:@"%2F"];
    urlString = [urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    urlString = [NSString stringWithFormat:@"https://www.google.com/search?rls=en&q=%@", urlString];
    NSURL *url = [NSURL URLWithString:urlString];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

-(void)postInfoToService:(NSSharingService *)service
{
    [SocialMessage messageForCurrentTrackWithCompletionHandler:^(NSString *message) {
        [service performWithItems:@[message]];
    }];
}

-(BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    Track *currentTrack = [MusicScrobbler sharedScrobbler].currentTrack;
    NSSharingService *service;
    NSString *menuTitle = menuItem.title;
    
    if ([menuTitle localizedCaseInsensitiveContainsString:@"Tweet"]) {
        service = [NSSharingService sharingServiceNamed:NSSharingServiceNamePostOnTwitter];
    } else if ([menuTitle localizedCaseInsensitiveContainsString:@"Facebook"]) {
        service = [NSSharingService sharingServiceNamed:NSSharingServiceNamePostOnFacebook];
    }
    
    if (service && [service canPerformWithItems:nil] && currentTrack.trackName) {
        return YES;
    } else if ([menuTitle localizedCaseInsensitiveContainsString:@"info"] && currentTrack.trackName) {
        return YES;
    } else if (([menuTitle localizedCaseInsensitiveContainsString:@"link"] ||  [menuTitle localizedCaseInsensitiveContainsString:@"lyrics"]) && currentTrack.trackName && [FXReachability isReachable]) {
        return YES;
    }
    return NO;
}

@end