//
//  CFPSidebarChildLevelButtonLayer.h
//
//  Created by Alec Sloman
//  Copyright 2012 __MetalHead__. All rights reserved. \m/
//

#import <QuartzCore/QuartzCore.h>

@interface CFPSidebarChildLevelButtonLayer : CALayer {
    
    NSImage *regularStateImage;
    NSImage *selectedStateImage;
    
}

@property (retain) NSImage *regularStateImage;
@property (retain) NSImage *selectedStateImage;

@end
