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
@class ControlView;
@class OverlayHUD;

@interface CoverWindow : NSWindow
@property (nonatomic) IBOutlet CoverView *coverView;
@property (nonatomic) IBOutlet ControlView *controlView;
@property (nonatomic) IBOutlet OverlayHUD *controlOverlayHUD;

@end
