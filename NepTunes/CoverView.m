//
//  CoverView.m
//  NepTunes
//
//  Created by rurza on 12/02/16.
//  Copyright © 2016 micropixels. All rights reserved.
//

#import "CoverView.h"

@implementation CoverView

-(void)awakeFromNib
{
    self.wantsLayer = YES;
    self.layer.cornerRadius = 6;
    CGColorRef background = CGColorCreateGenericRGB(0.0, 0.0, 0.0, 1);
    [self.layer setBackgroundColor:background];

    [self setupArtistView];
    [self setupTitleLabel];
    self.layer.masksToBounds = YES;
    CGColorRelease(background);
}

-(void)setupTitleLabel
{
    self.titleLabel.textColor = [NSColor labelColor];
}

-(void)setupArtistView
{
    self.artistView.layer.masksToBounds = YES;
}



@end
