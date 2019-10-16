//
//  NSWindow+Spaces.m
//  NepTunes
//
//  Created by Adam Różyński on 07/09/16.
//  Copyright © 2016 micropixels. All rights reserved.
//

#import "NSWindow+Spaces.h"

@implementation NSWindow (Spaces)

-(void)saveWindowStateUsingKeyword:(NSString *)keyword
{
    keyword = [NSString stringWithFormat:@"NepTunes %@", keyword];
    NSString *savedFrame = [self stringWithSavedFrame];
    [[NSUserDefaults standardUserDefaults] setObject:savedFrame forKey:keyword];
}

-(void)restoreWindowStateUsingKeyword:(NSString *)keyword
{
    keyword = [NSString stringWithFormat:@"NepTunes %@", keyword];
    
    NSString *savedFrame = [[NSUserDefaults standardUserDefaults] stringForKey:keyword];
    
    if (savedFrame) {
        /* Apple introduced a private defaults key in OS X Mavericks named
         NSWindowAutosaveFrameMovesToActiveDisplay which -setFrameFromString: and no other
         method accesses. The private key is used to determine whether the window should
         favor the active display when restoring the frame. */
        
        [self setFrameFromString:savedFrame];
    }
}



@end
