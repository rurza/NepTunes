//
//  CoverWindow.h
//  NepTunes
//
//  Created by rurza on 11/02/16.
//  Copyright © 2016 micropixels. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class CoverImageView;
@class CoverView;

@interface CoverWindow : NSWindow
@property (strong) IBOutlet CoverView *coverView;
@property (strong) IBOutlet NSVisualEffectView *controlView;

@end
