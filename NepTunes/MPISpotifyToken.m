//
//  MPISpotifyToken.m
//  NepTunes
//
//  Created by Adam Różyński on 14/10/2017.
//  Copyright © 2017 micropixels. All rights reserved.
//

#import "MPISpotifyToken.h"

@implementation MPISpotifyToken

+ (JSONKeyMapper *)keyMapper
{
    return [JSONKeyMapper mapperForSnakeCase];
}

- (void)setExpiresIn:(NSNumber *)expiresIn
{
    _expiresIn = expiresIn;
    self.expirationDate = [NSDate dateWithTimeIntervalSinceNow:expiresIn.floatValue];
}

@end
