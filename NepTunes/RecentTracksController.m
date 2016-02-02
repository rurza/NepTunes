//
//  RecentTracksController.m
//  NepTunes
//
//  Created by rurza on 22/01/16.
//  Copyright © 2016 micropixels. All rights reserved.
//

#import "RecentTracksController.h"
#import "Track.h"
#import "SettingsController.h"

@interface RecentTracksController ()
@property (nonatomic, readwrite) NSMutableArray *tracks;
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

-(BOOL)addTrackToRecentMenu:(Track *)track
{
    if (track) {
        if (![self.tracks containsObject:track] || ![self isTrackIsInRecentMenu:track]) {
            [self.tracks insertObject:track atIndex:0];
            if (self.tracks.count>15) {
                [self.tracks removeLastObject];
            }
            [self save];
            return YES;
        } else return NO;
    }
    else return NO;
}

-(BOOL)isTrackIsInRecentMenu:(Track *)track
{
    NSInteger numberOfItemsInRecentMenu = [SettingsController sharedSettings].numberOfTracksInRecent.integerValue;
    if (numberOfItemsInRecentMenu == 0) {
        return YES;
    }
    NSRange range;
    if (self.tracks.count >= numberOfItemsInRecentMenu) {
        range = NSMakeRange(0, numberOfItemsInRecentMenu);
    } else {
        range = NSMakeRange(0, self.tracks.count);
    }
    NSArray *subArray = [self.tracks subarrayWithRange:range];
    if ([subArray containsObject:track]) {
        return YES;
    }
    return NO;
}

#pragma mark - Private
-(void)preparePropertyList
{
    NSString *plistPath = [self pathToPlist];
    if (![[NSFileManager defaultManager] fileExistsAtPath:plistPath]) {
        self.tracks = [@[] mutableCopy];
        NSData *savedData = [NSKeyedArchiver archivedDataWithRootObject:self.tracks];
        [savedData writeToFile:plistPath atomically:YES];
    } else {
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
    
    NSString *plistPath = [rootPath stringByAppendingPathComponent:@"NepTunesRecentTracksList.plist"];
    
    return plistPath;
}


-(void)save
{
    NSData *savedData = [NSKeyedArchiver archivedDataWithRootObject:self.tracks];
    [savedData writeToFile:[self pathToPlist] atomically:YES];
}



@end
