//
//  MPISpotifySearch.h
//  NepTunes
//
//  Created by Adam Różyński on 10/10/2017.
//  Copyright © 2017 micropixels. All rights reserved.
//

#import <Foundation/Foundation.h>
@class MPISpotifyToken;

typedef void (^SpotifySearchReturnBlockWithResult)  (NSError * _Nullable error, id _Nullable result);
typedef void (^SpotifyAuthorizationHandler)         (NSError * _Nullable error, MPISpotifyToken * _Nullable token);

@protocol SpotifySearchCache <NSObject>
@optional
- (id _Nullable)cachedObjectForKey:(NSString * _Nonnull)key;
- (void)cacheResult:(id _Nonnull)result
             forKey:(NSString * _Nonnull)key
             maxAge:(NSTimeInterval)maxAge;
@end

@interface MPISpotifySearch : NSObject

@property (nonatomic) NSString  * _Nullable clientId;
@property (nonatomic) NSString  * _Nullable clientSecret;
@property (nonatomic) NSString  * _Nullable token;

@property (nonatomic, weak) id<SpotifySearchCache> _Nullable cache;

+ (instancetype _Nonnull)sharedInstance;

- (void)authorizeClientWithHandler:(SpotifyAuthorizationHandler _Nullable)handler;

- (void)searchForArtistWithName:(NSString * _Nonnull)artistName
                          limit:(NSNumber * _Nullable)limit
                        handler:(SpotifySearchReturnBlockWithResult _Nonnull)handler;

- (void)getTrackWithName:(NSString * _Nonnull)trackName
                  artist:(NSString * _Nonnull)artist
                   album:(NSString * _Nonnull)album
                   limit:(NSNumber * _Nullable)limit
                 handler:(SpotifySearchReturnBlockWithResult _Nonnull)handler;

- (void)getTrackWithID:(NSString * _Nonnull)trackID
               handler:(SpotifySearchReturnBlockWithResult _Nonnull)handler;

@end
