//
//  UserNotificationsController.m
//  NepTunes
//
//  Created by rurza on 01/02/16.
//  Copyright © 2016 micropixels. All rights reserved.
//

#import "UserNotificationsController.h"
#import "SettingsController.h"
#import "LastFm.h"
#import "AppDelegate.h"
#import "MenuController.h"
#import "MusicScrobbler.h"
#import "Song.h"

@interface UserNotificationsController () <NSUserNotificationCenterDelegate>
@property (nonatomic) BOOL doISentANotificationThatLastFmIsDown;
@end
@implementation UserNotificationsController

+(UserNotificationsController *)sharedNotificationsController
{
    static UserNotificationsController *notificationsController = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        notificationsController = [[UserNotificationsController alloc] init];
        [NSUserNotificationCenter defaultUserNotificationCenter].delegate = notificationsController;
    });
    return notificationsController;
}

#pragma mark - That can be hidden
-(void)displayNotificationThatInternetConnectionIsDown
{
    if (self.displayNotifications) {
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        notification.title = NSLocalizedString(@"Yikes!", nil);
        notification.subtitle = NSLocalizedString(@"Looks like there is no connection to the Internet.", nil);
        notification.informativeText = NSLocalizedString(@"Don't worry, I'm going to scrobble anyway.", nil);
        [notification setDeliveryDate:[NSDate dateWithTimeInterval:0 sinceDate:[NSDate date]]];
        [[NSUserNotificationCenter defaultUserNotificationCenter] scheduleNotification:notification];
    }
}

-(void)displayNotificationThatInternetConnectionIsBack
{
    if (self.displayNotifications) {
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        notification.title = NSLocalizedString(@"Yay! 😁", nil);
        notification.subtitle = NSLocalizedString(@"Your Mac is online now.", nil);
        notification.informativeText = NSLocalizedString(@"Now I'm going to scrobble tracks played offline.", nil);
        [notification setDeliveryDate:[NSDate dateWithTimeInterval:0 sinceDate:[NSDate date]]];
        [[NSUserNotificationCenter defaultUserNotificationCenter] scheduleNotification:notification];
    }
}

-(void)displayNotificationThatAllTracksAreScrobbled
{
    if (self.displayNotifications) {
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        notification.title = NSLocalizedString(@"Woohoo!", nil);
        notification.subtitle = NSLocalizedString(@"All tracks listened offline are scrobbled!", nil);
        [notification setDeliveryDate:[NSDate dateWithTimeInterval:5 sinceDate:[NSDate date]]];
        [[NSUserNotificationCenter defaultUserNotificationCenter] scheduleNotification:notification];
    }
}

-(void)displayNotificationThatTrackWasLoved:(Song *)track;
{
    if (self.displayNotifications) {
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        [notification setTitle:[NSString stringWithFormat:@"%@", track.artist]];
        [notification setInformativeText:[NSString stringWithFormat:@"%@ ❤️ at Last.fm", track.trackName]];
        [notification setDeliveryDate:[NSDate dateWithTimeInterval:0 sinceDate:[NSDate date]]];
        
        [[NSUserNotificationCenter defaultUserNotificationCenter] scheduleNotification:notification];
    }
}

#pragma mark - That we always want to display
-(void)displayNotificationThatLoveSongFailedWithError:(NSError *)error
{
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title = NSLocalizedString(@"Houston, we got a problem!", nil);
    if (error.code == kLastFmErrorCodeInvalidSession) {
        notification.informativeText = NSLocalizedString(@"There are some issues with your Last.fm session. Open preferences and log in again.", nil);
        notification.soundName = NSUserNotificationDefaultSoundName;
        notification.hasActionButton = YES;
        notification.actionButtonTitle = NSLocalizedString(@"Open", nil);
        [notification setValue:@YES forKey:@"_showsButtons"];
        notification.userInfo = @{@"logout":@YES};
    } else {
        notification.informativeText = [NSString stringWithFormat:NSLocalizedString(@"%@", @"displayNotificationThatLoveSongFailedWithError"), error.localizedDescription];
    }
    
    [notification setDeliveryDate:[NSDate dateWithTimeInterval:1 sinceDate:[NSDate date]]];
    [[NSUserNotificationCenter defaultUserNotificationCenter] scheduleNotification:notification];
}

-(void)displayNotificationThatTrackCanNotBeScrobbledWithError:(NSError *)error
{
    /*
     enum LastFmServiceErrorCodes {
     kLastFmErrorCodeInvalidService = 2,
     kLastFmErrorCodeInvalidMethod = 3,
     kLastFmErrorCodeAuthenticationFailed = 4,
     kLastFmErrorCodeInvalidFormat = 5,
     kLastFmErrorCodeInvalidParameters = 6,
     kLastFmErrorCodeInvalidResource = 7,
     kLastFmErrorCodeOperationFailed = 8,
     kLastFmErrorCodeInvalidSession = 9,
     kLastFmErrorCodeInvalidAPIKey = 10,
     kLastFmErrorCodeServiceOffline = 11,
     kLastFmErrorCodeSubscribersOnly = 12,
     kLastFmErrorCodeInvalidAPISignature = 13,
     kLastFmerrorCodeServiceError = 16
     };
     */
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title = NSLocalizedString(@"Houston, we got a problem!", nil);
    if (error.code == kLastFmErrorCodeInvalidSession) {
        notification.informativeText = NSLocalizedString(@"There are some issues with your Last.fm session. Open preferences and log in again.", nil);
        notification.soundName = NSUserNotificationDefaultSoundName;
        notification.hasActionButton = YES;
        notification.actionButtonTitle = NSLocalizedString(@"Open", nil);
        [notification setValue:@YES forKey:@"_showsButtons"];
        notification.userInfo = @{@"logout":@YES};
    } else if (error.code == kLastFmErrorCodeServiceOffline && !self.doISentANotificationThatLastFmIsDown) {
        if (!self.displayNotifications) {
            return;
        }
        self.doISentANotificationThatLastFmIsDown = YES;
        notification.informativeText = NSLocalizedString(@"It looks like Last.fm is offline. Don't worry, I'm going to scrobble all tracks later.", nil);
    } else {
        if (!self.displayNotifications) {
            return;
        }
        notification.informativeText = error.localizedDescription;
    }
    [notification setDeliveryDate:[NSDate dateWithTimeInterval:0 sinceDate:[NSDate date]]];
    [[NSUserNotificationCenter defaultUserNotificationCenter] scheduleNotification:notification];
}

#pragma mark - Getters
-(BOOL)displayNotifications
{
    return ![SettingsController sharedSettings].hideNotifications;
}

#pragma mark - User Notifications
- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification
{
    return YES;
}

-(void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification
{
    if ([[notification.userInfo objectForKey:@"logout"] boolValue]) {
        [((AppDelegate *)[NSApplication sharedApplication].delegate).menuController openPreferences:nil];
    }
}

-(void)userNotificationCenter:(NSUserNotificationCenter *)center didDeliverNotification:(NSUserNotification *)notification
{
    if ([[notification.userInfo objectForKey:@"logout"] boolValue]) {
        [(AppDelegate *)[NSApplication sharedApplication].delegate logOut:nil];
        [SettingsController sharedSettings].openPreferencesWhenThereIsNoUser = YES;
    }
}

@end
