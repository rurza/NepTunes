//
//  ItunesSearch.h
//  iTunesSearch
//
//  Created by Piers Biddlestone on 28/09/12.
//  Copyright (c) 2012 Gangverk. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^ItunesSearchReturnBlockWithObject)(id result);
typedef void (^ItunesSearchReturnBlockWithArray)(NSArray *result);
typedef void (^ItunesSearchReturnBlockWithError)(NSError *error);

@protocol ItunesSearchCache <NSObject>
@optional
- (NSArray *)cachedArrayForKey:(NSString *)key;
- (void)cacheArray:(NSArray *)array forKey:(NSString *)key requestParams:(NSDictionary *)params maxAge:(NSTimeInterval)maxAge;
@end

@interface ItunesSearch : NSObject

@property (strong, nonatomic) NSString *affiliateToken;
@property (strong, nonatomic) NSString *campaignToken;
@property (strong, nonatomic) NSString *countryCode;    // default: NSLocaleCountryCode
@property (unsafe_unretained, nonatomic) id <ItunesSearchCache> cacheDelegate;
@property (nonatomic) NSTimeInterval timeoutInterval;   // default: 10
@property (nonatomic) NSTimeInterval maxCacheAge;       // default: 60*60*24

+ (ItunesSearch *)sharedInstance;
- (void)performApiCallForMethod:(NSString*)method withParams:(NSDictionary *)params andFilters:(NSDictionary *)filters successHandler:(ItunesSearchReturnBlockWithObject)successHandler failureHandler:(ItunesSearchReturnBlockWithError)failureHandler;
- (void)performApiCallForMethod:(NSString*)method useCache:(BOOL)useCache withParams:(NSDictionary *)params andFilters:(NSDictionary *)filters successHandler:(ItunesSearchReturnBlockWithObject)successHandler failureHandler:(ItunesSearchReturnBlockWithError)failureHandler;

#pragma mark - Album methods

- (void)getTracksForAlbums:(NSArray *)albumIds limitOrNil:(NSNumber *)limit sucessHandler:(ItunesSearchReturnBlockWithArray)successHandler failureHandler:(ItunesSearchReturnBlockWithError)failureHandler;

#pragma mark - Artist methods

- (void)getAlbumsForArtist:(NSNumber *)artistId limitOrNil:(NSNumber *)limit successHandler:(ItunesSearchReturnBlockWithArray)successHandler failureHandler:(ItunesSearchReturnBlockWithError)failureHandler;
- (void)getAlbumWithArtist:(NSString *)artistName andName:(NSString *)albumName limitOrNil:(NSNumber *)limit successHandler:(ItunesSearchReturnBlockWithArray)successHandler failureHandler:(ItunesSearchReturnBlockWithError)failureHandler;
- (void)getIdForArtist:(NSString *)artist successHandler:(ItunesSearchReturnBlockWithArray)successHandler failureHandler:(ItunesSearchReturnBlockWithError)failureHandler;

#pragma mark - Track methods

- (void)getTrackWithName:(NSString *)trackName artist:(NSString *)artist album:(NSString *)album limitOrNil:(NSNumber *)limit successHandler:(ItunesSearchReturnBlockWithArray)successHandler failureHandler:(ItunesSearchReturnBlockWithError)failureHandler;

#pragma mark - App methods

- (void)getAppWithName:(NSString *)appName developer:(NSString*)developer limitOrNil:(NSNumber *)limit successHandler:(ItunesSearchReturnBlockWithArray)successHandler failureHandler:(ItunesSearchReturnBlockWithError)failureHandler;
- (void)getAppsByDeveloper:(NSString *)developerId limitOrNil:(NSNumber *)limit successHandler:(ItunesSearchReturnBlockWithArray)successHandler failureHandler:(ItunesSearchReturnBlockWithError)failureHandler;
- (void)getAppsWithIds:(NSArray *)appIds successHandler:(ItunesSearchReturnBlockWithArray)successHandler failureHandler:(ItunesSearchReturnBlockWithError)failureHandler;

#pragma mark - Podcast methods

- (void)getPodcastWithName:(NSString *)podcast artist:(NSString *)artist limitOrNil:(NSNumber *)limit successHandler:(ItunesSearchReturnBlockWithArray)successHandler failureHandler:(ItunesSearchReturnBlockWithError)failureHandler;

@end
