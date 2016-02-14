//
//  CoverWindowController.h
//  NepTunes
//
//  Created by rurza on 11/02/16.
//  Copyright © 2016 micropixels. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class Track;

@interface CoverWindowController : NSWindowController

-(void)updateCoverWithTrack:(Track *)track andUserInfo:(NSDictionary *)userInfo;
-(void)fadeCover:(BOOL)direction;

@end
