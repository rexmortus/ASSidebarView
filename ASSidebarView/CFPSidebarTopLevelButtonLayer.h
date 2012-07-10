//
//  CFPSidebarTopLevelButtonLayer.h
//
//  Created by Alec Sloman
//  Copyright 2012 __MetalHead__. All rights reserved. \m/
//

#import <QuartzCore/QuartzCore.h>
#import "CFPSidebarView.h"

@class CFPSideBarClipView;
@class CFPSidebarTopLevelButton;
@class CFPSidebarChildLevelButtonLayer;

@interface CFPSidebarTopLevelButtonLayer : CALayer {
    
    CFPSideBarClipView *iconView;
    NSImage *regularStateImage;
    NSImage *selectedStateImage;
    NSImage *loadingStateImage;
    NSImage *activeStateImage;
    NSNumber *originalYPosition;
    NSTrackingArea *trackingArea;
    CFPSidebarTopLevelButton *button;
    
    CFPSidebarChildLevelButtonLayer *overviewButtonLayer;
    CFPSidebarChildLevelButtonLayer *roadsButtonLayer;
    CFPSidebarChildLevelButtonLayer *peopleButtonLayer;
    
}

@property (retain) CFPSideBarClipView *iconView;
@property (retain) NSTrackingArea *trackingArea;
@property (retain) NSNumber *originalYPosition;
@property (retain) NSImage *regularStateImage;
@property (retain) NSImage *selectedStateImage;
@property (retain) NSImage *loadingStateImage;
@property (retain) NSImage *activeStateImage;
@property (retain) CFPSidebarTopLevelButton *button;
@property (retain) CFPSidebarChildLevelButtonLayer *overviewButtonLayer;
@property (retain) CFPSidebarChildLevelButtonLayer *roadsButtonLayer;
@property (retain) CFPSidebarChildLevelButtonLayer *peopleButtonLayer;

- (void)select;
- (void)deselectIsSubsequent:(BOOL)subsequent;

@end
