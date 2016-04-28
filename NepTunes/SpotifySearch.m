//
//  SpotifySearch.m
//  Pods
//
//  Created by Adam Różyński on 27/04/16.
//
//


#import "SpotifySearch.h"
#include <CommonCrypto/CommonDigest.h>

static NSString *const kBaseURL = @"https://api.spotify.com/v1/";

typedef NS_ENUM(NSInteger, SpotifySearchType) {
    SpotifySearchArtist = 1,
    SpotifySearchAlbum,
    SpotifySearchTrack,
    SpotifySearchPlaylist
};

@interface SpotifySearch ()
@property (nonatomic) NSOperationQueue *operationQueue;
@end

@implementation SpotifySearch

+(_Nonnull instancetype)sharedInstance
{
    static SpotifySearch *spotifySearch = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        spotifySearch = [[SpotifySearch alloc] init];
    });
    return spotifySearch;
}

-(instancetype)init
{
    self = [super init];
    if (self) {
        self.timeoutInterval = 10;
        self.operationQueue = [NSOperationQueue new];
    }
    return self;
}

#pragma mark - PUBLIC

-(void)serachForArtistWithName:(NSString *)artistName limit:(NSNumber *)limit successHandler:(SpotifySearchReturnBlockWithArray)successHandler failureHandler:(SpotifySearchReturnBlockWithError)failureHandler
{
    NSMutableDictionary *params = [@{} mutableCopy];
    params[@"type"] = @"artist";
    params[@"q"] = [self forceString:artistName];
    if (limit && limit > 0) {
        params[@"limit"] = limit;
    }
    [self performApiCallForMethod:@"search"
                       withParams:params
                       andFilters:nil
                    andSearchType:SpotifySearchArtist
                   successHandler:successHandler
                   failureHandler:failureHandler];
}


#pragma mark - PRIVATE

-(void)performApiCallForMethod:(NSString*)method
                    withParams:(NSDictionary *)params
                    andFilters:(NSDictionary *)filters
                 andSearchType:(SpotifySearchType)searchType
                successHandler:(SpotifySearchReturnBlockWithObject)successHandler
                failureHandler:(SpotifySearchReturnBlockWithError)failureHandler
{
    [self performApiCallForMethod:method
                         useCache:YES
                       withParams:params
                       andFilters:filters
                    andSearchType:searchType
                   successHandler:successHandler
                   failureHandler:failureHandler];
}


//==========================================================================================================================


-(void)performApiCallForMethod:(NSString*)method
                      useCache:(BOOL)useCache
                    withParams:(NSDictionary *)params
                    andFilters:(NSDictionary *)filters
                 andSearchType:(SpotifySearchType)searchType
                successHandler:(SpotifySearchReturnBlockWithObject)successHandler
                failureHandler:(SpotifySearchReturnBlockWithError)failureHandler
{
    
    NSMutableDictionary *newParams = [params mutableCopy];
    
    
    // Convert the dict of params into an array of key=value strings
    NSMutableArray *paramsArray = [NSMutableArray arrayWithCapacity:[newParams count]];
    [newParams enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if (![key isEqualToString:@"type"]) {
            [paramsArray addObject:[NSString stringWithFormat:@"%@=%@", [self urlEscapeString:key], [self urlEscapeString:obj]]];
        }
    }];
    if (searchType) {
        [paramsArray addObject:[NSString stringWithFormat:@"type=%@", [self stringForType:searchType]]];
    }
    
    // Construct the request url
    NSString *url = [NSString stringWithFormat:@"%@%@?%@", kBaseURL, method, [paramsArray componentsJoinedByString:@"&"]];
    
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
                   andSearchType:searchType
                  successHandler:successHandler
                  failureHandler:failureHandler];
}

//==========================================================================================================================


-(void)_performApiCallWithURL:(NSString*)url
                     useCache:(BOOL)useCache
                    signature:(NSString *)cacheKey
                   withParams:(NSDictionary *)params
                   andFilters:(NSDictionary *)filters
                andSearchType:(SpotifySearchType)searchType
               successHandler:(SpotifySearchReturnBlockWithObject)successHandler
               failureHandler:(SpotifySearchReturnBlockWithError)failureHandler
{
    
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
                    NSError *invalidTopLevel = [NSError errorWithDomain:@"SpotifySearch"
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
            NSArray *results = jsonData[[self pluralStringForType:searchType]][@"items"];
            
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
    
    [self.operationQueue addOperation:op];
}

//==========================================================================================================================


-(NSString*)urlEscapeString:(id)unencodedString
{
    if ([unencodedString isKindOfClass:[NSString class]]) {
        CFStringRef originalStringRef = (__bridge_retained CFStringRef)unencodedString;
        NSString *s = (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,originalStringRef, NULL, NULL,kCFStringEncodingUTF8);
        CFRelease(originalStringRef);
        return s;
    }
    return unencodedString;
}

//==========================================================================================================================


-(NSString *)forceString:(NSString *)value
{
    if (!value) return @"";
    return value;
}

//==========================================================================================================================


-(NSString *)md5sumFromString:(NSString *)string
{
    unsigned char digest[CC_MD5_DIGEST_LENGTH], i;
    CC_MD5([string UTF8String], (CC_LONG)[string lengthOfBytesUsingEncoding:NSUTF8StringEncoding], digest);
    NSMutableString *ms = [NSMutableString string];
    for (i=0;i<CC_MD5_DIGEST_LENGTH;i++) {
        [ms appendFormat: @"%02x", (int)(digest[i])];
    }
    return [ms copy];
}

//==========================================================================================================================


-(NSString *)pluralStringForType:(SpotifySearchType)searchType
{
    switch(searchType) {
        case SpotifySearchArtist:
            return @"artists";
            break;
        case SpotifySearchAlbum:
            return @"albums";
            break;
        case SpotifySearchTrack:
            return @"tracks";
            break;
        case SpotifySearchPlaylist:
            return @"playlists";
            break;
        default:
            return nil;
            break;
    }
}

//==========================================================================================================================


-(NSString *)stringForType:(SpotifySearchType)searchType
{
    switch(searchType) {
        case SpotifySearchArtist:
            return @"artist";
            break;
        case SpotifySearchAlbum:
            return @"album";
            break;
        case SpotifySearchTrack:
            return @"track";
            break;
        case SpotifySearchPlaylist:
            return @"playlist";
            break;
        default:
            return nil;
            break;
    }
}

//==========================================================================================================================


@end