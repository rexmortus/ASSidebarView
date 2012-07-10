//
//  CFPSidebarView.h
//  Interstate for Mac
//
//  Created by Alec Sloman on 8/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CFPSidebarTopLevelButton.h"
#import "CFPSidebarChildLevelButton.h"
//  Created by Alec Sloman
//  Copyright 2012 __MetalHead__. All rights reserved. \m/

#import "CFPSidebarTopLevelButtonLayer.h"
#import "CFPSidebarChildLevelButtonLayer.h"

@interface NSMutableArray (MoveArray)

- (void)moveObjectFromIndex:(NSUInteger)from toIndex:(NSUInteger)to;

@end

@class CFPSidebarTopLevelButtonLayer;

@interface CFPSideBarClipView : NSClipView {
    
    BOOL            reorderMode;
    NSMenu          *reorderingContextualMenu;
    NSTimer         *reorderTimer;
    
    CALayer         *clickedLayer;
    NSMutableArray  *roadmapButtons;

    NSTrackingArea                     *exitClipViewTrackingArea;
    CFPSidebarTopLevelButtonLayer      *selectedLayerBeforeReorderMode;
    
}

@property (retain) NSMutableArray *roadmapButtons;

- (void)enterReorderMode:(NSTimer *)timer;
- (void)exitReorderMode;
- (void)startReorderTimer;
- (void)invalidateReorderTimer;

- (void)updateTrackingAreas;

- (CABasicAnimation *)rockingAnimation;
- (CABasicAnimation *)zoomDownAnimation;
- (CABasicAnimation *)zoomUpAnimation;
- (CABasicAnimation *)rotationAnimation;

@end

@interface CFPSidebarView : NSView {
    
    NSScrollView        *scrollView;
    NSOutlineView       *outlineView;
    CFPSideBarClipView  *iconView;
    
    NSMutableArray      *sidebarButtons;
    
    BOOL canSwapButtons;

}

- (void)switchToOutlineView;
- (void)switchToIconView;

@end