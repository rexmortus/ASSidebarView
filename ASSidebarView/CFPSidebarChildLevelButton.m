//
//  CFPSidebarChildLevelButton.m
//
//  Created by Alec Sloman
//  Copyright 2012 __MetalHead__. All rights reserved. \m/
//

#import "CFPSidebarChildLevelButton.h"

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

@implementation CFPSidebarChildLevelButton

- (id)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (self) {
        
        [self setBordered:NO];
        [[self cell] setHighlightsBy:3];
        
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

@end
