//
//  CoverView.h
//  NepTunes
//
//  Created by rurza on 12/02/16.
//  Copyright © 2016 micropixels. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class CoverImageView;

@interface CoverView : NSView
@property (strong) IBOutlet CoverImageView *coverImageView;
@property (strong) IBOutlet NSTextField *titleLabel;
@property (strong) IBOutlet NSVisualEffectView *artistView;

@end
