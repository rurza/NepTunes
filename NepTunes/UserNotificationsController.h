//
//  UserNotificationsController.h
//  NepTunes
//
//  Created by rurza on 01/02/16.
//  Copyright © 2016 micropixels. All rights reserved.
//

@import AppKit;
@class Track;

@interface UserNotificationsController : NSObject 

@property (nonatomic) BOOL displayNotifications;

+(UserNotificationsController *)sharedNotificationsController;

-(void)displayNotificationThatInternetConnectionIsDown;
-(void)displayNotificationThatInternetConnectionIsBack;
-(void)displayNotificationThatAllTracksAreScrobbled;
-(void)displayNotificationThatTrackWasLoved:(Track *)track withArtwork:(NSImage *)artwork;
-(void)displayNotificationThatLoveSongFailedWithError:(NSError *)error;
-(void)displayNotificationThatTrackCanNotBeScrobbledWithError:(NSError *)error;

@end
