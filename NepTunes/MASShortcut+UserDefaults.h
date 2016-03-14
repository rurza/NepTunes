//
//  MASShortcut+UserDefaults.h
//  NepTunes
//
//  Created by rurza on 14/03/16.
//  Copyright © 2016 micropixels. All rights reserved.
//

#import <MASShortcut/MASShortcut.h>

@interface MASShortcut (UserDefaults)
+ (MASShortcut *)shortcutWithData:(NSData *)data;
@end
