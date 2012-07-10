//
//  CFPSidebarTopLevelButton.h
//
//  Created by Alec Sloman
//  Copyright 2012 __MetalHead__. All rights reserved. \m/
//

#import <AppKit/AppKit.h>
#import <QuartzCore/QuartzCore.h>
#import "CFPSidebarView.h"
#import "CFPSidebarTopLevelButtonLayer.h"

@class CFPSidebarView;

@interface CFPSidebarTopLevelButton : NSButton {

    BOOL isLoading;
    BOOL isActive;
    

}

- (NSImage *)layerRepresentation;
- (NSImage *)layerRepresentationSelected;
- (NSImage *)layerRepresentationLoading;
- (NSImage *)layerRepresentationActive;

- (BOOL)isLoading;
- (BOOL)isActive;

@end

@interface CFPSidebarTopLevelButtonCell : NSButtonCell {NSShadow *dropShadow; NSShadow *innerShadow;}

@end
