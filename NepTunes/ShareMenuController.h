//
//  ShareMenuControoler.h
//  NepTunes
//
//  Created by rurza on 26/03/16.
//  Copyright © 2016 micropixels. All rights reserved.
//

@import Cocoa;

@interface ShareMenuController : NSObject

@property (weak) IBOutlet NSMenuItem *shareOnTwitterMenuItem;
@property (weak) IBOutlet NSMenuItem *shareOnFacebookMenuItem;
@property (weak) IBOutlet NSMenuItem *trackInfoMenuItem;

- (IBAction)shareOnTwitter:(NSMenuItem *)sender;
- (IBAction)shareOnFacebook:(NSMenuItem *)sender;
- (IBAction)copyTrackLink:(NSMenuItem *)sender;
- (IBAction)copyTrackInfo:(NSMenuItem *)sender;
- (IBAction)searchForLyrics:(NSMenuItem *)sender;


@end
