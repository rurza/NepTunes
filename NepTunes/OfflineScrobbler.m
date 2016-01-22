//
//  OfflineScrobbler.m
//  NepTunes
//
//  Created by rurza on 20/01/16.
//  Copyright © 2016 micropixels. All rights reserved.
//

#import "OfflineScrobbler.h"
#import "FXReachability.h"
#import "MusicScrobbler.h"
#import "SavedSong.h"

@interface OfflineScrobbler ()
@property (nonatomic) NSMutableArray *songs;
@property (nonatomic) NSOperationQueue *offlineScrobblerOperationQueue;
@end

@implementation OfflineScrobbler

#pragma mark - Public

+(OfflineScrobbler *)sharedInstance
{
    static OfflineScrobbler *scrobbler = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        scrobbler = [[OfflineScrobbler alloc] init];
    });
    return scrobbler;
}

-(void)saveSong:(Song *)song
{
    [self saveSong:song toScrobbleItLaterWithDate:[NSDate date]];
}

-(void)deleteSong:(SavedSong *)song
{
    [self.songs removeObject:song];
    [self save];
}

#pragma mark - Music Scrobbler Delegate

-(void)songWasSuccessfullyScrobbled:(Song *)song
{
    if ([song isKindOfClass:[SavedSong class]]) {
        [self deleteSong:(SavedSong *)song];
    }
}

-(void)songWasNotScrobbled:(Song *)song
{
    [self saveSong:song toScrobbleItLaterWithDate:[NSDate date]];
}

#pragma mark - Private

-(instancetype)init
{
    self = [super init];
    if (self) {
         [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityDidChange:) name:FXReachabilityStatusDidChangeNotification object:nil];
    }
    return self;
}

-(void)preparePropertyList
{
    NSString *plistPath = [self pathToPlist];
    if (![[NSFileManager defaultManager] fileExistsAtPath:plistPath]) {
        self.songs = [@[] mutableCopy];
        NSData *savedData = [NSKeyedArchiver archivedDataWithRootObject:self.songs];
        [savedData writeToFile:plistPath atomically:YES];
    } else {
        self.songs = [[NSKeyedUnarchiver unarchiveObjectWithFile:plistPath] mutableCopy];
        if (!self.songs) {
            NSError *error;
            [[NSFileManager defaultManager] removeItemAtPath:plistPath error:&error];
            [self preparePropertyList];
        }
    }
}

-(NSString *)pathToPlist
{
    NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                              NSUserDomainMask, YES) objectAtIndex:0];
    NSString *plistPath = [rootPath stringByAppendingPathComponent:@"NepTunesOfflineSongsToScrobble.plist"];
    return plistPath;
}

-(void)saveSong:(Song *)song toScrobbleItLaterWithDate:(NSDate *)date
{
    SavedSong *savedSong = [[SavedSong alloc] initWithSong:song andDate:date];
    [self.songs addObject:savedSong];
    [self save];
}


-(void)save
{
    NSData *savedData = [NSKeyedArchiver archivedDataWithRootObject:self.songs];
    [savedData writeToFile:[self pathToPlist] atomically:YES];
}


-(void)reachabilityDidChange:(NSNotification *)note
{
    if ([FXReachability isReachable]) {
        self.areWeOffline = NO;
        if (self.songs.count) {
            [self tryToScrobbleTracks];
        }
    } else {
        self.areWeOffline = YES;
        [self preparePropertyList];
    }
}

-(void)tryToScrobbleTracks
{
    __weak typeof(self) weakSelf = self;
    NSMutableArray *tempArray = [self.songs copy];
    [tempArray enumerateObjectsUsingBlock:^(SavedSong * _Nonnull savedSong, NSUInteger idx, BOOL * _Nonnull stop) {
        NSBlockOperation *scrobbleTrack = [NSBlockOperation blockOperationWithBlock:^{
            [[MusicScrobbler sharedScrobbler] scrobbleOfflineTrack:savedSong];
        }];
        [weakSelf.offlineScrobblerOperationQueue addOperation:scrobbleTrack];
        if (idx == tempArray.count - 1) {
            NSBlockOperation *sendNotification = [NSBlockOperation blockOperationWithBlock:^{
                [weakSelf sendNotificationToUserThatAllSongsAreScrobbled];
            }];
            [weakSelf.offlineScrobblerOperationQueue addOperation:sendNotification];
        }
    }];
}

-(void)sendNotificationToUserThatAllSongsAreScrobbled
{
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title = NSLocalizedString(@"Woohoo!", nil);
    notification.subtitle = NSLocalizedString(@"All tracks seems scrobbled", nil);
    [notification setDeliveryDate:[NSDate dateWithTimeInterval:5 sinceDate:[NSDate date]]];
    [[NSUserNotificationCenter defaultUserNotificationCenter] scheduleNotification:notification];
}

#pragma mark - Getters

-(NSOperationQueue *)offlineScrobblerOperationQueue
{
    if (!_offlineScrobblerOperationQueue) {
        _offlineScrobblerOperationQueue = [NSOperationQueue mainQueue];
        _offlineScrobblerOperationQueue.qualityOfService = NSQualityOfServiceBackground;
        _offlineScrobblerOperationQueue.maxConcurrentOperationCount = 1;
    }
    return _offlineScrobblerOperationQueue;
}



-(void)dealloc
{
}

@end
