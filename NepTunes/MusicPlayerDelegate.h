//
//  MusicPlayerDelegate.h
//  NepTunes
//
//  Created by Adam Różyński on 24/04/16.
//  Copyright © 2016 micropixels. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MusicPlayerDelegate <NSObject>

-(void)trackChanged;
-(void)newActivePlayer;
-(void)bothPlayersAreAvailable;
-(void)onePlayerIsAvailable;
@end