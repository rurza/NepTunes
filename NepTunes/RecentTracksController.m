//
//  RecentTracksController.m
//  NepTunes
//
//  Created by rurza on 22/01/16.
//  Copyright © 2016 micropixels. All rights reserved.
//

#import "RecentTracksController.h"
#import "Song.h"
#import "SettingsController.h"

@interface RecentTracksController ()
@property (nonatomic, readwrite) NSMutableArray *songs;
@end

@implementation RecentTracksController

#pragma mark - Public

+(RecentTracksController *)sharedInstance
{
    static RecentTracksController *controller = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        controller = [[RecentTracksController alloc] init];
    });
    return controller;
}

-(instancetype)init
{
    self = [super init];
    if (self) {
        [self preparePropertyList];
    }
    return self;
}

-(BOOL)addSongToRecentMenu:(Song *)song
{
    if (song) {
        if (![self.songs containsObject:song] || ![self isTrackIsInRecentMenu:song]) {
            [self.songs insertObject:song atIndex:0];
            if (self.songs.count>15) {
                [self.songs removeLastObject];
            }
            [self save];
            return YES;
        } else return NO;
    }
    else return NO;
}

-(BOOL)isTrackIsInRecentMenu:(Song *)song
{
    NSInteger numberOfItemsInRecentMenu = [SettingsController sharedSettings].numberOfTracksInRecent.integerValue;
    if (numberOfItemsInRecentMenu == 0) {
        return YES;
    }
    NSRange range;
    if (self.songs.count >= numberOfItemsInRecentMenu) {
        range = NSMakeRange(0, numberOfItemsInRecentMenu);
    } else {
        range = NSMakeRange(0, self.songs.count);
    }
    NSArray *subArray = [self.songs subarrayWithRange:range];
    if ([subArray containsObject:song]) {
        return YES;
    }
    return NO;
}

#pragma mark - Private
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
    NSString *plistPath = [rootPath stringByAppendingPathComponent:@"NepTunesRecentTracksMenu.plist"];
    return plistPath;
}


-(void)save
{
    NSData *savedData = [NSKeyedArchiver archivedDataWithRootObject:self.songs];
    [savedData writeToFile:[self pathToPlist] atomically:YES];
}



@end
