//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UIViewController+SRGAnalytics.h"

#import <objc/runtime.h>

#import "SRGAnalyticsTracker.h"
#import "NSString+SRGAnalytics.h"
#import "SRGAnalyticsPageViewDataSource.h"

@implementation UIViewController (SRGAnalytics)

static void (*viewDidAppearIMP)(UIViewController *, SEL, BOOL);
static void AnalyticsViewDidAppear(UIViewController *self, SEL _cmd, BOOL animated);
static void AnalyticsViewDidAppear(UIViewController *self, SEL _cmd, BOOL animated)
{
	viewDidAppearIMP(self, _cmd, animated);
    
    if ([self conformsToProtocol:@protocol(SRGAnalyticsPageViewDataSource)]) {
        id<SRGAnalyticsPageViewDataSource> dataSource = (id<SRGAnalyticsPageViewDataSource>)self;
        if (![dataSource respondsToSelector:@selector(isTrackedAutomatically)] || [dataSource isTrackedAutomatically]) {
            [self trackPageView];
        }
    }
}

- (void)trackPageView
{
	if ([self conformsToProtocol:@protocol(SRGAnalyticsPageViewDataSource)]) {
		[[SRGAnalyticsTracker sharedTracker] trackPageViewForDataSource:(id<SRGAnalyticsPageViewDataSource>)self];
	}
}

+ (void)load
{
	Method viewDidAppear = class_getInstanceMethod(self, @selector(viewDidAppear:));
	viewDidAppearIMP = (__typeof__(viewDidAppearIMP))method_getImplementation(viewDidAppear);
	method_setImplementation(viewDidAppear, (IMP)AnalyticsViewDidAppear);
}

@end
