//
//  CFPSidebarTopLevelButtonLayer.m
//
//  Created by Alec Sloman
//  Copyright 2012 __MetalHead__. All rights reserved. \m/
//

#import "CFPSidebarTopLevelButtonLayer.h"

#define UP 1
#define DOWN -1

@implementation CFPSidebarTopLevelButtonLayer

@synthesize iconView;
@synthesize trackingArea;
@synthesize originalYPosition;
@synthesize regularStateImage;
@synthesize selectedStateImage;
@synthesize loadingStateImage;
@synthesize activeStateImage;
@synthesize button;
@synthesize overviewButtonLayer;
@synthesize roadsButtonLayer;
@synthesize peopleButtonLayer;

- (void)select {
        
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:0.25f];
    [[NSAnimationContext currentContext] setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    
    // Return the clicked button to it's original position
    self.position = CGPointMake(self.position.x, self.originalYPosition.floatValue);
    
    // Change the button's image to active
    self.contents = activeStateImage;
    
    // Show the child buttons
    overviewButtonLayer.position = CGPointMake(overviewButtonLayer.position.x, self.position.y + 50);
    overviewButtonLayer.hidden = NO;
    overviewButtonLayer.opacity = 1.0;
    roadsButtonLayer.position = CGPointMake(roadsButtonLayer.position.x, self.position.y + 90);
    roadsButtonLayer.hidden = NO;
    roadsButtonLayer.opacity = 1.0;
    roadsButtonLayer.contents = roadsButtonLayer.selectedStateImage;
    peopleButtonLayer.position = CGPointMake(peopleButtonLayer.position.x, self.position.y + 130);
    peopleButtonLayer.hidden = NO;
    peopleButtonLayer.opacity = 1.0f;
    
    // Reposition previous button
    NSInteger indexOfPreviousButton = [iconView.roadmapButtons indexOfObject:self] - 1;
    for (NSInteger i = indexOfPreviousButton; i >= 0; i--) {
        CFPSidebarTopLevelButtonLayer *layer = [iconView.roadmapButtons objectAtIndex:i];
        layer.position = CGPointMake(layer.position.x, layer.originalYPosition.floatValue);
        [layer deselectIsSubsequent:NO];
    }
    
    // Reposition subsequent buttons
    NSInteger indexOfNextButton = [iconView.roadmapButtons indexOfObject:self] + 1;
    for (NSInteger i = indexOfNextButton; i < [iconView.roadmapButtons count]; i++) {
        CFPSidebarTopLevelButtonLayer *layer = [iconView.roadmapButtons objectAtIndex:i];
        layer.position = CGPointMake(layer.position.x, layer.originalYPosition.floatValue + 120);
        [layer deselectIsSubsequent:YES];
    }
    
    [NSAnimationContext endGrouping];

}

- (void)deselectIsSubsequent:(BOOL)subsequent {
        
    self.contents = regularStateImage;
    
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setCompletionHandler:^{
        overviewButtonLayer.hidden = YES;
        roadsButtonLayer.hidden = YES;
        peopleButtonLayer.hidden = YES;
        
        if (!subsequent) {
            overviewButtonLayer.position = CGPointMake(overviewButtonLayer.position.x, self.position.y + 40);
            roadsButtonLayer.position = CGPointMake(roadsButtonLayer.position.x, self.position.y + 40);
            peopleButtonLayer.position = CGPointMake(roadsButtonLayer.position.x, self.position.y + 40);
        }
        
        else {
            overviewButtonLayer.position = CGPointMake(overviewButtonLayer.position.x, self.position.y + 10);
            roadsButtonLayer.position = CGPointMake(roadsButtonLayer.position.x, self.position.y + 10);
            peopleButtonLayer.position = CGPointMake(roadsButtonLayer.position.x, self.position.y + 10); 
        }
    
    }];
        
    if (!subsequent) {
        overviewButtonLayer.position = CGPointMake(overviewButtonLayer.position.x, self.position.y + 40);
        roadsButtonLayer.position = CGPointMake(roadsButtonLayer.position.x, self.position.y + 40);
        peopleButtonLayer.position = CGPointMake(roadsButtonLayer.position.x, self.position.y + 40);
    }
    
    else {
        overviewButtonLayer.position = CGPointMake(overviewButtonLayer.position.x, self.position.y + 10);
        roadsButtonLayer.position = CGPointMake(roadsButtonLayer.position.x, self.position.y + 10);
        peopleButtonLayer.position = CGPointMake(roadsButtonLayer.position.x, self.position.y + 10);   
    }
    
    overviewButtonLayer.opacity = 0.0;
    roadsButtonLayer.opacity = 0.0;
    peopleButtonLayer.opacity = 0.0;
    
    [NSAnimationContext endGrouping];
    
}

@end
