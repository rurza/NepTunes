//
//  GetCover.h
//  NepTunes
//
//  Created by rurza on 12/02/16.
//  Copyright © 2016 micropixels. All rights reserved.
//

@import AppKit;
@class Track;

@protocol CoverGetterDelegate <NSObject>

@optional
-(void)trackInfoShouldBeRemoved;
-(void)trackInfoShouldBeDisplayed;
@end

@interface GetCover : NSObject
@property (nonatomic, weak) id<CoverGetterDelegate>delegate;

+(GetCover *)sharedInstance;
-(void)getCoverWithTrack:(Track *)track withCompletionHandler:(void(^)(NSImage *cover))handler;
-(NSImage *)defaultCover;
@end
