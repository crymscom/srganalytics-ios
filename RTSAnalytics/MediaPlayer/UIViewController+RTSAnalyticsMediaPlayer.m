//
//  Created by Frédéric Humbert-Droz on 19/04/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "UIViewController+RTSAnalyticsMediaPlayer.h"

#import <objc/runtime.h>

#import "RTSAnalyticsStreamTracker_private.h"
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
	[[RTSAnalyticsStreamTracker sharedTracker] startTrackingMediaPlayerController:mediaPlayerController];
}

- (void) stopTrackingMediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController
{
	[[RTSAnalyticsStreamTracker sharedTracker] stopTrackingMediaPlayerController:mediaPlayerController];
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
	
	[[RTSAnalyticsStreamTracker sharedTracker] trackMediaPlayerFromPresentingViewController:mediaPlayerDelegate];
}

@end
