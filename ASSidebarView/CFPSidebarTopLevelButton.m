//
//  CFPSidebarTopLevelButton.m
//
//  Created by Alec Sloman
//  Copyright 2012 __MetalHead__. All rights reserved. \m/
//

#import "CFPSidebarTopLevelButton.h"

#define X_INSET 3.5
#define Y_INSET 3.5
#define BEZIER_RADIUS 6
#define UP 1
#define DOWN -1

#define DROPSHADOW_COLOR [[NSColor blackColor] colorWithAlphaComponent:0.35]
#define INNER_SHADOW_COLOR [NSColor whiteColor]

#define SHADOW_BLUR_RADIUS 2.0f
#define SHADOW_OFFSET_SIZE NSMakeSize(0.0f, -2.0f)

#define BUTTON_BACKGROUND_COLOR [NSColor colorWithDeviceRed:0.180 green:0.224 blue:0.247 alpha:1.000]
#define BUTTON_BORDER_COLOR [NSColor colorWithDeviceRed:0.402 green:0.437 blue:0.461 alpha:1.000]
#define BUTTON_BORDER_PRESSED_COLOR [[NSColor blackColor] colorWithAlphaComponent:0.35]
#define BUTTON_SHEEN_COLOR [[NSColor whiteColor] colorWithAlphaComponent:0.05] 
#define BUTTON_SHEEN_PRESSED_COLOR [[NSColor blackColor] colorWithAlphaComponent:0.15]

#define BUTTON_SELECTED_GRADIENT_BACKGROUND [[NSGradient alloc] initWithStartingColor:[NSColor colorWithDeviceHue:0.591 saturation:0.811 brightness:0.416 alpha:1.000] endingColor:[NSColor colorWithDeviceHue:0.581 saturation:0.700 brightness:0.471 alpha:1.000]]
#define BUTTON_SELECTED_STROKE_COLOR [NSColor whiteColor] colorWithAlphaComponent:0.5]

// Button

@implementation NSImage(Rotated)

- (NSImage *)imageRotated:(float)degrees {
    if (0 != fmod(degrees,90.)) { NSLog( @"This code has only been tested for multiples of 90 degrees. (TODO: test and remove this line)"); }
    degrees = fmod(degrees, 360.);
    if (0 == degrees) {
        return self;
    }
    NSSize size = [self size];
    NSSize maxSize;
    if (90. == degrees || 270. == degrees || -90. == degrees || -270. == degrees) {
        maxSize = NSMakeSize(size.height, size.width);
    } else if (180. == degrees || -180. == degrees) {
        maxSize = size;
    } else {
        maxSize = NSMakeSize(20+MAX(size.width, size.height), 20+MAX(size.width, size.height));
    }
    NSAffineTransform *rot = [NSAffineTransform transform];
    [rot rotateByDegrees:degrees];
    NSAffineTransform *center = [NSAffineTransform transform];
    [center translateXBy:maxSize.width / 2. yBy:maxSize.height / 2.];
    [rot appendTransform:center];
    NSImage *image = [[[NSImage alloc] initWithSize:maxSize] autorelease];
    [image lockFocus];
    [rot concat];
    NSRect rect = NSMakeRect(0, 0, size.width, size.height);
    NSPoint corner = NSMakePoint(-size.width / 2., -size.height / 2.);
    [self drawAtPoint:corner fromRect:rect operation:NSCompositeCopy fraction:1.0];
    [image unlockFocus];
    return image;
}

@end

@implementation CFPSidebarTopLevelButton

- (id)initWithFrame:(NSRect)frameRect {
    
    if (self = [super initWithFrame:frameRect]) {
        
        CFPSidebarTopLevelButtonCell *buttonCell = [[CFPSidebarTopLevelButtonCell alloc] init];
        [self setCell:buttonCell];
        [self setBezelStyle:NSSmallSquareBezelStyle];
        [self setImage:[NSImage imageNamed:@"Cloud"]];
                
    }
    
    return self;
    
}

- (NSImage *)layerRepresentation {
    
    [self highlight:NO];
    
    NSData *imageRepresenationData = [self dataWithPDFInsideRect:self.bounds];
    NSImage *imageRepresentation = [[NSImage alloc] initWithData:imageRepresenationData];
        
    return [imageRepresentation imageRotated:180];
        
}

- (NSImage *)layerRepresentationSelected {
    
    [self highlight:YES];
    
    NSData *imageRepresenationData = [self dataWithPDFInsideRect:self.bounds];
    NSImage *imageRepresentation = [[NSImage alloc] initWithData:imageRepresenationData];
    
    [self highlight:NO];
    
    return [imageRepresentation imageRotated:180];
    
}

- (NSImage *)layerRepresentationLoading {
    
    isLoading = YES;
    
    NSData *imageRepresenationData = [self dataWithPDFInsideRect:self.bounds];
    NSImage *imageRepresentation = [[NSImage alloc] initWithData:imageRepresenationData];
    
    isLoading = NO;
    
    return imageRepresentation;
    
}

- (NSImage *)layerRepresentationActive {
    
    isActive = YES;
    
    NSData *imageRepresenationData = [self dataWithPDFInsideRect:self.bounds];
    NSImage *imageRepresentation = [[NSImage alloc] initWithData:imageRepresenationData];
    
    isActive = NO;
    
    return [imageRepresentation imageRotated:180];
    
}

- (BOOL)isActive {
    
    return isActive;
    
}

- (BOOL)isLoading {
    
    return isLoading;
    
}


@end

// Button Cell

@implementation CFPSidebarTopLevelButtonCell

- (id)init {
    
    if (self = [super init]) {
        
        dropShadow = [[NSShadow alloc] init];
        [dropShadow setShadowColor:DROPSHADOW_COLOR];
        [dropShadow setShadowBlurRadius:SHADOW_BLUR_RADIUS];
        [dropShadow setShadowOffset:SHADOW_OFFSET_SIZE];
        
        innerShadow = [[NSShadow alloc] init];
        [innerShadow setShadowColor:INNER_SHADOW_COLOR];
        [innerShadow setShadowBlurRadius:SHADOW_BLUR_RADIUS];
        [innerShadow setShadowOffset:SHADOW_OFFSET_SIZE];
        
        [self setHighlightsBy:0];
        
    }
    
    return self;
    
}

- (void)drawBezelWithFrame:(NSRect)frame inView:(NSView *)controlView {
    
    CFPSidebarTopLevelButton *button = (CFPSidebarTopLevelButton *)controlView;
    
    NSRect insetRect = NSInsetRect(frame, X_INSET, Y_INSET);
    NSBezierPath *borderPath = [NSBezierPath bezierPathWithRoundedRect:insetRect xRadius:BEZIER_RADIUS yRadius:BEZIER_RADIUS];
    [borderPath setLineWidth:0.5f];
    
    [NSGraphicsContext saveGraphicsState];
    [dropShadow set];
    [BUTTON_BACKGROUND_COLOR setFill];
    [borderPath fill];
    [NSGraphicsContext restoreGraphicsState];
    
    if ([button isLoading]) {
        
        [NSGraphicsContext saveGraphicsState];
        [BUTTON_BORDER_PRESSED_COLOR setStroke];
        [borderPath stroke];
        [NSGraphicsContext restoreGraphicsState];
        
    }
    
    else if ([button isActive]) {
        
        [NSGraphicsContext saveGraphicsState];
        [BUTTON_SELECTED_GRADIENT_BACKGROUND drawInBezierPath:borderPath angle:270.0f];
        [[[NSColor colorWithCalibratedHue:0.581 saturation:0.473 brightness:0.580 alpha:1.000] colorWithAlphaComponent:1] setStroke];
        [borderPath stroke];
        [NSGraphicsContext restoreGraphicsState];
        
    }
    
    else if (!self.isHighlighted) {
    
        [NSGraphicsContext saveGraphicsState];
        [BUTTON_BORDER_COLOR setStroke];
        [borderPath stroke];
        [NSGraphicsContext restoreGraphicsState];
    
    }
    
    else {
        
        [NSGraphicsContext saveGraphicsState];
        [BUTTON_BORDER_PRESSED_COLOR setStroke];
        [borderPath stroke];
        [NSGraphicsContext restoreGraphicsState];
        
    }
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {

    NSRect insetRect = NSInsetRect(cellFrame, X_INSET, Y_INSET);
    NSBezierPath *borderPath = [NSBezierPath bezierPathWithRoundedRect:insetRect xRadius:BEZIER_RADIUS yRadius:BEZIER_RADIUS];
    [borderPath addClip];
    
    CFPSidebarTopLevelButton *button = (CFPSidebarTopLevelButton *)controlView;
    [super drawInteriorWithFrame:cellFrame inView:controlView];    

    if ([button isLoading]) {
        
        [[NSColor whiteColor] setFill];
        [borderPath fill];
                
    }
        
    else if (!self.isHighlighted && ![button isActive]) {

        NSRect clipRect = NSMakeRect(cellFrame.origin.x, 0, cellFrame.size.width, cellFrame.size.height / 2);
        NSBezierPath *clipPath = [NSBezierPath bezierPathWithRect:clipRect];
        [clipPath addClip];
        [BUTTON_SHEEN_COLOR setFill];
        [borderPath fill];
        
    }
    
    else if ([button isActive]) {
        
        NSRect clipRect = NSMakeRect(cellFrame.origin.x, 0, cellFrame.size.width, cellFrame.size.height / 2);
        NSBezierPath *clipPath = [NSBezierPath bezierPathWithRect:clipRect];
        [clipPath addClip];
        [BUTTON_SHEEN_COLOR setFill];
        [borderPath fill];
        
    }
    
    else if (self.isHighlighted) {
        
        [BUTTON_SHEEN_PRESSED_COLOR setFill];
        [borderPath fill];
        
    }
    
}


@end
