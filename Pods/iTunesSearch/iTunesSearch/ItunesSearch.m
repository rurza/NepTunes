//
//  ItunesSearch.m
//  iTunesSearch
//
//  Created by Piers Biddlestone on 28/09/12.
//  Copyright (c) 2012 Gangverk. All rights reserved.
//

#include <CommonCrypto/CommonDigest.h>
#import "ItunesSearch.h"

#define API_URL @"https://geo.itunes.apple.com/"

@interface ItunesSearch ()
@property (nonatomic, strong) NSOperationQueue *queue;
@end

@implementation ItunesSearch

#pragma mark - Initialization

+ (ItunesSearch *)sharedInstance {
    static dispatch_once_t pred;
    static ItunesSearch *sharedInstance = nil;
    dispatch_once(&pred, ^{ sharedInstance = [[self alloc] init]; });
    return sharedInstance;
}

- (id)init {
    self = [super init];
    if (self) {
        self.affiliateToken = @"";
        self.campaignToken = @"";
        self.queue = [[NSOperationQueue alloc] init];
        self.timeoutInterval = 10;
        self.maxCacheAge = (60 * 60 * 24);
    }
    return self;
}

#pragma mark - Private methods

- (NSString *)md5sumFromString:(NSString *)string {
	unsigned char digest[CC_MD5_DIGEST_LENGTH], i;
	CC_MD5([string UTF8String], (CC_LONG)[string lengthOfBytesUsingEncoding:NSUTF8StringEncoding], digest);
	NSMutableString *ms = [NSMutableString string];
	for (i=0;i<CC_MD5_DIGEST_LENGTH;i++) {
		[ms appendFormat: @"%02x", (int)(digest[i])];
	}
	return [ms copy];
}

- (NSString*)urlEscapeString:(id)unencodedString {
    if ([unencodedString isKindOfClass:[NSString class]]) {
        CFStringRef originalStringRef = (__bridge_retained CFStringRef)unencodedString;
        NSString *s = (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,originalStringRef, NULL, NULL,kCFStringEncodingUTF8);
        CFRelease(originalStringRef);
        return s;
    }
    return unencodedString;
}

- (NSString *)forceString:(NSString *)value {
    if (!value) return @"";
    return value;
}

- (NSString *)countryCode {
    if (!_countryCode) _countryCode = [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
    return _countryCode;
}

- (void)performApiCallForMethod:(NSString*)method
                     withParams:(NSDictionary *)params
                     andFilters:(NSDictionary *)filters
                 successHandler:(ItunesSearchReturnBlockWithObject)successHandler
                 failureHandler:(ItunesSearchReturnBlockWithError)failureHandler {

    [self performApiCallForMethod:method
                         useCache:YES
                       withParams:params
                       andFilters:filters
                   successHandler:successHandler
                   failureHandler:failureHandler];
}

- (void)performApiCallForMethod:(NSString*)method
                       useCache:(BOOL)useCache
                     withParams:(NSDictionary *)params
                     andFilters:(NSDictionary *)filters
                 successHandler:(ItunesSearchReturnBlockWithObject)successHandler
                 failureHandler:(ItunesSearchReturnBlockWithError)failureHandler {

    NSMutableDictionary *newParams = [params mutableCopy];

    // Add affiliate token if supplied
    if (self.affiliateToken && self.affiliateToken.length > 0) {
        newParams[@"at"] = self.affiliateToken;
    }

    // Add campaign token if supplied
    if (self.campaignToken && self.campaignToken.length > 0) {
        newParams[@"ct"] = self.campaignToken;
    }
    
    // Set the user's country to get the correct price
    if (self.countryCode && self.countryCode.length) {
        newParams[@"country"] = self.countryCode;
    }

    // Convert the dict of params into an array of key=value strings
    NSMutableArray *paramsArray = [NSMutableArray arrayWithCapacity:[newParams count]];
    [newParams enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [paramsArray addObject:[NSString stringWithFormat:@"%@=%@", [self urlEscapeString:key], [self urlEscapeString:obj]]];
    }];

    // Construct the request url
    NSString *url = [NSString stringWithFormat:@"%@%@?%@", API_URL, method, [paramsArray componentsJoinedByString:@"&"]];

    // Check if we have the object in cache
    NSString *cacheKey = [self md5sumFromString:url];
    if (useCache && self.cacheDelegate && [self.cacheDelegate respondsToSelector:@selector(cachedArrayForKey:)]) {
        NSArray *cachedArray = [self.cacheDelegate cachedArrayForKey:cacheKey];
        if (cachedArray && cachedArray.count) {
            if (successHandler) {
                successHandler(cachedArray);
            }
            return;
        }
    }

    [self _performApiCallWithURL:url
                        useCache:useCache
                       signature:cacheKey
                      withParams:newParams
                      andFilters:filters
                  successHandler:successHandler
                  failureHandler:failureHandler];
}

- (void)_performApiCallWithURL:(NSString*)url
                      useCache:(BOOL)useCache
                     signature:(NSString *)cacheKey
                    withParams:(NSDictionary *)params
                    andFilters:(NSDictionary *)filters
                successHandler:(ItunesSearchReturnBlockWithObject)successHandler
                failureHandler:(ItunesSearchReturnBlockWithError)failureHandler {

    NSBlockOperation *op = [[NSBlockOperation alloc] init];
    [op addExecutionBlock:^{
        // Set up the http request
        NSURLRequestCachePolicy policy = NSURLRequestUseProtocolCachePolicy;
        if (!useCache) {
            policy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
        }
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]
                                                               cachePolicy:policy
                                                           timeoutInterval:self.timeoutInterval];
        [request setHTTPMethod:@"GET"];

        NSHTTPURLResponse *response;
        NSError *error;
        NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];

        // Check for NSURLConnection errors
        if (error) {
            if (failureHandler) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    failureHandler(error);
                }];
            }
            return;
        }

        // Deserialise the raw data into a JSON object
        id jsonData = [NSJSONSerialization JSONObjectWithData:data
                                                      options:0
                                                        error:&error];

        // Check for data serialization errors
        if (error) {
            if (failureHandler) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    failureHandler(error);
                }];
            }
            return;
        }

        // Ensure a dictionary was received
        if (![jsonData isKindOfClass:[NSDictionary class]]) {
            if (failureHandler) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    // Build an error describing the failure
                    NSMutableDictionary* details = [NSMutableDictionary dictionary];
                    [details setValue:@"Expected a dictionary as the top level object"
                               forKey:NSLocalizedDescriptionKey];
                    NSError *invalidTopLevel = [NSError errorWithDomain:@"ItunesSearch"
                                                                   code:101
                                                               userInfo:details];

                    // Execute the failure handler
                    failureHandler(invalidTopLevel);
                }];
            }

            return;
        }

        // Extract the results from the returned data
        NSArray *filteredResults = nil;
        if (jsonData && [jsonData count] > 0) {
            // Pull out the results object
            NSArray *results = jsonData[@"results"];

            // Sanity check the results
            if (results) {
                // Apply filters to the results if supplied
                if (filters && [filters count] > 0) {
                    NSMutableArray *predicates = [NSMutableArray array];
                    // Construct a case-insensitive predicate for each filter
                    for (id key in [filters allKeys]) {
                        [predicates addObject:[NSPredicate predicateWithFormat:
                                               @"%K ==[c] %@",
                                               key,
                                               [filters valueForKey:key]]];
                    }

                    // Apply the predicates
                    filteredResults = [results filteredArrayUsingPredicate:
                                       [NSCompoundPredicate andPredicateWithSubpredicates:predicates]];
                } else {
                    // No filtering necessary
                    filteredResults = results;
                }
            }
        }

        // Add to cache
        if (useCache &&
            self.cacheDelegate &&
            [self.cacheDelegate respondsToSelector:@selector(cacheArray:forKey:requestParams:maxAge:)]) {
            [self.cacheDelegate cacheArray:filteredResults forKey:cacheKey requestParams:params maxAge:self.maxCacheAge];
        }

        // Send the results to the success handler
        if (successHandler) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                successHandler(filteredResults);
            }];
        }
    }];

    [self.queue addOperation:op];
}

#pragma mark - Album methods

- (void)getTracksForAlbums:(NSArray *)albumIds limitOrNil:(NSNumber *)limit sucessHandler:(ItunesSearchReturnBlockWithArray)successHandler failureHandler:(ItunesSearchReturnBlockWithError)failureHandler {
    // Set up the request parameters
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    params[@"id"] = [albumIds componentsJoinedByString:@","];
    params[@"entity"] = @"song";

    // Add the limit if supplied
    if (limit && limit > 0) {
        params[@"limit"] = limit;
    }

    [self performApiCallForMethod:@"lookup"
                       withParams:params
                       andFilters:nil
                   successHandler:successHandler
                   failureHandler:failureHandler];
}

#pragma mark - Artist methods

- (void)getAlbumsForArtist:(NSNumber *)artistId limitOrNil:(NSNumber *)limit successHandler:(ItunesSearchReturnBlockWithArray)successHandler failureHandler:(ItunesSearchReturnBlockWithError)failureHandler {
    // Set up the request paramters
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    params[@"id"] = [self forceString:[artistId stringValue]];
    params[@"media"] = @"music";
    params[@"entity"] = @"album";

    // Set up the results filter
    NSDictionary *filters = @{
        @"wrapperType": @"collection",
        @"collectionType": @"album"
    };

    // Add the limit if supplied
    if (limit && [limit integerValue] > 0) {
        params[@"limit"] = limit;
    }

    [self performApiCallForMethod:@"lookup"
                       withParams:params
                       andFilters:filters
                   successHandler:successHandler
                   failureHandler:failureHandler];
}

- (void)getAlbumWithArtist:(NSString *)artistName andName:(NSString *)albumName limitOrNil:(NSNumber *)limit successHandler:(ItunesSearchReturnBlockWithArray)successHandler failureHandler:(ItunesSearchReturnBlockWithError)failureHandler {
    // Set up the request paramters
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    params[@"term"] = [self forceString:artistName];
    params[@"media"] = @"music";
    params[@"entity"] = @"album";
    params[@"attribute"] = @"artistTerm";

    // Set up the results filter
    NSDictionary *filters = @{
        @"wrapperType": @"collection",
        @"collectionType": @"album",
        @"collectionName": albumName
    };

    // Add the limit if supplied
    if (limit && [limit integerValue] > 0) {
        params[@"limit"] = limit;
    }

    [self performApiCallForMethod:@"search"
                       withParams:params
                       andFilters:filters
                   successHandler:successHandler
                   failureHandler:failureHandler];
}

- (void)getIdForArtist:(NSString *)artist successHandler:(ItunesSearchReturnBlockWithArray)successHandler failureHandler:(ItunesSearchReturnBlockWithError)failureHandler {
    // Set up the request paramters
    NSDictionary *params = @{
        @"term": [self forceString:artist],
        @"media": @"music",
        @"entity": @"musicArtist",
        @"attribute": @"artistTerm",
    };

    // Set up the results filter
    NSDictionary *filters = @{ @"artistName": [self forceString:artist] };

    [self performApiCallForMethod:@"search"
                       withParams:params
                       andFilters:filters
                   successHandler:successHandler
                   failureHandler:failureHandler];
}

#pragma mark - Track methods

- (void)getTrackWithName:(NSString *)trackName artist:(NSString *)artist album:(NSString *)album limitOrNil:(NSNumber *)limit successHandler:(ItunesSearchReturnBlockWithArray)successHandler failureHandler:(ItunesSearchReturnBlockWithError)failureHandler {
    // Ensure only valid objects are used in the search
    NSMutableArray *searchParameters = [NSMutableArray array];
    if (trackName) {
        [searchParameters addObject:trackName];
    }

    if (artist) {
        [searchParameters addObject:artist];
    }

    if (album) {
        [searchParameters addObject:album];
    }

    // Build the search term
    NSString *searchTerm = [searchParameters componentsJoinedByString:@"+"];

    if (searchTerm && [searchTerm length] > 0) {
        // Set up the request paramters
        NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
        params[@"term"] = [self forceString:searchTerm];
        params[@"media"] = @"music";
        params[@"entity"] = @"song";

        // Add the limit if supplied
        if (limit && limit > 0) {
            params[@"limit"] = limit;
        }

        [self performApiCallForMethod:@"search"
                           withParams:params
                           andFilters:nil
                       successHandler:successHandler
                       failureHandler:failureHandler];
    } else {
        if (successHandler) {
            return successHandler(nil);
        }
    }
}

#pragma mark - App methods

- (void)getAppWithName:(NSString *)appName developer:(NSString *)developer limitOrNil:(NSNumber *)limit successHandler:(ItunesSearchReturnBlockWithArray)successHandler failureHandler:(ItunesSearchReturnBlockWithError)failureHandler {
    // Ensure only valid objects are used in the search
    NSMutableArray *searchParameters = [NSMutableArray array];

    if (appName) {
        [searchParameters addObject:appName];
    }

    if (developer) {
        [searchParameters addObject:developer];
    }

    // Build the search term
    NSString *searchTerm = [searchParameters componentsJoinedByString:@"+"];

    if (searchTerm && [searchTerm length] > 0) {
        // Set up the request paramters
        NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
        params[@"term"] = [self forceString:searchTerm];
        params[@"media"] = @"software";

        // Add the limit if supplied
        if (limit && limit > 0) {
            params[@"limit"] = limit;
        }

        [self performApiCallForMethod:@"search"
                           withParams:params
                           andFilters:nil
                       successHandler:successHandler
                       failureHandler:failureHandler];
    } else {
        if (successHandler) {
            return successHandler(nil);
        }
    }
}

- (void)getAppsByDeveloper:(NSString *)developerId limitOrNil:(NSNumber *)limit successHandler:(ItunesSearchReturnBlockWithArray)successHandler failureHandler:(ItunesSearchReturnBlockWithError)failureHandler {
    // Ensure only valid developerId is used in the search
    if (developerId && [developerId length] > 0) {
        // Set up the request paramters
        NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
        params[@"id"] = developerId;
        params[@"entity"] = @"software";

        // Add the limit if supplied
        if (limit && limit > 0) {
            params[@"limit"] = limit;
        }

        [self performApiCallForMethod:@"lookup"
                           withParams:params
                           andFilters:nil
                       successHandler:successHandler
                       failureHandler:failureHandler];
    } else {
        if (successHandler) {
            return successHandler(nil);
        }
    }
}

- (void)getAppsWithIds:(NSArray *)appIds successHandler:(ItunesSearchReturnBlockWithArray)successHandler failureHandler:(ItunesSearchReturnBlockWithError)failureHandler {
    // Build a string of App Ids
    NSString *appIdsString = [appIds componentsJoinedByString:@","];
    
    if (appIdsString && [appIdsString length] > 0) {
        // Set up the request paramters
        NSDictionary * params = @{
            @"id": [self forceString:appIdsString],
            @"media": @"software"
        };
        
        [self performApiCallForMethod:@"lookup"
                           withParams:params
                           andFilters:nil
                       successHandler:successHandler
                       failureHandler:failureHandler];
    } else {
        if (successHandler) {
            return successHandler(nil);
        }
    }
}

#pragma mark - Podcast methods

- (void)getPodcastWithName:(NSString *)podcast artist:(NSString *)artist limitOrNil:(NSNumber *)limit successHandler:(ItunesSearchReturnBlockWithArray)successHandler failureHandler:(ItunesSearchReturnBlockWithError)failureHandler {

    NSMutableArray *searchParameters = [NSMutableArray array];
    if (podcast) {
        [searchParameters addObject:podcast];
    }
    
    if (artist) {
        [searchParameters addObject:artist];
    }
    
    // Build the search term
    NSString *searchTerm = [searchParameters componentsJoinedByString:@"+"];
    
    if (searchTerm && [searchTerm length] > 0) {
        // Set up the request paramters
        NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
        params[@"term"] = [self forceString:searchTerm];
        params[@"media"] = @"podcast";
        params[@"entity"] = @"podcast";
        
        // Add the limit if supplied
        if (limit && limit > 0) {
            params[@"limit"] = limit;
        }
        
        [self performApiCallForMethod:@"search"
                           withParams:params
                           andFilters:nil
                       successHandler:successHandler
                       failureHandler:failureHandler];
    } else {
        if (successHandler) {
            return successHandler(nil);
        }
    }
}


@end
