//
//  CFPSidebarView.m
//
//  Created by Alec Sloman
//  Copyright 2012 __MetalHead__. All rights reserved. \m/
//

#import "CFPSidebarView.h"

// Layout Constants
#define ABSOLUTE_MIN_WIDTH 68        // The minimum width of the sidebar view
#define DISPLAY_MIN_WIDTH 100        // The minumum width in which the sidebar displays the icon view
#define INITIAL_Y_OFFSET 35          // The Y offset of the first button
#define Y_OFFSET 60                  // The Y offset between buttons
#define BUTTON_X_POSITION 32         // The X position of the roadmap buttons
#define BUTTON_SIZE 54               // The dimension of the button (allowing 2 px extra for inset for shadow)
#define SMALL_BUTTON_X_POSITION 32   // The X position of the small buttons
#define SMALL_BUTTON_Y_OFFSET 42     // The Y offset of the small buttons
#define SMALL_BUTTON_SIZE 32         // The size of the small buttons
#define PADDING 20                   // The height between buttons

#define UP 1
#define DOWN -1

@implementation CFPSideBarClipView

@synthesize roadmapButtons;

- (BOOL)isFlipped {
    
    // We have to flip the coordinate system of the clip view because the CoreAnimation layer it hosts is also *flipped*! 
    // This way, everything has a top-left origin which helps the whole thing play properly with mousedowns and tracking events.
    
    return YES;
    
}

#pragma mark -
#pragma mark Initializer

- (id)initWithFrame:(NSRect)frameRect {
    
    if (self = [super initWithFrame:frameRect]) {
        
        // Create a mutable array to store pointers to the buttons
        roadmapButtons = [[NSMutableArray alloc] initWithCapacity:0];
        
        // Register the view to receive filename pasteboards
        [self registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
        
        // Create the initial tracking view (see updateTrackingAreas:)
        exitClipViewTrackingArea = [[NSTrackingArea alloc] initWithRect:self.frame options:(NSTrackingActiveInKeyWindow|NSTrackingMouseEnteredAndExited) owner:self userInfo:nil];
        [self addTrackingArea:exitClipViewTrackingArea];
        
        // When in reorder mode, re-use this simple contextual menu to enter/exit
        reorderingContextualMenu = [[NSMenu alloc] initWithTitle:@"Sidebar"];
        [reorderingContextualMenu addItemWithTitle:@"Reorder" action:@selector(enterReorderMode:) keyEquivalent:@""];
        [reorderingContextualMenu addItemWithTitle:@"End Reorder" action:@selector(exitReorderMode) keyEquivalent:@""];
        
    }
    
    return self;
    
}

#pragma mark -
#pragma mark Mouse Events

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent {
    
    return YES;
    
}

- (void)mouseDown:(NSEvent *)theEvent {
        
    // Start the reorder timer
    if (!reorderMode)
        [self startReorderTimer];
    
    // Get the clicked layer
    NSPoint location = [theEvent locationInWindow];
    clickedLayer = [[self layer] hitTest:NSPointToCGPoint(location)];
        
    // Set the clicked layer's z-position so it displays over the other sublayers
    for (CALayer *layer in roadmapButtons)
        layer.zPosition = 0.99;
    clickedLayer.zPosition = 1.0;
    
    // Clicking the root layer will exit reorder mode
    if ([clickedLayer isEqualTo:self.layer] && reorderMode)
        [self exitReorderMode];
    
    // Mouse-down on the selected layer shouldn't trigger an action, but if in reorder mode, should animate the layer
    if ([clickedLayer isKindOfClass:[CFPSidebarTopLevelButtonLayer class]]) {
        CFPSidebarTopLevelButtonLayer *_layer = (CFPSidebarTopLevelButtonLayer *)clickedLayer;
        _layer.contents = _layer.selectedStateImage;
        if (reorderMode) {
            clickedLayer.position = CGPointMake(clickedLayer.position.x, [self convertPoint:theEvent.locationInWindow fromView:nil].y);
            [_layer removeAnimationForKey:@"rockAnimation"];
            [clickedLayer addAnimation:[self zoomUpAnimation] forKey:@"zoomUp"];
        }
    }
}

- (void)rightMouseDown:(NSEvent *)theEvent {
    
    [super rightMouseDown:theEvent];
        
}

// A simple default implementation for contextual menus. Plug in an existing menu or create one on the fly.
- (NSMenu *)menuForEvent:(NSEvent *)event {
    
    id layer = [self.layer hitTest:NSPointToCGPoint(event.locationInWindow)];
    
    if ([layer isKindOfClass:[CFPSidebarTopLevelButtonLayer class]]) {
        
        NSMenu *menu = [[NSMenu alloc] initWithTitle:@"Your custom menu"];
        return menu;
    }
    
    else if ([layer isEqualTo:self.layer]) {
        return reorderingContextualMenu;
    }

    return nil;
    
}

- (void)mouseUp:(NSEvent *)theEvent {
    
    // If the reorder mode timer is still running after mouseup, invalidate it
    if ([reorderTimer isValid])
        [reorderTimer invalidate];
    
    // If the view is in reorder mode and a layer has been clicked, return the clicked layer to it's originalY position
    if (reorderMode) {
        if ([clickedLayer isKindOfClass:[CFPSidebarTopLevelButtonLayer class]]) {
            CFPSidebarTopLevelButtonLayer *_layer = (CFPSidebarTopLevelButtonLayer *)clickedLayer;
            clickedLayer.position = CGPointMake(clickedLayer.position.x, _layer.originalYPosition.floatValue);
            [clickedLayer addAnimation:[self zoomDownAnimation] forKey:@"zoomDown"];
            [clickedLayer addAnimation:[self rockingAnimation] forKey:@"rockAnimation"];
            
        }
        // Reset all the buttons to their regular image state
        for (CALayer *layer in roadmapButtons)
            if ([layer isKindOfClass:[CFPSidebarTopLevelButtonLayer class]]) {
                CFPSidebarTopLevelButtonLayer *_layer = (CFPSidebarTopLevelButtonLayer *)layer;
                _layer.contents = _layer.regularStateImage;
            }
    }
    
    // If the view isn't in reorder mode, select the button
    else if (!reorderMode) {
        NSPoint location = [theEvent locationInWindow];
        CALayer *layer = [[self layer] hitTest:NSPointToCGPoint(location)];
        if ([clickedLayer isEqual:layer] && [clickedLayer isKindOfClass:[CFPSidebarTopLevelButtonLayer class]]) {
            CFPSidebarTopLevelButtonLayer *_clickedLayer = (CFPSidebarTopLevelButtonLayer *)clickedLayer;
            selectedLayerBeforeReorderMode = _clickedLayer;
            for (CALayer *layer in roadmapButtons) {
                CFPSidebarTopLevelButtonLayer *_layer = (CFPSidebarTopLevelButtonLayer *)layer;
                _layer.contents = _layer.regularStateImage;
            }
            [_clickedLayer select];
        }
    }
    // nil the clicked layer in preparation for the next NSEvent
    clickedLayer = nil;
}

- (void)mouseEntered:(NSEvent *)theEvent {

    if (reorderMode && clickedLayer) {
        
        // Setup the animation context
        [NSAnimationContext beginGrouping];
        [[NSAnimationContext currentContext] setCompletionHandler:^{
            [self updateTrackingAreas]; // Update the tracking areas after the operation completes
        }];
        
        // Get a pointer to the affected layers
        CFPSidebarTopLevelButtonLayer *draggedLayer = (CFPSidebarTopLevelButtonLayer *)clickedLayer;
        CFPSidebarTopLevelButtonLayer *repositionedLayer = [[[theEvent trackingArea] userInfo] valueForKey:@"layer"];
        
        // Determine the direction of the reposition
        NSInteger indexOfDraggedLayer = [roadmapButtons indexOfObject:clickedLayer];
        NSInteger indexOfRepositionLayer = [roadmapButtons indexOfObject:repositionedLayer];
        if (indexOfDraggedLayer < indexOfRepositionLayer)
            repositionedLayer.frame = CGRectMake(repositionedLayer.frame.origin.x, 
                                                 repositionedLayer.frame.origin.y - Y_OFFSET, 
                                                 NSWidth(repositionedLayer.frame), 
                                                 NSHeight(repositionedLayer.frame));
        else
            repositionedLayer.frame = CGRectMake(repositionedLayer.frame.origin.x, 
                                                 repositionedLayer.frame.origin.y + Y_OFFSET, 
                                                 NSWidth(repositionedLayer.frame), 
                                                 NSHeight(repositionedLayer.frame));

        // Adjust the affected layers' original Y positions
        CGFloat repositionedLayerOriginalY  = repositionedLayer.originalYPosition.floatValue;
        CGFloat draggedLayerOriginalY       = draggedLayer.originalYPosition.floatValue;
        draggedLayer.originalYPosition      = [NSNumber numberWithFloat:repositionedLayerOriginalY];
        repositionedLayer.originalYPosition = [NSNumber numberWithFloat:draggedLayerOriginalY];
        
        // Update the position of the layers in the roadmap buttons array
        [roadmapButtons moveObjectFromIndex:indexOfDraggedLayer toIndex:indexOfRepositionLayer];
        
        // Close out the animation context
        [NSAnimationContext endGrouping];
    }
}

- (void)mouseExited:(NSEvent *)theEvent {
    
    // Check that it's not an obsolete tracking area, and that we've got a valid pointer to the clicked layer
    if ([[theEvent trackingArea] isEqualTo:exitClipViewTrackingArea] && clickedLayer)
        [self mouseUp:theEvent];
    
    // Also, if it's in re-order mode, update the tracking areas so the next mouseEntered: makes sense
    if (reorderMode)
        [self updateTrackingAreas];
    
}

- (void)mouseDragged:(NSEvent *)theEvent {
    
    // Suppress any implicit animations, then animate the layer so that it follows the vertical (but not horizontal) delta of the cursor
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    if (reorderMode) {
        CGPoint position = clickedLayer.position;
        position.y = [self convertPoint:theEvent.locationInWindow fromView:nil].y;
        clickedLayer.position = position;
    }
    [CATransaction commit];
    
    // Update tracking areas and call super
    [self updateTrackingAreas];
    [super mouseDragged:theEvent];

    
}

#pragma mark -
#pragma mark Drag & Drop

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender {
    
    return [super draggingEntered:sender];
}

- (NSDragOperation)draggingUpdated:(id<NSDraggingInfo>)sender {
    
    NSPasteboard *pboard;
    NSDragOperation sourceDragMask;
    NSPoint draggingLocation = [sender draggingLocation];
    
    sourceDragMask = [sender draggingSourceOperationMask];
    pboard = [sender draggingPasteboard];
    
    CALayer *draggedOverLayer = [self.layer hitTest:NSPointToCGPoint(draggingLocation)];
    
    // Button layers should only accept filename pasteboards
    if ([draggedOverLayer isKindOfClass:[CFPSidebarTopLevelButtonLayer class]] && [[pboard types] containsObject:NSFilenamesPboardType]) {
        NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
        NSString *filePathExtension = [[[files objectAtIndex:0] lastPathComponent] pathExtension];
        if ([filePathExtension isEqualToString:@"png"] || [filePathExtension isEqualToString:@"gif"] || [filePathExtension isEqualToString:@"jpg"] || [filePathExtension isEqualToString:@"jpeg"])
            return NSDragOperationCopy;
    }
        
    return NSDragOperationNone;
    
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender {
    
    // Get the dragged-over layer
    NSPoint draggingLocation = [sender draggingLocation];
    CFPSidebarTopLevelButtonLayer *draggedOverLayer = (CFPSidebarTopLevelButtonLayer *)[self.layer hitTest:NSPointToCGPoint(draggingLocation)];
    
    // Get the new image from the pasteboard
    NSPasteboard *pboard = [sender draggingPasteboard];
    NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
    NSString *filePath = [files objectAtIndex:0];
    NSImage *image = [[NSImage alloc] initWithContentsOfFile:filePath];
    [image setSize:NSMakeSize(44, 44)];
    
    // Get new image representations of the button
    CFPSidebarTopLevelButton *button    = [draggedOverLayer button];
    [[draggedOverLayer button] setImage:image];
    draggedOverLayer.activeStateImage   = [button layerRepresentationActive];
    draggedOverLayer.regularStateImage  = [button layerRepresentation];
    draggedOverLayer.selectedStateImage = [button layerRepresentationSelected];
    
    // Start the 'loading' animation. Don't refactor because it's way harder to read when the completion handler is in another method. Trust me.
    [draggedOverLayer setContents:[draggedOverLayer loadingStateImage]];
    CALayer *loadingLayer = [CALayer layer];
    [loadingLayer setFrame:CGRectMake(19, 19, 16, 16)];
    [loadingLayer setContents:[NSImage imageNamed:@"loading"]];
    [draggedOverLayer addSublayer:loadingLayer];
    
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setCompletionHandler:^{
        
        [NSAnimationContext beginGrouping];
        [[NSAnimationContext currentContext] setDuration:0.18];
        [[NSAnimationContext currentContext] setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
        draggedOverLayer.contents = draggedOverLayer.regularStateImage;
        [loadingLayer removeFromSuperlayer];
        [NSAnimationContext endGrouping];
    
    }];
    
    [loadingLayer addAnimation:[self rotationAnimation] forKey:@"360"];
    [NSAnimationContext endGrouping];
    
    return YES;
    
}

#pragma mark -
#pragma mark Reorder Timer

- (void)startReorderTimer {
    
    reorderTimer = nil;
    reorderTimer = [[NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(enterReorderMode:) userInfo:nil repeats:NO] retain];      
    [[NSRunLoop mainRunLoop] addTimer:reorderTimer forMode:NSRunLoopCommonModes];
    
}

- (void)invalidateReorderTimer {
    
    if ([reorderTimer isValid])
        [reorderTimer invalidate];
    
}

- (void)enterReorderMode:(NSTimer *)timer {
    
    CFPSidebarChildLevelButtonLayer *_layer = (CFPSidebarChildLevelButtonLayer *)clickedLayer;
    
    reorderMode = YES;
    [clickedLayer addAnimation:[self zoomUpAnimation] forKey:@"zoomUp"];
        
    for (CFPSidebarTopLevelButtonLayer *layer in roadmapButtons) {
        [layer deselectIsSubsequent:NO];
        layer.position = CGPointMake(layer.position.x, layer.originalYPosition.floatValue);
        [layer addAnimation:[self rockingAnimation] forKey:@"rockAnimation"];
    }
    
    clickedLayer.contents = _layer.selectedStateImage;
    [clickedLayer removeAnimationForKey:@"rockAnimation"];

}

- (void)exitReorderMode {
    
    reorderMode = NO;
    for (CFPSidebarTopLevelButtonLayer *layer in roadmapButtons) {
        [layer removeAnimationForKey:@"rockAnimation"];
        layer.position = CGPointMake(layer.position.x, layer.originalYPosition.floatValue);
        [layer deselectIsSubsequent:NO];
    }
    
}

#pragma mark -
#pragma mark Tracking Areas

- (void)updateTrackingAreas {
    
    for (CFPSidebarTopLevelButtonLayer *layer in roadmapButtons) {
        
        [self removeTrackingArea:layer.trackingArea];
        NSRect trackingRect = NSMakeRect(0, layer.frame.origin.y, self.frame.size.width, layer.frame.size.height);
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:layer forKey:@"layer"];
        NSTrackingArea *newTrackingArea = [[NSTrackingArea alloc] initWithRect:trackingRect
                                                                       options:layer.trackingArea.options
                                                                         owner:self userInfo:userInfo];
        
        [self addTrackingArea:newTrackingArea];
        [layer setTrackingArea:newTrackingArea];
        
        
    }
    
}

#pragma mark -
#pragma mark Animations

- (CABasicAnimation *)zoomUpAnimation {
    
    CABasicAnimation *scaling;
	scaling = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
	scaling.toValue = [NSNumber numberWithFloat:1.05];
	scaling.removedOnCompletion = NO;
	scaling.autoreverses = NO;
	scaling.fillMode = kCAFillModeForwards;
	scaling.duration = 0.2;
    
    return scaling;
    
}

- (CABasicAnimation *)zoomDownAnimation {
    
    CABasicAnimation *scaling;
	scaling = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
	scaling.toValue = [NSNumber numberWithFloat:1.00];
	scaling.removedOnCompletion = NO;
	scaling.autoreverses = NO;
	scaling.fillMode = kCAFillModeForwards;
	scaling.duration = 0.2;
    
    return scaling;
    
}

- (CABasicAnimation *)rockingAnimation {
    
    float diff = 0.065 - .055;
    float startValue = (((float) (arc4random() % ((unsigned)RAND_MAX + 1)) / RAND_MAX) * diff) + 0.055;
    float endValue   = (((float) (arc4random() % ((unsigned)RAND_MAX + 1)) / RAND_MAX) * diff) - 0.055;
    float duration   = (((float) (arc4random() % ((unsigned)RAND_MAX + 1)) / RAND_MAX) * diff) + 0.085;
    
    CABasicAnimation *rockAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    [rockAnimation setFromValue:[NSNumber numberWithFloat:startValue]];
    [rockAnimation setToValue:[NSNumber numberWithFloat:endValue]];
    [rockAnimation setDuration:duration];
    [rockAnimation setRemovedOnCompletion:YES];
    [rockAnimation setFillMode:kCAFillModeForwards];
    [rockAnimation setAutoreverses:YES];
    [rockAnimation setRepeatCount:10000];
    
    return rockAnimation;
    
}

- (CABasicAnimation *)rotationAnimation {
    
    CABasicAnimation * rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
	rotationAnimation.fromValue = [NSNumber numberWithFloat:0];
	rotationAnimation.toValue = [NSNumber numberWithFloat:-((360*M_PI)/180)];
	rotationAnimation.duration = 0.6;
    rotationAnimation.repeatCount = 2;
    return rotationAnimation;
    
}

@end

@implementation CFPSidebarView

#pragma mark -
#pragma mark Init

- (void)awakeFromNib {

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterReorderMode:) name:@"CFPSidebarShouldEnterReorderModeNotification" object:nil];
    
    // Prepare a mutable array to store pointers to all them buttons
    sidebarButtons = [[NSMutableArray alloc] initWithCapacity:0];
    
    // Set up the scroll view        
    scrollView = [[NSScrollView alloc] initWithFrame:self.frame];
    [scrollView setAutoresizingMask:(NSViewHeightSizable | NSViewWidthSizable)];
    [scrollView setVerticalLineScroll:10.0f];
    [scrollView setDrawsBackground:NO];
        
    iconView = [[CFPSideBarClipView alloc] initWithFrame:NSMakeRect(0, 0, scrollView.frame.size.width, self.frame.size.height + 100)];
    [iconView setAutoresizingMask:(NSViewWidthSizable|NSViewHeightSizable)];
    [iconView setDrawsBackground:NO];
    
    CALayer *iconViewLayer = [CALayer layer];
    iconViewLayer.transform = CATransform3DMakeScale(-1.0f, -1.0f, 1.0f);
    [iconView setLayer:iconViewLayer];
    [iconView setWantsLayer:YES];
    
    NSInteger y_position = INITIAL_Y_OFFSET;
    
    // This is where you'd hook into your model and generate buttons.
    // In this example, we're creating an arbitrary number of top level buttons (6)
    // Each "topLevel" button will own 
    
    for (int i = 0; i < 6; i++) {
        
        CFPSidebarTopLevelButton *roadmapButton = [[CFPSidebarTopLevelButton alloc] 
                                                   initWithFrame:NSMakeRect(0, 0, BUTTON_SIZE, BUTTON_SIZE)];
        // Make a top-level button layer
        CFPSidebarTopLevelButtonLayer *layer = [CFPSidebarTopLevelButtonLayer layer];
        layer.zPosition = 0.000;
        layer.activeStateImage = [roadmapButton layerRepresentationActive];
        layer.regularStateImage = [roadmapButton layerRepresentation];
        layer.selectedStateImage = [roadmapButton layerRepresentationSelected];
        layer.loadingStateImage = [roadmapButton layerRepresentationLoading];
        layer.contents = [layer regularStateImage];
        layer.bounds = CGRectMake(0, 0, BUTTON_SIZE, BUTTON_SIZE);
        layer.position = CGPointMake(BUTTON_X_POSITION, NSMinY(iconView.frame) + y_position);
        layer.name = [NSString stringWithFormat:@"%f", y_position];
        layer.originalYPosition = [NSNumber numberWithFloat:layer.position.y];
        layer.iconView = iconView;
        layer.button = roadmapButton;
        
        // The overview button
        CFPSidebarChildLevelButton *overviewButton = [[CFPSidebarChildLevelButton alloc] initWithFrame:NSMakeRect(0, 0, SMALL_BUTTON_SIZE, SMALL_BUTTON_SIZE)];
        [overviewButton setImage:[NSImage imageNamed:@"overview_static"]];
        [overviewButton setAlternateImage:[NSImage imageNamed:@"overview_selected"]];
        CFPSidebarChildLevelButtonLayer *overviewButtonLayer = [CFPSidebarChildLevelButtonLayer layer];
        overviewButtonLayer.bounds = CGRectMake(0, 0, SMALL_BUTTON_SIZE, SMALL_BUTTON_SIZE);
        overviewButtonLayer.position = CGPointMake(SMALL_BUTTON_X_POSITION, layer.position.y + PADDING);
        overviewButtonLayer.regularStateImage = [overviewButton layerRepresentation];
        overviewButtonLayer.selectedStateImage = [overviewButton layerRepresentationSelected];
        overviewButtonLayer.contents = overviewButtonLayer.regularStateImage;
        overviewButtonLayer.hidden = YES;
        layer.overviewButtonLayer = overviewButtonLayer;
        [iconViewLayer addSublayer:overviewButtonLayer];
        
        CFPSidebarChildLevelButton *roadsButton = [[CFPSidebarChildLevelButton alloc] initWithFrame:NSMakeRect(0, y_position + 0, SMALL_BUTTON_SIZE, SMALL_BUTTON_SIZE)];
        [roadsButton setImage:[NSImage imageNamed:@"roads_static"]];
        [roadsButton setAlternateImage:[NSImage imageNamed:@"roads_selected"]];
        CFPSidebarChildLevelButtonLayer *roadsButtonLayer = [CFPSidebarChildLevelButtonLayer layer];
        roadsButtonLayer.bounds = CGRectMake(0, 0, SMALL_BUTTON_SIZE, SMALL_BUTTON_SIZE);
        roadsButtonLayer.position = CGPointMake(SMALL_BUTTON_X_POSITION, layer.position.y + PADDING);
        roadsButtonLayer.regularStateImage = [roadsButton layerRepresentation];
        roadsButtonLayer.selectedStateImage = [roadsButton layerRepresentationSelected];
        roadsButtonLayer.contents = roadsButtonLayer.regularStateImage;
        roadsButtonLayer.hidden = YES;

        layer.roadsButtonLayer = roadsButtonLayer;
        [iconViewLayer addSublayer:roadsButtonLayer];
        
        CFPSidebarChildLevelButton *peopleButton = [[CFPSidebarChildLevelButton alloc] initWithFrame:NSMakeRect(0, y_position + 0, SMALL_BUTTON_SIZE, SMALL_BUTTON_SIZE)];
        [peopleButton setImage:[NSImage imageNamed:@"people_static"]];
        [peopleButton setAlternateImage:[NSImage imageNamed:@"people_selected"]];
        CFPSidebarChildLevelButtonLayer *peopleButtonLayer = [CFPSidebarChildLevelButtonLayer layer];
        peopleButtonLayer.bounds = CGRectMake(0, 0, SMALL_BUTTON_SIZE, SMALL_BUTTON_SIZE);
        peopleButtonLayer.position = CGPointMake(SMALL_BUTTON_X_POSITION, layer.position.y + PADDING);
        peopleButtonLayer.regularStateImage = [peopleButton layerRepresentation];
        peopleButtonLayer.selectedStateImage = [peopleButton layerRepresentationSelected];
        peopleButtonLayer.contents = peopleButtonLayer.regularStateImage;
        peopleButtonLayer.hidden = YES;
        layer.peopleButtonLayer = peopleButtonLayer;
        [iconViewLayer addSublayer:peopleButtonLayer];
        
        // Make a tracking area and associate it with the layer
        NSRect trackingRect = NSMakeRect(0, layer.frame.origin.y, self.frame.size.width, layer.frame.size.height);
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:layer forKey:@"layer"];
        NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect:trackingRect options:(NSTrackingActiveInKeyWindow|NSTrackingMouseEnteredAndExited|NSTrackingEnabledDuringMouseDrag) owner:iconView userInfo:userInfo];
        [iconView addTrackingArea:trackingArea];
        [layer setTrackingArea:trackingArea];
        
        // Add it to the view
        [iconViewLayer addSublayer:layer];
        
        // Add a pointer to the array of layer buttons (so they can be dynamically reordered without actually affecting the sublayers array)
        [[iconView roadmapButtons] addObject:layer];
    
        y_position += Y_OFFSET;

    }
    
    [scrollView setDocumentView:iconView];
    [self addSubview:scrollView];
    
}

#pragma mark -
#pragma mark Drawing

- (void)drawRect:(NSRect)dirtyRect {
    
    // Set the pattern phase so the image draws from the top left instead of the bottom left
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [[NSGraphicsContext currentContext] setPatternPhase:NSMakePoint(0, self.frame.size.height)];
    
    // If the icon should be in sidebar mode, draw the background as black linen
    if (self.frame.size.width < DISPLAY_MIN_WIDTH) {
                
        NSColor *background = [NSColor colorWithPatternImage:[NSImage imageNamed:@"linen"]];
        [background setFill];
        NSRectFill(self.bounds);
        
        NSBezierPath *path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(NSMinX(self.bounds) - .5, NSMaxY(self.bounds))];
        [path lineToPoint:NSMakePoint(NSMaxX(self.bounds) - .5, NSMaxY(self.bounds))];
        [path setLineWidth:0.5];
        [[NSColor blackColor] setStroke];
        [path stroke];
        
        if (scrollView.documentView != iconView)
            [self switchToIconView];
        
    }
    
    // Otherwise, draw it as blue linen or whatever you want
    else {
        
        [[NSColor colorWithPatternImage:[NSImage imageNamed:@"light_linen"]] setFill];
        NSRectFill(self.bounds);
        if (scrollView.documentView != outlineView)
            [self switchToOutlineView];
        
        [[NSColor blackColor] setStroke];
        NSBezierPath *topBorderPath = [NSBezierPath bezierPath];
        [topBorderPath moveToPoint:NSMakePoint(NSMinX(self.bounds), NSMaxY(self.bounds))];
        [topBorderPath lineToPoint:NSMakePoint(NSMaxX(self.bounds), NSMaxY(self.bounds))];
        //[topBorderPath stroke];
    }
    
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    
}

#pragma mark -
#pragma mark Controller

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent {
    
    return YES;
    
}

- (void)switchToOutlineView {
    
    [scrollView setDocumentView:outlineView];
    
}

- (void)switchToIconView {
    
    [scrollView setDocumentView:iconView];
    
}


@end

@implementation NSMutableArray (MoveArray)

- (void)moveObjectFromIndex:(NSUInteger)from toIndex:(NSUInteger)to
{
    if (to != from) {
        id obj = [self objectAtIndex:from];
        [obj retain];
        [self removeObjectAtIndex:from];
        if (to >= [self count]) {
            [self addObject:obj];
        } else {
            [self insertObject:obj atIndex:to];
        }
        [obj release];
    }
}
@end
