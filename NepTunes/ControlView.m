//
//  ControlView.m
//  NepTunes
//
//  Created by rurza on 20/02/16.
//  Copyright © 2016 micropixels. All rights reserved.
//

#import "ControlView.h"

@interface ControlView ()
@end

@implementation ControlView


-(BOOL)acceptsTouchEvents
{
    return YES;
}

-(BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
    return YES;
}

-(BOOL)becomeFirstResponder
{
    return YES;
}

@end
