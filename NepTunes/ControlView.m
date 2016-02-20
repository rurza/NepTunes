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

-(void)rotateWithEvent:(NSEvent *)event
{
    NSLog(@"=== rotate: %@ ===", event);
}

-(void)magnifyWithEvent:(NSEvent *)event
{
    NSLog(@"magnify: %@", event);
}

-(BOOL)wantsScrollEventsForSwipeTrackingOnAxis:(NSEventGestureAxis)axis
{
    return YES;
}


-(BOOL)acceptsFirstResponder
{
    return YES;
}

@end
