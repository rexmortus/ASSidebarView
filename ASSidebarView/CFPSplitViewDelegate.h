//
//  CFPSplitViewDelegate.h
//  Interstate for Mac
//
//  Created by Alec Sloman on 8/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

// Delegate splitview which is mostly responsible for constraining width of subviews

@interface CFPSplitViewDelegate : NSObject <NSSplitViewDelegate> {
    
	NSMutableDictionary *lengthsByViewIndex;
	NSMutableDictionary *viewIndicesByPriority;
}

- (void)setMinimumLength:(CGFloat)minLength forViewAtIndex:(NSInteger)viewIndex;
- (void)setPriority:(NSInteger)priorityIndex forViewAtIndex:(NSInteger)viewIndex;

@end

@interface CFPInnerSplitViewDelegate : CFPSplitViewDelegate {}
@end
