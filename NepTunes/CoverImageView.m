//
//  CoverImageView.m
//  NepTunes
//
//  Created by rurza on 11/02/16.
//  Copyright © 2016 micropixels. All rights reserved.
//

#import "CoverImageView.h"

@implementation CoverImageView

-(void)awakeFromNib
{
    self.wantsLayer = YES;
    self.layer.cornerRadius = 6;
    self.layer.masksToBounds = YES;
}

//draggable
-(BOOL)mouseDownCanMoveWindow
{
    return YES;
}

@end
