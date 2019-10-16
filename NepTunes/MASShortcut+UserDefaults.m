//
//  MASShortcut+UserDefaults.m
//  NepTunes
//
//  Created by rurza on 14/03/16.
//  Copyright © 2016 micropixels. All rights reserved.
//

#import "MASShortcut+UserDefaults.h"

@implementation MASShortcut (UserDefaults)

+ (MASShortcut *)shortcutWithData:(NSData *)data
{
    id shortcut = (data ? [NSKeyedUnarchiver unarchiveObjectWithData:data] : nil);
    return shortcut;
}

@end
