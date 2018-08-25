//
//  MPISpotifySearch.m
//  NepTunes
//
//  Created by Adam Różyński on 10/10/2017.
//  Copyright © 2017 micropixels. All rights reserved.
//

#import "MPISpotifySearch.h"
#import "MPISpotifyToken.h"
#import "MPISpotifyRequestsFactory.h"
#import "GVUserDefaults+Settings.h"

@interface MPISpotifySearch ()
@property (nonatomic) NSURLSession  *session;
@end

@implementation MPISpotifySearch

+ (instancetype _Nonnull)sharedInstance
{
    static MPISpotifySearch *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[MPISpotifySearch alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.clientId = @"b2c8b5a310b84340966c06901a1e4153";
        self.clientSecret = @"2964f9c8caea46b7a7b46c8d8ffa8693";

    }
    return self;
}

- (void)authorizeClientWithHandler:(SpotifyAuthorizationHandler)handler
{
    NSURLRequest *request = [MPISpotifyRequestsFactory requestForAuthorizeWithClientID:self.clientId andClientSecret:self.clientSecret];
    [self _makeNetworkRequest:request withHandler:^(NSError *error, id result) {
        NSError *jsonModelError;
        MPISpotifyToken *token = [[MPISpotifyToken alloc] initWithDictionary:result error:&jsonModelError];
        if (token) {
            [GVUserDefaults standardUserDefaults].spotifyToken = token.accessToken;
            [GVUserDefaults standardUserDefaults].spotifyTokenExpirationDate = token.expirationDate;
            self.token = token.accessToken;
        }
        if (handler) {
            handler(error ?: jsonModelError, token);
        }
    }];
}

- (void)searchForArtistWithName:(NSString *)artistName
                         limit:(NSNumber *)limit
                       handler:(SpotifySearchReturnBlockWithResult)handler
{
    [self _verifyAndUpdateCachedTokenIfNeededWithHandler:^(NSError *error) {
        if (error) {
            handler(error, nil);
            return;
        }
        NSURLRequest *request = [MPISpotifyRequestsFactory requestWithSearchForArtistWithName:artistName limit:limit token:self.token];
        [self _makeNetworkRequest:request withHandler:^(NSError *error, id result) {
            if (handler) { handler(error, [[(NSDictionary *)result objectForKey:@"artists"] objectForKey:@"items"]); }
        }];
    }];
}

- (void)getTrackWithName:(NSString * _Nonnull)trackName
                 artist:(NSString * _Nonnull)artist
                  album:(NSString * _Nonnull)album
                  limit:(NSNumber * _Nullable)limit
                handler:(SpotifySearchReturnBlockWithResult _Nonnull)handler
{
    [self _verifyAndUpdateCachedTokenIfNeededWithHandler:^(NSError *error) {
        if (error) {
            handler(error, nil);
            return;
        }
        NSURLRequest *request = [MPISpotifyRequestsFactory requestWithGetTrackWithhName:trackName
                                                                                 artist:artist
                                                                                  album:album
                                                                                  limit:limit
                                                                                  token:self.token];
        [self _makeNetworkRequest:request withHandler:^(NSError *error, id result) {
            if (handler) { handler(error, [[(NSDictionary *)result objectForKey:@"tracks"] objectForKey:@"items"]); }
        }];
    }];
}

- (void)getTrackWithID:(NSString * _Nonnull)trackID
              handler:(SpotifySearchReturnBlockWithResult _Nonnull)handler
{
    [self _verifyAndUpdateCachedTokenIfNeededWithHandler:^(NSError *error) {
        if (error) {
            handler(error, nil);
            return;
        }
        NSURLRequest *request = [MPISpotifyRequestsFactory requestForGetTrackWithIds:@[trackID] token:self.token];
        [self _makeNetworkRequest:request withHandler:^(NSError *error, id result) {
            if (handler) { handler(error, [(NSDictionary *)result objectForKey:@"tracks"]); }
        }];
    }];
}

#pragma mark – PRIVATE
- (void)_makeNetworkRequest:(NSURLRequest *)request withHandler:(void (^)(NSError *error, id result))handler
{
    if ([self.cache respondsToSelector:@selector(cachedObjectForKey:)]) {
        NSString *key = request.URL.absoluteString;
        id results = [self.cache cachedObjectForKey:key];
        if (results) {
            handler(nil, results);
            return;
        }
    }
    [[self.session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (handler) {
            id result = nil;
            NSError *jsonError = nil;
            if (data) {
                result = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonError];
                if ([self.cache respondsToSelector:@selector(cacheResult:forKey:maxAge:)]) {
                    [self.cache cacheResult:result forKey:request.URL.absoluteString maxAge:60 * 60 * 48];
                }
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(error ?: jsonError, result);
            });
        }
    }] resume];
}

- (void)_verifyAndUpdateCachedTokenIfNeededWithHandler:(void (^)(NSError *error))handler
{
    NSString *token = [GVUserDefaults standardUserDefaults].spotifyToken;
    NSDate *tokenExpirationDate = [GVUserDefaults standardUserDefaults].spotifyTokenExpirationDate;
    self.token = token;
    if ([tokenExpirationDate compare:[NSDate date]] == NSOrderedAscending) {
        self.token = nil;
        [self authorizeClientWithHandler:^(NSError * _Nullable error, MPISpotifyToken * _Nullable token) {
            if (handler) { handler(error); }
        }];
    } else {
        if (handler) { handler(nil); }
    }
}

- (NSURLSession *)session
{
    if (!_session) {
        _session = [NSURLSession sharedSession];
    }
    return _session;
}

@end
