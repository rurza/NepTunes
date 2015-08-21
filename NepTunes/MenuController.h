//
//  MenuController.h
//  NepTunes
//
//  Created by rurza on 08/08/15.
//  Copyright (c) 2015 micropixels. All rights reserved.
//
@import Cocoa;

#import <Foundation/Foundation.h>

@interface MenuController : NSObject

@property (weak, nonatomic) IBOutlet NSMenuItem *loveSongMenuTitle;
@property (weak, nonatomic) IBOutlet NSMenuItem *profileMenuTitle;
@property (weak, nonatomic) IBOutlet NSMenuItem *similarArtistMenuTtitle;

-(IBAction)loveSong:(id)sender;
-(IBAction)showUserProfile:(id)sender;
-(IBAction)showSimilarArtists:(id)sender;
-(void)changeState;



@end
