//
//  ExampleCache.m
//  Example
//
//  Created by Kevin Renskers on 31-10-12.
//  Copyright (c) 2012 Gangverk. All rights reserved.
//

/*
 * Better example: uses memory cache but falls back to rolling 
 * disk cache with the help of EGOCache.
 *
 * Rolling cache: cache will never be purged from disk after
 * its expire time is reached. Instead, the cached version is 
 * used AND a request to Last.fm is made, updating the cache
 * in the process. This way, you will never hit the situation
 * where you're offline and the cached is cleared because
 * it's 24 hours old, leaving you with nothing.
 */

#import "LastFmCache.h"
#import "EGOCache.h"

@interface LastFmCache ()
@property (strong, nonatomic) NSCache *cache;
@end

@implementation LastFmCache

- (id)init {
    self = [super init];
    if (self) {
        self.cache = [[NSCache alloc] init];
    }
    return self;
}

- (BOOL)cacheExpiredForKey:(NSString *)key requestParams:(NSDictionary *)params {
    NSDate *created = [[EGOCache globalCache] dateForKey:key];
    NSTimeInterval age = [[NSDate date] timeIntervalSinceDate:created];
    NSTimeInterval maxAge = 24*60*60;
    if (age > maxAge) {
        return YES;
    }

    return NO;
}

- (NSArray *)cachedArrayForKey:(NSString *)key {
    // Get from memory
    NSArray *result = [self.cache objectForKey:key];
    if (result) {
        return result;
    }

    // Get from disk
    NSData *data = [[EGOCache globalCache] dataForKey:key];
    if (data) {
        // Save in memory
        result = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        [self.cache setObject:result forKey:key];
        return result;
    }

    return nil;
}

- (void)cacheArray:(NSArray *)array forKey:(NSString *)key maxAge:(NSTimeInterval)maxAge {
    // Save in memory
    [self.cache setObject:array forKey:key];

    // Also save to disk. Timeout is 10 years, never automatically remove stuff from cache.
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:array];
    [[EGOCache globalCache] setData:data forKey:key withTimeoutInterval:60*60*24*365*10];
}

@end

