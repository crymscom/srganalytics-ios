//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UIViewController+RTSAnalytics.h"

#import <objc/runtime.h>

#import "RTSAnalyticsTracker.h"
#import "NSString+RTSAnalytics.h"
#import "RTSAnalyticsPageViewDataSource.h"

@implementation UIViewController (RTSAnalytics)

static void (*viewDidAppearIMP)(UIViewController *, SEL, BOOL);
static void AnalyticsViewDidAppear(UIViewController *self, SEL _cmd, BOOL animated);
static void AnalyticsViewDidAppear(UIViewController *self, SEL _cmd, BOOL animated)
{
	viewDidAppearIMP(self, _cmd, animated);
	[self trackPageView];
}

- (void)trackPageView
{
	if ([self conformsToProtocol:@protocol(RTSAnalyticsPageViewDataSource)]) {
		[[RTSAnalyticsTracker sharedTracker] trackPageViewForDataSource:(id<RTSAnalyticsPageViewDataSource>)self];
	}
}

+ (void)load
{
	Method viewDidAppear = class_getInstanceMethod(self, @selector(viewDidAppear:));
	viewDidAppearIMP = (__typeof__(viewDidAppearIMP))method_getImplementation(viewDidAppear);
	method_setImplementation(viewDidAppear, (IMP)AnalyticsViewDidAppear);
}

@end
