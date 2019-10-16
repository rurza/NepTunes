//
//  GVUserDefaults+Settings.h
//  NepTunes
//
//  Created by Adam Różyński on 15/10/2017.
//  Copyright © 2017 micropixels. All rights reserved.
//

#import <GVUserDefaults/GVUserDefaults.h>

@interface GVUserDefaults (Settings)

@property (nonatomic, weak) NSString    *spotifyToken;
@property (nonatomic, weak) NSDate      *spotifyTokenExpirationDate;

@end
