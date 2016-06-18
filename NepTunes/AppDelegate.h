//
//  AppDelegate.h
//  NepTunes
//
//  Created by rurza on 19.11.2014.
//  Copyright (c) 2014 micropixels. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (nonatomic) NSArray *tagsToCut;


-(void)downloadNewTagsLibraryAndStoreIt;

@end

