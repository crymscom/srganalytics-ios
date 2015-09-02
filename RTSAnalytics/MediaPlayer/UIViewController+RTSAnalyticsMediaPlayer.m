//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UIViewController+RTSAnalyticsMediaPlayer.h"

#import <objc/runtime.h>

#import "RTSMediaPlayerControllerTracker_private.h"
#import "RTSAnalyticsMediaPlayerDelegate.h"

@implementation UIViewController (RTSAnalyticsMediaPlayer)

+ (void) load
{
	Method viewDidLoad = class_getInstanceMethod(self, @selector(viewDidLoad));
	viewDidLoadIMP = (__typeof__(viewDidLoadIMP))method_getImplementation(viewDidLoad);
	method_setImplementation(viewDidLoad, (IMP)AnalyticsViewDidLoad);
}

- (void) startTrackingMediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController
{
	[[RTSMediaPlayerControllerTracker sharedTracker] startTrackingMediaPlayerController:mediaPlayerController];
}

- (void) stopTrackingMediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController
{
	[[RTSMediaPlayerControllerTracker sharedTracker] stopTrackingMediaPlayerController:mediaPlayerController];
}

#pragma mark - RTSAnalyticsMediaPlayerDelegate

static void (*viewDidLoadIMP)(UIViewController *, SEL);
static void AnalyticsViewDidLoad(UIViewController *self, SEL _cmd);
static void AnalyticsViewDidLoad(UIViewController *self, SEL _cmd)
{
	viewDidLoadIMP(self, _cmd);
	[self trackMediaPlayer];
}

- (void) trackMediaPlayer
{
	id<RTSAnalyticsMediaPlayerDelegate> mediaPlayerDelegate = nil;
	if ([self conformsToProtocol:@protocol(RTSAnalyticsMediaPlayerDelegate)])
		mediaPlayerDelegate = (id<RTSAnalyticsMediaPlayerDelegate>)self;
	
	[[RTSMediaPlayerControllerTracker sharedTracker] trackMediaPlayerFromPresentingViewController:mediaPlayerDelegate];
}

@end
