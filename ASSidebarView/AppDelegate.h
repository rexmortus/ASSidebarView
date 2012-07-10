#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>

// View
#import "CFPSidebarView.h"

// Delegate
#import "CFPSplitViewDelegate.h"

@interface AppDelegate : NSObject <NSApplicationDelegate> {
    
    // View
    IBOutlet NSSplitView *splitView;
    
}

@property (assign) IBOutlet NSSplitView *splitView;

@end
