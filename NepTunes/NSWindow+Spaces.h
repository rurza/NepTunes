//
//  NSWindow+Spaces.h
//  NepTunes
//
//  Created by Adam Różyński on 07/09/16.
//  Copyright © 2016 micropixels. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSWindow (Spaces)

-(void)saveWindowStateUsingKeyword:(NSString *)keyword;
-(void)restoreWindowStateUsingKeyword:(NSString *)keyword;

@end
