//
//  CFPSplitView.m
//  Interstate for Mac
//
//  Created by Alec Sloman
//  Copyright 2012 __MetalHead__. All rights reserved. \m/
//

#import "CFPSplitView.h"

// Layout Constants
#define MIN_DISPLAY_WIDTH 100

// Drawing Constants
#define ICON_VIEW_RIGHT_BORDER_COLOR [NSColor blackColor]
#define OUTLINE_VIEW_RIGHT_BORDER_COLOR [NSColor colorWithCalibratedWhite:0.576 alpha:1.000]

@implementation CFPSplitView

- (NSColor *)dividerColor {
    
    NSView *sidebarView = (NSView *)[[self subviews] objectAtIndex:0];
    
    if (sidebarView.frame.size.width < MIN_DISPLAY_WIDTH)
        return ICON_VIEW_RIGHT_BORDER_COLOR;
    else
        return OUTLINE_VIEW_RIGHT_BORDER_COLOR;
    
}

@end
