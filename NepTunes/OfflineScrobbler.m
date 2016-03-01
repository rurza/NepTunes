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
#import "SavedTrack.h"
#import "SettingsController.h"
#import "UserNotificationsController.h"

@interface OfflineScrobbler ()
@property (nonatomic, readwrite) NSMutableArray *tracks;
@property (nonatomic) NSOperationQueue *offlineScrobblerOperationQueue;
@end

@implementation OfflineScrobbler
@synthesize userWasLoggedOut = _userWasLoggedOut;

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

-(void)saveTrack:(Track *)track
{
    [self saveTrack:track toScrobbleItLaterWithDate:[NSDate date]];
}

-(void)deleteTrack:(SavedTrack *)track
{
    [self.tracks removeObject:track];
    [self save];
}

-(void)deleteAllSavedTracks
{
    [self.tracks removeAllObjects];
    [self removePlistFile];
}


#pragma mark - Music Scrobbler Delegate

-(void)trackWasSuccessfullyScrobbled:(Track *)track
{
    if ([track isKindOfClass:[SavedTrack class]]) {
        [self deleteTrack:(SavedTrack *)track];
    }
    if (self.tracks.count == 0) {
        [self removePlistFile];
    }
}

-(void)trackWasNotScrobbled:(Track *)track
{
    [self saveTrack:track toScrobbleItLaterWithDate:[NSDate date]];
}

#pragma mark - Private

-(instancetype)init
{
    self = [super init];
    if (self) {
        [self preparePropertyList];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityDidChange:) name:FXReachabilityStatusDidChangeNotification object:nil];
    }
    return self;
}

-(void)preparePropertyList
{
    NSString *plistPath = [self pathToPlist];
    if (![[NSFileManager defaultManager] fileExistsAtPath:plistPath]) {
        self.tracks = [@[] mutableCopy];
        NSData *savedData = [NSKeyedArchiver archivedDataWithRootObject:self.tracks];
        [savedData writeToFile:plistPath atomically:YES];
    } else {
        [self removeIncompatibleFiles];
        self.tracks = [[NSKeyedUnarchiver unarchiveObjectWithFile:plistPath] mutableCopy];
        if (!self.tracks) {
            NSError *error;
            [[NSFileManager defaultManager] removeItemAtPath:plistPath error:&error];
            [self preparePropertyList];
        }
    }
}

-(NSString *)pathToPlist
{
    NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *plistPath = [rootPath stringByAppendingPathComponent:@"NepTunesOfflineTracksToScrobble.plist"];
    return plistPath;
}

-(BOOL)removePlistFile
{
    NSError *error;
    BOOL succeed = [NSFileManager defaultManager] removeItemAtPath:[self pathToPlist] error:&error];
    if (error) {
        NSLog(@"Can't remove file, %@", error.localizedDescription);
    }
    return succeed;
}

-(void)removeIncompatibleFiles
{
    NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *oldPlistPath = [rootPath stringByAppendingPathComponent:@"NepTunesOfflineSongsToScrobble.plist"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:oldPlistPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:oldPlistPath error:nil];
    }
}

-(void)saveTrack:(Track *)track toScrobbleItLaterWithDate:(NSDate *)date
{
    SavedTrack *savedTrack = [[SavedTrack alloc] initWithTrack:track andDate:date];
    [self.tracks addObject:savedTrack];
    [self save];
}


-(void)save
{
    NSData *savedData = [NSKeyedArchiver archivedDataWithRootObject:self.tracks];
    [savedData writeToFile:[self pathToPlist] atomically:YES];
}


-(void)reachabilityDidChange:(NSNotification *)note
{
    if ([FXReachability isReachable]) {
        self.areWeOffline = NO;
        [self tryToScrobbleTracks];
    } else {
        self.areWeOffline = YES;
    }
}

-(void)tryToScrobbleTracks
{
    if ([SettingsController sharedSettings].session && self.tracks.count && ![SettingsController sharedSettings].userWasLoggedOut) {
        __weak typeof(self) weakSelf = self;
        NSMutableArray *tempArray = [self.tracks copy];
        [tempArray enumerateObjectsUsingBlock:^(SavedTrack * _Nonnull savedSong, NSUInteger idx, BOOL * _Nonnull stop) {
            NSBlockOperation *scrobbleTrack = [NSBlockOperation blockOperationWithBlock:^{
                [[MusicScrobbler sharedScrobbler] scrobbleOfflineTrack:savedSong];
            }];
            [weakSelf.offlineScrobblerOperationQueue addOperation:scrobbleTrack];
            if (idx == tempArray.count - 1) {
                NSBlockOperation *sendNotification = [NSBlockOperation blockOperationWithBlock:^{
                    [[UserNotificationsController sharedNotificationsController] displayNotificationThatAllTracksAreScrobbled];
                }];
                [weakSelf.offlineScrobblerOperationQueue addOperation:sendNotification];
            }
        }];
    }
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

#pragma mark - Setters
-(void)setLastFmIsDown:(BOOL)lastFmIsDown
{
    _lastFmIsDown = lastFmIsDown;
    if (!lastFmIsDown) {
        [self tryToScrobbleTracks];
    }
}

#pragma mark - User Was logged out
-(void)setUserWasLoggedOut:(BOOL)userWasLoggedOut
{
    _userWasLoggedOut = userWasLoggedOut;
    [SettingsController sharedSettings].userWasLoggedOut = userWasLoggedOut;
    if (!userWasLoggedOut) {
        [self tryToScrobbleTracks];
    }
}

-(BOOL)userWasLoggedOut
{
    return [SettingsController sharedSettings].userWasLoggedOut;
}

@end
