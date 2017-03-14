//
//  GravityView.m
//  Gravity
//
//  Created by Krish Kalai on 3/9/17.
//  Copyright © 2017 Krish Kalai. All rights reserved.
//

//
// Progression List:
// -- ITEM                                   STATUS
// -------------------------------------------------------------
// *) Learn how to animate.                  [DONE]
// *) Smoothen out animations.               [DONE]
// *) Cut motion pattern to arc.             [DONE]
// *) Fix radius and position of circles.    [~DONE]
// *) Fix constant velocity of circles.      [~DONE]
// *) Add second circle that mirrors first.  [DONE]
// *) Add stop and wait points               [DONE]
// *) Clean positions of circles             [IN PROGRESS]
// *) Optimize code - cleanup of this point. [DONE]
// *) Implement with linear velocity.        [DONE]
// *) Upgrade to with quadratic velocity.    [IN PROGRESS]
// *) Add middle circles.                    []
// *) Reduce angle to 15<θ<30 degrees        []
// *) Make [rainbow] strings                 []
//

#import "GravityView.h"

#define PI        3.1415926
//#define MAX_POINT 3*PI/2     //90 degrees
//#define MAX_POINT 195*PI/180 //15 degrees
#define MAX_POINT 210*PI/180 //30 degrees
#define MIN_POINT PI
/**
 * 0: circular
 * 1: parabolic (needs implementation)
 */
#define MOTION_PATTERN 0

@implementation GravityView {
    NSRect tmp;
    NSRect left_filler_rect; // Black circle to cover the previous draw of the left red circle.
    NSRect right_filler_rect; // Black circle to cover the previous draw of the right blue circle.
    NSRect far_left_rect; // Far left red moving circle.
    NSRect far_right_rect; // Far right blue moving circle.
    NSBezierPath *path; // Path that the rectangle draws in.
    double position; // Variable that represents the current circle angle (in radiants).
    double rate_of_change; // How many degrees per frame.
    double velocity_change; // Change in velocity (constant value for now).
    bool left_circle_moves; // Value to determine if the left circle moves (for stop-wait points).
    bool reverse; // Change if the min/max point has been reached, and change the direction.
}

- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview {
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
        [self setAnimationTimeInterval:1/40.0]; //Official frame speed.
        //[self setAnimationTimeInterval:1/10.0]; //Frame speed for debugging
    }
    return self;
}

- (void)startAnimation {
    [super startAnimation];
    //initialize values to default
    
    //
    // Initial angle key:
    // 0°   = 0      (Top)
    // 90°  = PI/2   (Right)
    // 180° = PI     (Bottom)
    // 270° = 3PI/2  (Left)
    //
    position = MAX_POINT;
    
    far_left_rect.origin = [self calculatePointForFarLeftRectangle];
    far_left_rect.size = CGSizeMake(50, 50);
    far_right_rect.origin = [self calculatePointForFarRightRectangle];
    far_right_rect.size = CGSizeMake(50, 50);
    left_filler_rect.origin = far_left_rect.origin;
    left_filler_rect.size = CGSizeMake(50, 50);
    right_filler_rect.origin = far_left_rect.origin;
    right_filler_rect.size = CGSizeMake(50, 50);

    rate_of_change = 57.0;
    velocity_change = 1.0;
    reverse = NO;
    left_circle_moves = YES;
}

- (void)stopAnimation {
    [super stopAnimation];
}

- (void)drawRect:(NSRect)rect {
    [super drawRect:rect];
}

- (void)animateOneFrame {
    //Draw over previously painted rectangles.
    [[NSColor blackColor] set];
    
    left_filler_rect.origin = far_left_rect.origin;
    path = [NSBezierPath bezierPathWithOvalInRect:left_filler_rect];
    [path fill];
    //[path stroke];

    right_filler_rect.origin = far_right_rect.origin;
    path = [NSBezierPath bezierPathWithOvalInRect:right_filler_rect];
    [path fill];
    //[path stroke];
        
    position += reverse ? 1/rate_of_change : -(1/rate_of_change);
    
    if ((left_circle_moves && !reverse) || (!left_circle_moves && reverse)){
        rate_of_change -= velocity_change;
    }
    if ((left_circle_moves && reverse) || (!left_circle_moves && !reverse)){
        rate_of_change += velocity_change;
    }
    
    
    if (left_circle_moves) {
        far_left_rect.origin = [self calculatePointForFarLeftRectangle];
    }
    else {
        far_right_rect.origin = [self calculatePointForFarRightRectangle];
    }
    
    if (position >= MAX_POINT || position <= MIN_POINT) {
        // Change when circles reached max height
        reverse = !reverse;
        
        if (left_circle_moves && position <= MIN_POINT) {
            left_circle_moves = NO;
            position = MAX_POINT;
            rate_of_change = 57.0;
            reverse = NO;
        }
        else if (!left_circle_moves && position >= MAX_POINT) {
            left_circle_moves = YES;
            position = MIN_POINT;
            rate_of_change = 57.0;
            reverse = YES;
        }
    }
    
    [[NSColor redColor] set];
    path = [NSBezierPath bezierPathWithOvalInRect:far_left_rect];
    [path fill];
    
    [[NSColor blueColor] set];
    path = [NSBezierPath bezierPathWithOvalInRect:far_right_rect];
    [path fill];
}

- (BOOL)hasConfigureSheet {
    return NO;
}

- (NSWindow*)configureSheet {
    return nil;
}

#pragma mark - rectangle origin evaluation

#if MOTION_PATTERN == 0

//Circular
- (CGPoint)calculatePointForFarLeftRectangle {
    // r^2 = (x+x1)^2 + (y+y1)^2
    // x = r*sin(frame) + displacement, y = r*sin(frame) + displacement
    const int radius = 300;
    int screen_width = [self bounds].size.width;
    int screen_height = [self bounds].size.height;
    return CGPointMake(radius*sin(position) + (3*screen_width/8), radius*cos(position)+screen_height/2);
}

- (CGPoint)calculatePointForFarRightRectangle {
    // r^2 = (x+x1)^2 + (y+y1)^2
    // x = r*sin(frame) + displacement, y = r*sin(frame) + displacement
    const int radius = 300;
    int screen_width = [self bounds].size.width;
    int screen_height = [self bounds].size.height;
    //return CGPointMake(radius*cos(PI-position-PI/4)+(5*screen_width/8), radius*sin(PI-position-PI/4)+screen_height/2);
    return CGPointMake(radius*cos(11*PI/16-position)+5*screen_width/8, radius*sin(11*PI/16-position)+screen_height/2);
}

#elif MOTION_PATTERN == 1

//Parabolic - most likely not used
- (CGPoint)calculatePointFromFramePosition {
    int screen_width = [self bounds].size.width;
    int screen_height = [self bounds].size.height;
    
    return = CGPointMake(position*8 + screen_width/4, pow(2*position,2) + position + screen_height/4);
}

#endif

@end
