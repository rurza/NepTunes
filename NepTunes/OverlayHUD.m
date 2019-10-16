//
//  OverlayHUD.m
//  NepTunes
//
//  Created by Adam Różyński on 12/09/2016.
//  Copyright © 2016 micropixels. All rights reserved.
//

#import "OverlayHUD.h"

@implementation OverlayHUD

-(void)awakeFromNib
{
    self.wantsLayer = YES;
    self.layer.cornerRadius = 6;
}

@end
