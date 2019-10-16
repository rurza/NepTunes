//
//  CoverLabel.m
//  NepTunes
//
//  Created by rurza on 15/02/16.
//  Copyright © 2016 micropixels. All rights reserved.
//

#import "CoverLabel.h"

@implementation CoverLabel

-(instancetype)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (self) {
        [self setup];
    }
    return self;
}

-(void)setup
{
    self.textColor = [NSColor labelColor];
    self.wantsLayer = YES;
    self.layer.opacity = 0;
    self.bezeled = NO;
    self.bordered = NO;
    self.drawsBackground = NO;
    self.alignment = NSTextAlignmentCenter;
    self.selectable = NO;
    [[self cell] setLineBreakMode:NSLineBreakByWordWrapping];
    [[self cell] setTruncatesLastVisibleLine:YES];
}

@end
