//
//  MPISpotifyRequestsFactory.h
//  NepTunes
//
//  Created by Adam Różyński on 11/10/2017.
//  Copyright © 2017 micropixels. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MPISpotifyRequestsFactory : NSObject

+ (NSURLRequest * _Nonnull)requestForAuthorizeWithClientID:(NSString * _Nonnull)clientId
                                           andClientSecret:(NSString * _Nonnull)clientSecret;

+ (NSURLRequest * _Nonnull)requestWithSearchForArtistWithName:(NSString * _Nonnull)artistName
                                                        limit:(NSNumber * _Nullable)limit
                                                        token:(NSString * _Nonnull)token;

+ (NSURLRequest * _Nonnull)requestForGetTrackWithIds:(NSArray<NSString *> * _Nonnull)ids
                                               token:(NSString * _Nonnull)token;

+ (NSURLRequest * _Nonnull)requestWithGetTrackWithhName:(NSString * _Nonnull)trackName
                                                 artist:(NSString * _Nonnull)artist
                                                  album:(NSString * _Nonnull)album
                                                  limit:(NSNumber * _Nullable)limit
                                                  token:(NSString * _Nonnull)token;

@end
