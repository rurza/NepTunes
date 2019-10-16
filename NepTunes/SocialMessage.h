//
//  SocialMessage.h
//  NepTunes
//
//  Created by rurza on 27/03/16.
//  Copyright © 2016 micropixels. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SocialMessage : NSObject

+(void)messageForCurrentTrackWithCompletionHandler:(void(^)(NSString *message))handler;
+(void)messageForLovedTrackWithCompletionHandler:(void(^)(NSString *message))handler;

@end