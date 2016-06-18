//
//  AppDelegate.m
//  NepTunes
//
//  Created by rurza on 19.11.2014.
//  Copyright (c) 2014 micropixels. All rights reserved.
//

#import "AppDelegate.h"
#import "SettingsController.h"
#import "PreferencesController.h"
#import "MenuController.h"

@interface AppDelegate ()
@property (nonatomic) SettingsController *settingsController;
@property (nonatomic) IBOutlet MenuController *menuController;
@end



@implementation AppDelegate

-(void)applicationDidFinishLaunching:(NSNotification *)notification
{
    [self downloadNewTagsLibraryAndStoreIt];
}

-(void)applicationDidBecomeActive:(NSNotification *)notification
{
    if (self.settingsController.hideStatusBarIcon) {
        [self.menuController openPreferences:nil];
    }
}

-(SettingsController *)settingsController
{
    if (!_settingsController) {
        _settingsController = [SettingsController sharedSettings];
    }
    return _settingsController;
}

-(void)downloadNewTagsLibraryAndStoreIt
{
    NSURLSession *session = [NSURLSession sharedSession];
    __weak typeof(self) weakSelf = self;
    [[session dataTaskWithURL:[NSURL URLWithString:@"http://micropixels.pl/neptunes/tags.json"] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            NSLog(@"error downloading tags = %@", [error localizedDescription]);
        }
        if (data.length) {
            NSError *error;
            id tags = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
            if ([tags isKindOfClass:[NSDictionary class]]) {
                NSArray *tagsStrings = [tags objectForKey:@"tags"];
                if (tagsStrings.count) {
                    weakSelf.tagsToCut = tagsStrings;
                    NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
                    NSString *plistPath = [rootPath stringByAppendingPathComponent:@"NepTunesTagsToCut.plist"];
                    BOOL fileSaved = [tagsStrings writeToFile:plistPath atomically:YES];
                    if (fileSaved) {
                        if (weakSelf.settingsController.debugMode) {
                            NSLog(@"Cut list saved");
                        }
                    }
                }
            }
        }
        
    }] resume];
}

@end
