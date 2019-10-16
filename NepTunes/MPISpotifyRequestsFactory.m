//
//  MPISpotifyRequestsFactory.m
//  NepTunes
//
//  Created by Adam Różyński on 11/10/2017.
//  Copyright © 2017 micropixels. All rights reserved.
//

#import "MPISpotifyRequestsFactory.h"

static NSString *const kMPISpotifyAPIHost =             @"api.spotify.com";
static NSString *const kMPISpotifyAPIScheme =           @"https";
static NSString *const kMPISpotifyAPIVersion =          @"/v1";
static NSString *const kMPISpotifyAPITracksEndpoint =   @"/tracks";
static NSString *const kMPISpotifyAPISearchEndpoint =   @"/search";

static NSString *const kMPIHttpMethodPOST =             @"POST";
static NSString *const kMPIHttpMethodGET =              @"GET";

@implementation MPISpotifyRequestsFactory

+ (NSURLRequest *)requestForAuthorizeWithClientID:(NSString * _Nonnull)clientId
                                  andClientSecret:(NSString * _Nonnull)clientSecret
{
    NSURLComponents *urlComponents = [[NSURLComponents alloc] init];
    urlComponents.host = @"accounts.spotify.com";
    urlComponents.scheme = kMPISpotifyAPIScheme;
    urlComponents.path = @"/api/token";
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:urlComponents.URL];
    request.HTTPMethod = kMPIHttpMethodPOST;
    request.HTTPBody = [@"grant_type=client_credentials" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *data = [[NSString stringWithFormat:@"%@:%@", clientId, clientSecret] dataUsingEncoding:NSUTF8StringEncoding];
    NSString *base64String = [data base64EncodedStringWithOptions:0];
    request.allHTTPHeaderFields = @{
                                    @"Authorization": [NSString stringWithFormat:@"Basic %@", base64String]
                                    };
    return request;
}

+ (NSURLRequest *)requestWithSearchForArtistWithName:(NSString * _Nonnull)artistName
                                               limit:(NSNumber * _Nullable)limit
                                               token:(NSString * _Nonnull)token
{
    NSURLComponents *urlComponents = [self _urlComponentsWithPath:kMPISpotifyAPISearchEndpoint];
    NSMutableArray *queryItems = [NSMutableArray new];
    [queryItems addObjectsFromArray:@[[NSURLQueryItem queryItemWithName:@"q" value:[NSString stringWithFormat:@"artist:%@", artistName]],
                                      [NSURLQueryItem queryItemWithName:@"type" value:@"artist"]]];
    if (limit.unsignedIntegerValue > 0) {
        [queryItems addObject:[NSURLQueryItem queryItemWithName:@"limit" value:limit.stringValue]];
    }
    urlComponents.queryItems = queryItems;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:urlComponents.URL];
    request.allHTTPHeaderFields = @{@"Authorization": [NSString stringWithFormat:@"Bearer %@", token]};

    return request;
}

+ (NSURLRequest *)requestForGetTrackWithIds:(NSArray<NSString *> * _Nonnull)ids
                                      token:(NSString * _Nonnull)token
{
    NSURLComponents *urlComponents = [self _urlComponentsWithPath:kMPISpotifyAPITracksEndpoint];
    urlComponents.queryItems = @[[NSURLQueryItem queryItemWithName:@"ids" value:[ids componentsJoinedByString:@","]]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:urlComponents.URL];
    request.allHTTPHeaderFields = @{@"Authorization": [NSString stringWithFormat:@"Bearer %@", token]};
    return request;
}

+ (NSURLRequest *)requestWithGetTrackWithhName:(NSString * _Nonnull)trackName
                                        artist:(NSString * _Nonnull)artist
                                         album:(NSString * _Nonnull)album
                                         limit:(NSNumber * _Nullable)limit
                                         token:(NSString * _Nonnull)token
{
    NSURLComponents *urlComponents = [self _urlComponentsWithPath:kMPISpotifyAPISearchEndpoint];
    NSMutableArray *queryItems = [NSMutableArray new];
    [queryItems addObject:[NSURLQueryItem queryItemWithName:@"type" value:@"track"]];
    [queryItems addObject:[NSURLQueryItem queryItemWithName:@"q" value:[NSString stringWithFormat:@"artist:%@ album:%@ track:%@", artist, album, trackName]]];

    if (limit.unsignedIntegerValue > 0) {
        [queryItems addObject:[NSURLQueryItem queryItemWithName:@"limit" value:limit.stringValue]];
    }
    urlComponents.queryItems = queryItems;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:urlComponents.URL];
    request.allHTTPHeaderFields = @{@"Authorization": [NSString stringWithFormat:@"Bearer %@", token]};

    return request;
}

#pragma mark - Private
+ (NSURLComponents *)_urlComponentsWithPath:(NSString *)path
{
    NSURLComponents *urlComponents = [[NSURLComponents alloc] init];
    urlComponents.host = kMPISpotifyAPIHost;
    urlComponents.scheme = kMPISpotifyAPIScheme;
    urlComponents.path = [NSString stringWithFormat:@"%@%@", kMPISpotifyAPIVersion, path];
    return urlComponents;
}

@end
