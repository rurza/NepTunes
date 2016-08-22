//
//  SpotifySearch.h
//  Pods
//
//  Created by Adam Różyński on 27/04/16.
//
//

#import <Foundation/Foundation.h>

typedef void (^SpotifySearchReturnBlockWithObject)  (id _Nullable object);
typedef void (^SpotifySearchReturnBlockWithArray)   (NSArray * _Nullable result);
typedef void (^SpotifySearchReturnBlockWithError)   (NSError * _Nonnull error);

@protocol SpotifySearchCache <NSObject>
@optional
- (NSArray * _Nullable)cachedArrayForKey:(NSString * _Nonnull)key;
- (void)cacheArray:(NSArray * _Nonnull)array
            forKey:(NSString * _Nonnull)key
     requestParams:(NSDictionary * _Nonnull)params
            maxAge:(NSTimeInterval)maxAge;
@end

@interface SpotifySearch : NSObject

@property (nonatomic) NSTimeInterval timeoutInterval; //in seconds
@property (nonatomic, weak) id<SpotifySearchCache> _Nullable cacheDelegate;
@property (nonatomic) NSTimeInterval maxCacheAge;

+(_Nonnull instancetype)sharedInstance;

#pragma mark - Artist methods

-(void)searchForArtistWithName:(NSString * _Nonnull)artistName
                         limit:(NSNumber * _Nullable)limit
                successHandler:(SpotifySearchReturnBlockWithArray _Nullable)successHandler
                failureHandler:(SpotifySearchReturnBlockWithError _Nullable)failureHandler;


#pragma mark - Track methods

-(void)getTrackWithName:(NSString * _Nonnull)trackName
                  artist:(NSString * _Nonnull)artist
                   album:(NSString * _Nonnull)album
                   limit:(NSNumber * _Nullable)limit
          successHandler:(SpotifySearchReturnBlockWithArray _Nullable)successHandler
          failureHandler:(SpotifySearchReturnBlockWithError _Nullable)failureHandler;

-(void)getTrackWithID:(NSString * _Nonnull)trackID
       successHandler:(SpotifySearchReturnBlockWithArray _Nullable)successHandler
       failureHandler:(SpotifySearchReturnBlockWithError _Nullable)failureHandler;


@end